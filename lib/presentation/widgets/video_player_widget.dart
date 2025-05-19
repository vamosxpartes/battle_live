import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:battle_live/core/logging/app_logger.dart';

class VideoPlayerWidget extends StatefulWidget {
  final int puntosContendiente1;
  final int puntosContendiente2;
  
  const VideoPlayerWidget({
    Key? key,
    required this.puntosContendiente1,
    required this.puntosContendiente2,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isLoading = true;
  String _currentVideo = '';
  
  @override
  void initState() {
    super.initState();
    AppLogger.info('Inicializando VideoPlayerWidget', name: 'VideoPlayerWidget');
    _initializePlayer();
  }
  
  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Comprobar si cambió el líder para actualizar el video
    bool oldLeaderWasOne = oldWidget.puntosContendiente1 > oldWidget.puntosContendiente2;
    bool newLeaderIsOne = widget.puntosContendiente1 > widget.puntosContendiente2;
    bool wasATie = oldWidget.puntosContendiente1 == oldWidget.puntosContendiente2;
    bool isATie = widget.puntosContendiente1 == widget.puntosContendiente2;
    
    AppLogger.info(
      'Cambio en puntuación: Contendiente1 ${oldWidget.puntosContendiente1} → ${widget.puntosContendiente1}, ' +
      'Contendiente2 ${oldWidget.puntosContendiente2} → ${widget.puntosContendiente2}',
      name: 'VideoPlayerWidget'
    );
    
    // Forzar actualización en cualquiera de estos casos
    if (oldLeaderWasOne != newLeaderIsOne || wasATie != isATie) {
      AppLogger.info(
        'Cambio de líder detectado: ${oldLeaderWasOne ? "Contendiente 1" : wasATie ? "Empate" : "Contendiente 2"} → ' +
        '${newLeaderIsOne ? "Contendiente 1" : isATie ? "Empate" : "Contendiente 2"}',
        name: 'VideoPlayerWidget'
      );
      _forceVideoUpdate();
    }
  }
  
  // Inicializar el controlador de video
  void _initializePlayer() async {
    AppLogger.info('Inicializando reproductor de video', name: 'VideoPlayerWidget');
    _updateVideoBasedOnLeader();
  }
  
  // Forzar actualización del video sin importar si es el mismo
  void _forceVideoUpdate() async {
    // Forzar el reinicio del video aunque la ruta sea la misma
    String assetPath = _getVideoAssetPath();
    
    AppLogger.info('Forzando actualización de video a: $assetPath', name: 'VideoPlayerWidget');
    _currentVideo = ""; // Restablecer el video actual para forzar la actualización
    _updateVideoBasedOnLeader();
  }
  
  // Actualizar el video según quién va ganando
  void _updateVideoBasedOnLeader() async {
    String assetPath = _getVideoAssetPath();
    
    // Si ya está mostrando este video, no hacer nada
    if (_currentVideo == assetPath) {
      AppLogger.info('Video actual mantiene: $assetPath', name: 'VideoPlayerWidget');
      return;
    }
    
    AppLogger.info('Cambiando video a: $assetPath', name: 'VideoPlayerWidget');
    _currentVideo = assetPath;
    
    // Liberar el controlador anterior si existe
    if (_controller != null) {
      AppLogger.info('Eliminando controlador de video anterior', name: 'VideoPlayerWidget');
      await _controller?.dispose();
    }
    
    // Crear y configurar un nuevo controlador
    setState(() {
      _isLoading = true;
    });
    
    try {
      AppLogger.info('Verificando existencia del archivo: $assetPath', name: 'VideoPlayerWidget');
      
      AppLogger.info('Creando nuevo controlador para: $assetPath', name: 'VideoPlayerWidget');
      _controller = VideoPlayerController.asset(assetPath);
      
      // Agregar listener para detectar errores durante la reproducción
      _controller!.addListener(() {
        final value = _controller!.value;
        if (value.hasError) {
          AppLogger.error(
            'Error durante la reproducción: ${value.errorDescription}',
            name: 'VideoPlayerWidget'
          );
        }
      });
      
      await _controller!.initialize().then((_) {
        AppLogger.info(
          'Video inicializado correctamente: $assetPath, duración: ${_controller!.value.duration.inSeconds}s, ' +
          'aspectRatio: ${_controller!.value.aspectRatio}',
          name: 'VideoPlayerWidget'
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
            // Iniciar reproducción y bucle
            _controller?.setLooping(true);
            _controller?.play();
            _isPlaying = true;
            AppLogger.info('Reproducción iniciada automáticamente', name: 'VideoPlayerWidget');
          });
        }
      }).catchError((error) {
        AppLogger.error(
          'Error al inicializar el video: $assetPath',
          name: 'VideoPlayerWidget',
          error: error
        );
        
        // Detallar más información sobre el error
        AppLogger.error(
          'Detalles del error: ${error.toString()}',
          name: 'VideoPlayerWidget'
        );
        
        // Intentar con un video alternativo
        _handleVideoError();
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      AppLogger.error(
        'Excepción general al configurar el video: $assetPath',
        name: 'VideoPlayerWidget',
        error: e
      );
      
      _handleVideoError();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Manejar errores de video
  void _handleVideoError() {
    AppLogger.info('Intentando cargar video alternativo', name: 'VideoPlayerWidget');
    
    try {
      // Liberar el controlador con error
      _controller?.dispose();
      
      // Intentar con un video alternativo local primero
      // Prefiere usar un formato como .webm que tiene mejor compatibilidad en Flutter
      const alternativeVideoPath = 'assets/videos/messi.mp4'; // Usar un video que sabemos que existe
      AppLogger.info('Usando video alternativo local: $alternativeVideoPath', name: 'VideoPlayerWidget');
      
      _controller = VideoPlayerController.asset(alternativeVideoPath)
        ..initialize().then((_) {
          AppLogger.info('Video alternativo local inicializado', name: 'VideoPlayerWidget');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _controller?.setLooping(true);
              _controller?.play();
              _isPlaying = true;
            });
          }
        }).catchError((error) {
          AppLogger.error(
            'Error también con el video alternativo local',
            name: 'VideoPlayerWidget',
            error: error
          );
          
          // Si falla también, intentar con un video de la web
          _tryNetworkVideo();
        });
    } catch (e) {
      AppLogger.error(
        'Error al intentar cargar video alternativo local',
        name: 'VideoPlayerWidget',
        error: e
      );
      
      // Intentar con un video de la web como última opción
      _tryNetworkVideo();
    }
  }
  
  // Intentar con un video de la red como última opción
  void _tryNetworkVideo() {
    AppLogger.info('Intentando cargar video de la red como último recurso', name: 'VideoPlayerWidget');
    
    try {
      // URL de un pequeño video MP4 de ejemplo (reemplaza con una URL real y estable)
      // Este es solo un ejemplo, asegúrate de usar una URL de confianza y que funcione
      const networkVideoUrl = 'https://www.sample-videos.com/video123/mp4/240/big_buck_bunny_240p_10mb.mp4';
      
      _controller = VideoPlayerController.network(networkVideoUrl)
        ..initialize().then((_) {
          AppLogger.info('Video de red inicializado: $networkVideoUrl', name: 'VideoPlayerWidget');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _controller?.setLooping(true);
              _controller?.play();
              _isPlaying = true;
            });
          }
        }).catchError((error) {
          AppLogger.error(
            'Error también con el video de red',
            name: 'VideoPlayerWidget',
            error: error
          );
          
          // Desactivar completamente la reproducción de video
          if (mounted) {
            setState(() {
              _isLoading = false;
              _controller = null;
            });
          }
        });
    } catch (e) {
      AppLogger.error(
        'Error al intentar cargar video de red',
        name: 'VideoPlayerWidget',
        error: e
      );
      
      // Desactivar completamente la reproducción de video
      if (mounted) {
        setState(() {
          _isLoading = false;
          _controller = null;
        });
      }
    }
  }
  
  // Determinar qué video mostrar según los puntajes
  String _getVideoAssetPath() {
    AppLogger.info('Obteniendo ruta de video según puntuación', name: 'VideoPlayerWidget');
    
    // Es posible que necesites usar videos en formato WebM en lugar de MP4 para mejor compatibilidad
    // O convertir tus videos a un formato y códec compatible con Flutter
    
    if (widget.puntosContendiente1 > widget.puntosContendiente2) {
      AppLogger.info('Seleccionando video para contendiente 1', name: 'VideoPlayerWidget');
      return 'assets/videos/cristiano.mp4';
    } else if (widget.puntosContendiente2 > widget.puntosContendiente1) {
      AppLogger.info('Seleccionando video para contendiente 2', name: 'VideoPlayerWidget');
      return 'assets/videos/messi.mp4';
    } else {
      // Si hay empate, mostrar el primero por defecto
      AppLogger.info('Empate, seleccionando video por defecto', name: 'VideoPlayerWidget');
      return 'assets/videos/cristiano.mp4';
    }
  }
  
  // Botón para reproducir/pausar
  Widget _buildPlayPauseButton() {
    return IconButton(
      icon: Icon(
        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
        color: Colors.white,
        size: 48,
      ),
      onPressed: () {
        if (_controller == null) {
          AppLogger.warning('Se intentó controlar video pero el controlador es null', name: 'VideoPlayerWidget');
          return;
        }
        
        setState(() {
          if (_isPlaying) {
            _controller?.pause();
            AppLogger.info('Video pausado: $_currentVideo, posición: ${_controller!.value.position.inSeconds}s', name: 'VideoPlayerWidget');
          } else {
            _controller?.play();
            AppLogger.info('Video reanudado: $_currentVideo, posición: ${_controller!.value.position.inSeconds}s', name: 'VideoPlayerWidget');
          }
          _isPlaying = !_isPlaying;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _isLoading || !_controller!.value.isInitialized) {
      AppLogger.info('Mostrando indicador de carga del video', name: 'VideoPlayerWidget');
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (_isLoading) const SizedBox(height: 10),
            if (_isLoading) 
              const Text(
                'Cargando video...',
                style: TextStyle(color: Colors.white),
              ),
          ],
        ),
      );
    }
    
    // Verificar si hay error
    if (_controller!.value.hasError) {
      AppLogger.error(
        'Error en reproducción: ${_controller!.value.errorDescription}',
        name: 'VideoPlayerWidget'
      );
      
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              'Error al cargar video',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video
          VideoPlayer(_controller!),
          
          // Overlay con botones de control
          AnimatedOpacity(
            opacity: 0.5, // Siempre visible para facilitar controles
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: _buildPlayPauseButton(),
              ),
            ),
          ),
          
          // Indicador de quién va ganando
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.puntosContendiente1 > widget.puntosContendiente2 
                      ? Colors.blue 
                      : Colors.red,
                  width: 2,
                ),
              ),
              child: Text(
                widget.puntosContendiente1 > widget.puntosContendiente2
                    ? 'Ganando: Contendiente 1'
                    : widget.puntosContendiente2 > widget.puntosContendiente1
                        ? 'Ganando: Contendiente 2'
                        : 'Empate',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.info('Eliminando VideoPlayerWidget', name: 'VideoPlayerWidget');
    _controller?.dispose();
    super.dispose();
  }
} 