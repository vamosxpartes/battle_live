import 'package:flutter/material.dart';
import 'dart:async';
// Importar la clase Donador desde activar_live_page.dart
// Idealmente, Donador sería un modelo en una ubicación compartida.
import 'package:battle_live/presentation/pages/activar_live_page.dart' show Donador;

class DeviceStream extends StatefulWidget {
  final Map<String, dynamic>? esqueleto;
  final int puntosIzquierda;
  final int puntosDerecha;
  final Donador? mayorDonador;

  const DeviceStream({
    super.key,
    this.esqueleto,
    required this.puntosIzquierda,
    required this.puntosDerecha,
    this.mayorDonador,
  });

  @override
  State<DeviceStream> createState() => _DeviceStreamState();
}

class _DeviceStreamState extends State<DeviceStream>
    with TickerProviderStateMixin {
  // Variables para el temporizador regresivo
  int _remainingSeconds = 3600; // 1 hora inicial
  late Timer _countdownTimer;

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

  @override
  void initState() {
    super.initState();

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

    // Iniciar contador regresivo
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _countdownTimer.cancel();
          }
        });
      }
    });
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
  void didUpdateWidget(DeviceStream oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Activar pulsaciones si los puntajes cambian
    if (widget.puntosIzquierda > oldWidget.puntosIzquierda) {
      _pulseLeftScore();
    }
    if (widget.puntosDerecha > oldWidget.puntosDerecha) {
      _pulseRightScore();
    }
  }

  @override
  void dispose() {
    _leftPulseController.dispose();
    _rightPulseController.dispose();
    _shineController.dispose();
    _timerPulseController.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

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
          Container(
            decoration: BoxDecoration(
              color: Colors.white, // Color de fondo por defecto si no hay esqueleto/imagen
              image: DecorationImage(
                image: (widget.esqueleto != null && widget.esqueleto!['imagenUrl'] != null)
                    ? NetworkImage(widget.esqueleto!['imagenUrl']) as ImageProvider
                    : const AssetImage('assets/images/vs.jpeg'), // Imagen de fondo por defecto
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
                        score: widget.puntosIzquierda, // Usar puntaje del widget
                        color: Colors.white,
                        pulseAnimation: _leftPulseAnimation,
                        label: widget.esqueleto?['contendiente1'] as String? ?? 'Equipo 1', // Etiqueta del esqueleto
                        isWinning: isLeftWinning,
                      ),

                      // Podio vertical en el centro
                      VerticalPodium(
                        username: widget.mayorDonador?.nickname ?? 'Mejor Fan',
                        diamondsCount: widget.mayorDonador?.diamantesTotales ?? 0,
                        avatarUrl: widget.mayorDonador?.profilePictureUrl,
                        shineAnimation: _shineAnimation,
                      ),

                      // Contador derecho
                      ScoreCounter(
                        score: widget.puntosDerecha, // Usar puntaje del widget
                        color: Colors.white,
                        pulseAnimation: _rightPulseAnimation,
                        label: widget.esqueleto?['contendiente2'] as String? ?? 'Equipo 2', // Etiqueta del esqueleto
                        isWinning: isRightWinning,
                      ),
                    ],
                  ),
                ],
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
    return Container(
      width: 100,
      height: 230,
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
              image: DecorationImage(
                // Usar avatarUrl si está disponible, de lo contrario, una imagen por defecto o nada
                image: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : const NetworkImage('https://i.pravatar.cc/150?img=404') as ImageProvider, // Placeholder o imagen por defecto
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(128),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
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

          // Contador de diamantes
          Column(
            children: [
              // Ícono de diamante
              AnimatedBuilder(
                animation: shineAnimation,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: [
                          Colors.blue.shade300,
                          Colors.lightBlueAccent.shade100,
                          Colors.blue.shade300,
                        ],
                        stops: [
                          0.0,
                          shineAnimation.value,
                          1.0,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Icon(
                      Icons.diamond,
                      color: Colors.white,
                      size: 40,
                      shadows: [
                        Shadow(
                          color: Colors.blue.withAlpha(128),
                          blurRadius: 15,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Número de diamantes
              Text(
                diamondsCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      color: Colors.blue.withAlpha(128),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
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

  const ScoreCounter({
    Key? key,
    required this.score,
    required this.color,
    required this.pulseAnimation,
    required this.label,
    this.isWinning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}