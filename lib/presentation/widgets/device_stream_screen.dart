import 'package:flutter/material.dart';
import 'dart:async';
// Importar la clase Donador desde activar_live_page.dart
// Idealmente, Donador sería un modelo en una ubicación compartida.
import 'package:battle_live/presentation/pages/activar_live_page.dart'
    show Donador;
import 'package:video_player/video_player.dart';
import 'package:battle_live/core/logging/app_logger.dart';

class DeviceStream extends StatefulWidget {
  final Map<String, dynamic>? esqueleto;
  final int puntosIzquierda;
  final int puntosDerecha;
  final Donador? mayorDonador;
  final int? tiempoInicial; // Nuevo parámetro para tiempo inicial
  final bool
      pausarTemporizador; // Nuevo parámetro para controlar si está pausado
  final Function(int)?
      onTiempoActualizado; // Callback para notificar tiempo actual
  final bool mostrarVideo; // Nuevo parámetro para controlar si mostrar el video

  const DeviceStream({
    super.key,
    this.esqueleto,
    required this.puntosIzquierda,
    required this.puntosDerecha,
    this.mayorDonador,
    this.tiempoInicial,
    this.pausarTemporizador = false,
    this.onTiempoActualizado,
    this.mostrarVideo = false, // Por defecto no mostrar
  });

  @override
  State<DeviceStream> createState() => _DeviceStreamState();
}

class _DeviceStreamState extends State<DeviceStream>
    with TickerProviderStateMixin {
  // Variables para el temporizador regresivo
  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _isPaused = false;

  // Controladores para animaciones
  late AnimationController _leftPulseController;
  late AnimationController _rightPulseController;
  late Animation<double> _leftPulseAnimation;
  late Animation<double> _rightPulseAnimation;

  // Controlador para animación de brillo de diamantes
  late AnimationController _shineController;
  late Animation<double> _shineAnimation;

  // Controlador para animación pulsante del timer
  late AnimationController _timerPulseController;
  late Animation<double> _timerPulseAnimation;

  // Variables para el reproductor de video
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  String _currentVideo = '';
  bool _isVideoLoading = true;

  @override
  void initState() {
    super.initState();

    // Inicializar con el tiempo proporcionado o el valor por defecto
    _remainingSeconds = widget.tiempoInicial ?? 3600; // 1 hora por defecto
    _isPaused = widget.pausarTemporizador;

    // Configurar controladores de animación
    _leftPulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rightPulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Configurar animaciones
    _leftPulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _leftPulseController,
        curve: Curves.easeInOut,
      ),
    );

    _rightPulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _rightPulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Configurar animación de brillo para diamantes
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shineController,
        curve: Curves.easeInOut,
      ),
    );

    // Configurar animación pulsante para el timer
    _timerPulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _timerPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _timerPulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Iniciar animación de brillo y que se repita
    _shineController.repeat(reverse: true);

    // Iniciar animación del timer (se activará cuando queden menos de 5 minutos)
    _timerPulseController.repeat(reverse: true);

    // Iniciar contador regresivo si no está pausado
    if (!_isPaused) {
      _startCountdownTimer();
    }

    // Inicializar el reproductor de video si está habilitado
    if (widget.mostrarVideo) {
      _initializeVideoPlayer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            // Notificar tiempo actualizado si hay callback
            widget.onTiempoActualizado?.call(_remainingSeconds);
          } else {
            _countdownTimer?.cancel();
          }
        });
      }
    });
  }

  // Método para establecer un nuevo tiempo
  void setTime(int newSeconds) {
    if (mounted) {
      setState(() {
        _remainingSeconds = newSeconds;
      });
    }
  }

  @override
  void didUpdateWidget(DeviceStream oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Actualizar temporizador si cambia el tiempo inicial
    if (widget.tiempoInicial != null &&
        widget.tiempoInicial != oldWidget.tiempoInicial) {
      setState(() {
        _remainingSeconds = widget.tiempoInicial!;
      });
    }

    // Manejar pausa/reanudar si cambia el estado
    if (widget.pausarTemporizador != oldWidget.pausarTemporizador) {
      if (widget.pausarTemporizador) {
        _isPaused = true;
        _countdownTimer?.cancel();
      } else if (_isPaused) {
        _isPaused = false;
        _startCountdownTimer();
      }
    }

    // Activar pulsaciones si los puntajes cambian
    if (widget.puntosIzquierda > oldWidget.puntosIzquierda) {
      _pulseLeftScore();
    }
    if (widget.puntosDerecha > oldWidget.puntosDerecha) {
      _pulseRightScore();
    }

    // Actualizar video si cambió la puntuación
    if (widget.mostrarVideo && 
        (widget.puntosIzquierda != oldWidget.puntosIzquierda || 
         widget.puntosDerecha != oldWidget.puntosDerecha)) {
      AppLogger.info(
        'Cambio en puntuación: Izquierda ${oldWidget.puntosIzquierda} → ${widget.puntosIzquierda}, ' +
        'Derecha ${oldWidget.puntosDerecha} → ${widget.puntosDerecha}',
        name: 'DeviceStream'
      );
      
      bool oldLeaderWasLeft = oldWidget.puntosIzquierda > oldWidget.puntosDerecha;
      bool newLeaderIsLeft = widget.puntosIzquierda > widget.puntosDerecha;
      bool wasATie = oldWidget.puntosIzquierda == oldWidget.puntosDerecha;
      bool isATie = widget.puntosIzquierda == widget.puntosDerecha;
      
      // Forzar actualización en cualquiera de estos casos
      if (oldLeaderWasLeft != newLeaderIsLeft || wasATie != isATie) {
        AppLogger.info(
          'Cambio de líder detectado: ${oldLeaderWasLeft ? "Izquierda" : wasATie ? "Empate" : "Derecha"} → ' +
          '${newLeaderIsLeft ? "Izquierda" : isATie ? "Empate" : "Derecha"}',
          name: 'DeviceStream'
        );
        _forceVideoUpdate();
      }
    }
    
    // Activar/desactivar video
    if (widget.mostrarVideo != oldWidget.mostrarVideo) {
      AppLogger.info(
        'Cambio en estado de video: ${oldWidget.mostrarVideo ? "Activado" : "Desactivado"} → ${widget.mostrarVideo ? "Activado" : "Desactivado"}',
        name: 'DeviceStream'
      );
      
      if (widget.mostrarVideo) {
        _initializeVideoPlayer();
      } else if (_videoController != null) {
        AppLogger.info('Eliminando controlador de video', name: 'DeviceStream');
        _videoController!.pause();
        _videoController!.dispose();
        _videoController = null;
      }
    }
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Color _getTimerColor() {
    if (_remainingSeconds < 300) {
      // menos de 5 minutos
      return Colors.red;
    } else if (_remainingSeconds < 900) {
      // menos de 15 minutos
      return Colors.orange;
    } else {
      return Colors.white;
    }
  }

  void _pulseLeftScore() {
    _leftPulseController.forward().then((_) {
      _leftPulseController.reverse();
    });
  }

  void _pulseRightScore() {
    _rightPulseController.forward().then((_) {
      _rightPulseController.reverse();
    });
  }

  @override
  void dispose() {
    _leftPulseController.dispose();
    _rightPulseController.dispose();
    _shineController.dispose();
    _timerPulseController.dispose();
    _countdownTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  // Inicializar el controlador de video
  void _initializeVideoPlayer() async {
    AppLogger.info('Inicializando reproductor de video', name: 'DeviceStream');
    _updateVideoBasedOnLeader();
  }
  
  // Forzar actualización del video sin importar si es el mismo
  void _forceVideoUpdate() async {
    // Forzar el reinicio del video aunque la ruta sea la misma
    String assetPath = _getVideoAssetPath();
    
    AppLogger.info('Forzando actualización de video a: $assetPath', name: 'DeviceStream');
    _currentVideo = ""; // Restablecer el video actual para forzar la actualización
    _updateVideoBasedOnLeader();
  }
  
  // Actualizar el video según quién va ganando
  void _updateVideoBasedOnLeader() async {
    String assetPath = _getVideoAssetPath();
    
    // Si ya está mostrando este video, no hacer nada
    if (_currentVideo == assetPath) {
      AppLogger.info('Video actual mantiene: $assetPath', name: 'DeviceStream');
      return;
    }
    
    AppLogger.info('Cambiando video a: $assetPath', name: 'DeviceStream');
    _currentVideo = assetPath;
    
    // Liberar el controlador anterior si existe
    if (_videoController != null) {
      AppLogger.info('Eliminando controlador de video anterior', name: 'DeviceStream');
      await _videoController?.dispose();
    }
    
    // Crear y configurar un nuevo controlador
    setState(() {
      _isVideoLoading = true;
    });
    
    // Verificar si el archivo existe antes de intentar inicializarlo
    try {
      // Intentar verificar si el asset existe
      AppLogger.info('Verificando existencia del archivo: $assetPath', name: 'DeviceStream');
      
      AppLogger.info('Creando nuevo controlador para: $assetPath', name: 'DeviceStream');
      _videoController = VideoPlayerController.asset(assetPath);
      
      // Agregar listener para errores
      _videoController!.addListener(() {
        final value = _videoController!.value;
        if (value.hasError) {
          AppLogger.error(
            'Error durante la reproducción: ${value.errorDescription}',
            name: 'DeviceStream'
          );
        }
      });
      
      await _videoController!.initialize().then((_) {
        AppLogger.info(
          'Video inicializado correctamente: $assetPath, duración: ${_videoController!.value.duration.inSeconds}s, ' +
          'aspectRatio: ${_videoController!.value.aspectRatio}',
          name: 'DeviceStream'
        );
        
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
            // Iniciar reproducción y bucle
            _videoController?.setLooping(true);
            _videoController?.play();
            _isVideoPlaying = true;
            AppLogger.info('Reproducción iniciada automáticamente', name: 'DeviceStream');
          });
        }
      }).catchError((error) {
        AppLogger.error(
          'Error al inicializar el video: $assetPath',
          name: 'DeviceStream',
          error: error
        );
        
        // Detallar más información sobre el error
        AppLogger.error(
          'Detalles del error: ${error.toString()}',
          name: 'DeviceStream'
        );
        
        // Intentar con un video alternativo o mostrar un mensaje de error
        _handleVideoError();
        
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
          });
        }
      });
    } catch (e) {
      AppLogger.error(
        'Excepción general al configurar el video: $assetPath',
        name: 'DeviceStream',
        error: e
      );
      
      // Manejar el error
      _handleVideoError();
      
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
        });
      }
    }
  }
  
  // Manejar errores de video
  void _handleVideoError() {
    // Intentar con un video alternativo o mostrar un mensaje
    AppLogger.info('Intentando cargar video alternativo', name: 'DeviceStream');
    
    try {
      // Liberar el controlador con error
      _videoController?.dispose();
      
      // Primero intenta con el video alternativo local
      const alternativeVideoPath = 'assets/videos/messi.mp4'; // Usar un video que sabemos que existe
      AppLogger.info('Usando video alternativo local: $alternativeVideoPath', name: 'DeviceStream');
      
      _videoController = VideoPlayerController.asset(alternativeVideoPath)
        ..initialize().then((_) {
          AppLogger.info('Video alternativo local inicializado', name: 'DeviceStream');
          if (mounted) {
            setState(() {
              _isVideoLoading = false;
              _videoController?.setLooping(true);
              _videoController?.play();
              _isVideoPlaying = true;
            });
          }
        }).catchError((error) {
          AppLogger.error(
            'Error también con el video alternativo local',
            name: 'DeviceStream',
            error: error
          );
          
          // Si falla también, intentar con un video de la web
          _tryNetworkVideo();
        });
    } catch (e) {
      AppLogger.error(
        'Error al intentar cargar video alternativo local',
        name: 'DeviceStream',
        error: e
      );
      
      // Intentar con un video de la web como última opción
      _tryNetworkVideo();
    }
  }
  
  // Intentar con un video de la red como última opción
  void _tryNetworkVideo() {
    AppLogger.info('Intentando cargar video de la red como último recurso', name: 'DeviceStream');
    
    try {
      // URL de un pequeño video MP4 de ejemplo (reemplaza con una URL real y estable)
      // Este es solo un ejemplo, asegúrate de usar una URL de confianza y que funcione
      const networkVideoUrl = 'https://www.sample-videos.com/video123/mp4/240/big_buck_bunny_240p_10mb.mp4';
      
      _videoController = VideoPlayerController.network(networkVideoUrl)
        ..initialize().then((_) {
          AppLogger.info('Video de red inicializado: $networkVideoUrl', name: 'DeviceStream');
          if (mounted) {
            setState(() {
              _isVideoLoading = false;
              _videoController?.setLooping(true);
              _videoController?.play();
              _isVideoPlaying = true;
            });
          }
        }).catchError((error) {
          AppLogger.error(
            'Error también con el video de red',
            name: 'DeviceStream',
            error: error
          );
          
          // Desactivar completamente la reproducción de video
          if (mounted) {
            setState(() {
              _isVideoLoading = false;
              _videoController = null;
            });
          }
        });
    } catch (e) {
      AppLogger.error(
        'Error al intentar cargar video de red',
        name: 'DeviceStream',
        error: e
      );
      
      // Desactivar completamente la reproducción de video
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoController = null;
        });
      }
    }
  }
  
  // Determinar qué video mostrar según los puntajes
  String _getVideoAssetPath() {
    // Verificar los formatos de video soportados (MP4, WebM, etc.)
    // Es posible que necesites convertir tus videos a un formato más compatible
    
    if (widget.puntosIzquierda > widget.puntosDerecha) {
      AppLogger.info('Seleccionando video para contendiente 1 (izquierda)', name: 'DeviceStream');
      return 'assets/videos/cristiano.mp4';
    } else if (widget.puntosDerecha > widget.puntosIzquierda) {
      AppLogger.info('Seleccionando video para contendiente 2 (derecha)', name: 'DeviceStream');
      return 'assets/videos/messi.mp4';
    } else {
      // Si hay empate, mostrar el primero por defecto
      AppLogger.info('Empate, seleccionando video por defecto', name: 'DeviceStream');
      return 'assets/videos/cristiano.mp4';
    }
  }

  // Construir widget de reproductor de video
  @override
  Widget build(BuildContext context) {
    // Determinar quién va ganando usando los puntajes del widget
    final bool isLeftWinning = widget.puntosIzquierda > widget.puntosDerecha;
    final bool isRightWinning = widget.puntosDerecha > widget.puntosIzquierda;

    // Verificar si queda poco tiempo (menos de 5 minutos)
    final bool isTimeAlmostUp = _remainingSeconds < 300;

    return AspectRatio(
      aspectRatio: 9 / 16, // Formato TikTok
      child: Stack(
        children: [
          // Fondo (siempre una imagen)
          Container(
            decoration: BoxDecoration(
              color: Colors
                  .white, // Color de fondo por defecto si no hay esqueleto/imagen
              image: DecorationImage(
                image: (widget.esqueleto != null &&
                        widget.esqueleto!['imagenUrl'] != null)
                    ? NetworkImage(widget.esqueleto!['imagenUrl'])
                        as ImageProvider
                    : const AssetImage(
                        'assets/images/vs.jpeg'), // Imagen de fondo por defecto
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              // Imagen de fondo vs.jpeg
              image: DecorationImage(
                image: AssetImage('assets/images/tiktok.PNG'),
                fit: BoxFit.cover,
                opacity: 0, // Agregando opacidad del 80%
              ),
            ),
          ),

          // Contadores del versus
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Espacio vacío para empujar el contenido hacia abajo
                  const SizedBox(height: 100),

                  // Temporizador de finalización
                  AnimatedBuilder(
                      animation: _timerPulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale:
                              isTimeAlmostUp ? _timerPulseAnimation.value : 1.0,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(178),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _getTimerColor().withAlpha(178),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getTimerColor().withAlpha(76),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: _getTimerColor(),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(_remainingSeconds),
                                  style: TextStyle(
                                    color: _getTimerColor(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                  // Contadores de puntaje
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Contador izquierdo
                      ScoreCounter(
                        score:
                            widget.puntosIzquierda, // Usar puntaje del widget
                        color: Colors.white,
                        pulseAnimation: _leftPulseAnimation,
                        label: widget.esqueleto?['contendiente1'] as String? ??
                            'Equipo 1', // Etiqueta del esqueleto
                        isWinning: isLeftWinning,
                        isLeftSide: true, // Forzar lado izquierdo
                      ),

                      // Contador derecho
                      ScoreCounter(
                        score: widget.puntosDerecha, // Usar puntaje del widget
                        color: Colors.white,
                        pulseAnimation: _rightPulseAnimation,
                        label: widget.esqueleto?['contendiente2'] as String? ??
                            'Equipo 2', // Etiqueta del esqueleto
                        isWinning: isRightWinning,
                        isLeftSide: false, // Forzar lado derecho
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: VerticalPodium(
                username: widget.mayorDonador?.nickname ?? 'Mejor Fan',
                diamondsCount: widget.mayorDonador?.diamantesTotales ?? 0,
                avatarUrl: widget.mayorDonador?.profilePictureUrl,
                shineAnimation: _shineAnimation,
              ),
            ),
          ),

          // Reproductor de video superpuesto en la parte inferior central
          if (widget.mostrarVideo)
            Positioned(
              bottom: 400,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        // Mostrar mensaje de carga o el video
                        _videoController != null &&
                                _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : Container(
                                color: Colors.black45,
                                child: Center(
                                  child: _isVideoLoading 
                                    ? const CircularProgressIndicator()
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.video_library, color: Colors.white54, size: 30),
                                          SizedBox(height: 5),
                                          Text(
                                            'Video no disponible',
                                            style: TextStyle(color: Colors.white54, fontSize: 12),
                                          )
                                        ],
                                      ),
                                ),
                              ),

                        // Indicador de líder
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: widget.puntosIzquierda >
                                        widget.puntosDerecha
                                    ? Colors.blue
                                    : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.puntosIzquierda > widget.puntosDerecha
                                  ? 'Líder: 1'
                                  : widget.puntosDerecha >
                                          widget.puntosIzquierda
                                      ? 'Líder: 2'
                                      : 'Empate',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Widget del podio vertical con nombre, avatar y diamantes
class VerticalPodium extends StatelessWidget {
  final String username;
  final int diamondsCount;
  final Animation<double> shineAnimation;
  final String? avatarUrl; // Añadido para la imagen de perfil del mayor donador

  const VerticalPodium({
    Key? key,
    required this.username,
    required this.diamondsCount,
    required this.shineAnimation,
    this.avatarUrl, // Añadido
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Imprimir información de debug sobre avatarUrl
    print('VerticalPodium - AvatarUrl: $avatarUrl');

    return Container(
      width: 100,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(178),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(76),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Avatar del usuario
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(51),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              image: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl!),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        print('Error loading avatar image: $exception');
                      },
                    )
                  : null, // No usar DecorationImage si no hay URL
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(128),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            // Mostrar un placeholder si no hay URL o está vacía
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 40)
                : null,
          ),

          // Nombre de usuario
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(153),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withAlpha(76),
                width: 1,
              ),
            ),
            child: Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para el contador con animaciones
class ScoreCounter extends StatelessWidget {
  final int score;
  final Color color;
  final Animation<double> pulseAnimation;
  final String label;
  final bool isWinning;
  final bool isLeftSide;

  const ScoreCounter({
    Key? key,
    required this.score,
    required this.color,
    required this.pulseAnimation,
    required this.label,
    required this.isWinning,
    required this.isLeftSide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Para depuración
    print('ScoreCounter - Label: $label, isLeftSide: $isLeftSide');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Etiqueta del jugador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(178),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWinning
                  ? Colors.orange.withAlpha(178)
                  : Colors.white.withAlpha(128),
              width: isWinning ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isWinning
                    ? Colors.orange.withAlpha(128)
                    : Colors.black.withAlpha(128),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isWinning ? Colors.orange.shade100 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Contador con animación
        ScaleTransition(
          scale: pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(204),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isWinning ? Colors.orange : Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: isWinning
                      ? Colors.orange.withAlpha(76)
                      : Colors.white.withAlpha(76),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(153),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withAlpha(230),
                  Colors.black.withAlpha(178),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // GIF de fuego dentro del contenedor si está ganando
                  if (isWinning)
                    Opacity(
                      opacity: 0.7,
                      child: Image.asset(
                        'assets/gif/fire.gif',
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      ),
                    ),

                  // Número del contador
                  Text(
                    score.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 60,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: Colors.white.withAlpha(204),
                          offset: const Offset(0, 0),
                        ),
                        Shadow(
                          blurRadius: 10,
                          color: isWinning
                              ? Colors.orange.withAlpha(128)
                              : Colors.blue.withAlpha(128),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Rejilla de donaciones populares - ahora se muestra siempre, no solo cuando está ganando
        GiftGrid(isLeftSide: isLeftSide),
      ],
    );
  }
}

// Widget para mostrar las donaciones populares en una rejilla
class GiftGrid extends StatelessWidget {
  final bool isLeftSide;

  const GiftGrid({
    Key? key,
    required this.isLeftSide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // con lo definido en tiktok_gift_classifier.dart
    final List<Map<String, dynamic>> gifts = isLeftSide
        ? [
            // Grupo_A (Contendiente 1) - Valores actualizados según _directGiftMapping
            {
              'name': 'Rose',
              'value': 1,
              'color': Colors.pink,
              'gift_id': 'Rose',
              'icon': '🌹',
              'image_name': 'Rose_5655.png'
            },
            {
              'name': 'Finger Heart',
              'value': 5,
              'color': Colors.red,
              'gift_id': 'Finger Heart',
              'icon': '❤️',
              'image_name': 'FingerHeart_5487.png'
            },
            {
              'name': 'Ice Cream',
              'value': 5,
              'color': Colors.cyan,
              'gift_id': 'Ice Cream Cone',
              'icon': '🍦',
              'image_name': 'icecream_8963.png'
            },
            {
              'name': 'Sausage',
              'value': 10,
              'color': Colors.orange,
              'gift_id': 'Sausage',
              'icon': '🌭',
              'image_name': 'Sausage_6124.png'
            },
            {
              'name': 'Cake',
              'value': 20,
              'color': Colors.amber,
              'gift_id': 'Cake',
              'icon': '🍰',
              'image_name': 'Cake_5720.png'
            },
            {
              'name': 'Level-up',
              'value': 99,
              'color': Colors.purple,
              'gift_id': 'Level-up Sparks',
              'icon': '⬆️',
              'image_name': 'Level-up_12678.webp'
            },
          ]
        : [
            // Grupo_B (Contendiente 2) - Valores actualizados según _directGiftMapping
            {
              'name': 'GG',
              'value': 1,
              'color': Colors.teal,
              'gift_id': 'GG',
              'icon': '👍',
              'image_name': 'GG_8286.webp'
            },
            {
              'name': 'Fire',
              'value': 5,
              'color': Colors.deepOrange,
              'gift_id': 'Fire',
              'icon': '🔥',
              'image_name': 'fire_5719.png'
            },
            {
              'name': 'Mic',
              'value': 5,
              'color': Colors.blue,
              'gift_id': 'Mic',
              'icon': '🎤',
              'image_name': 'Mic_5650.png'
            },
            {
              'name': 'Pretzel',
              'value': 10,
              'color': Colors.brown,
              'gift_id': 'Pretzel',
              'icon': '🥨',
              'image_name': 'Pretzel_7056.webp'
            },
            {
              'name': 'S Flower',
              'value': 20,
              'color': Colors.pink,
              'gift_id': 'S Flower',
              'icon': '🌸',
              'image_name': 'S Flower_14115.webp'
            },
            {
              'name': 'Birthday',
              'value': 99,
              'color': Colors.blue,
              'gift_id': 'Birthday',
              'icon': '🎂',
              'image_name': 'birhday_9096.webp'
            },
          ];

    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLeftSide
              ? Colors.blue.withAlpha(120)
              : Colors.red.withAlpha(120),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isLeftSide
                ? Colors.blue.withAlpha(40)
                : Colors.red.withAlpha(40),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isLeftSide ? 'Grupo A' : 'Grupo B',
            style: TextStyle(
              color: isLeftSide
                  ? Colors.blue.withAlpha(230)
                  : Colors.red.withAlpha(230),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160, // Altura fija para evitar overflow
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final gift = gifts[index];
                return _buildGiftItem(gift, isLeftSide);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftItem(Map<String, dynamic> gift, bool isLeftSide) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: gift['color'].withAlpha(150),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gift['color'].withAlpha(40),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withAlpha(120),
            gift['color'].withAlpha(60),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Usar imagen si está disponible, sino emoji
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
              child: _buildGiftImage(gift),
            ),
          ),

          // Valor del regalo
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              width: double.infinity,
              child: Center(
                child: Text(
                  'x${gift['value']}',
                  style: TextStyle(
                    color:
                        isLeftSide ? Colors.blue.shade100 : Colors.red.shade100,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftImage(Map<String, dynamic> gift) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(7),
        topRight: Radius.circular(7),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  gift['color'].withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Contenedor para la imagen con padding
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.asset(
              'assets/icons/${gift['image_name']}',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Emoji como fallback si la imagen no se puede cargar
                print('Error cargando imagen ${gift['image_name']}: $error');
                return Center(
                  child: Text(
                    gift['icon'],
                    style: const TextStyle(fontSize: 22),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
