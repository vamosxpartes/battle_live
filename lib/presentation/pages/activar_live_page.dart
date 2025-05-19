import 'package:flutter/material.dart';
import 'package:battle_live/data/datasources/esqueleto_service.dart';
import 'package:battle_live/core/logging/app_logger.dart';
import 'package:battle_live/services/tiktok_service.dart';
import 'package:battle_live/config/app_config.dart';
import 'dart:async';
import 'package:battle_live/presentation/widgets/device_stream_screen.dart';

// Modelo para donador
class Donador {
  final String uniqueId;
  final String nickname;
  final String? profilePictureUrl;
  int diamantesTotales;
  DateTime ultimaDonacion;

  Donador({
    required this.uniqueId,
    required this.nickname,
    this.profilePictureUrl,
    this.diamantesTotales = 0,
    DateTime? ultimaDonacion,
  }) : ultimaDonacion = ultimaDonacion ?? DateTime.now();

  void agregarDonacion(int diamantes) {
    diamantesTotales += diamantes;
    ultimaDonacion = DateTime.now();
  }
  
  // Obtener el tiempo transcurrido desde la última donación
  String get tiempoTranscurrido {
    final now = DateTime.now();
    final difference = now.difference(ultimaDonacion);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Ahora';
    }
  }
}

class ActivarLivePage extends StatefulWidget {
  const ActivarLivePage({super.key});

  @override
  State<ActivarLivePage> createState() => _ActivarLivePageState();
}

class _ActivarLivePageState extends State<ActivarLivePage> {
  final EsqueletoService _esqueletoService = EsqueletoService();
  
  // TikTok service - inicializado directamente
  final TikTokService _tikTokService = TikTokService(
    serverUrl: AppConfig().socketServerUrl
  );
  
  // Controlador para el usuario de TikTok
  final TextEditingController _usuarioTikTokController = TextEditingController();
  
  // Estado de conexión TikTok
  bool _tiktokConectado = false;
  String _tiktokUsuario = '';
  
  // Timer para actualizar puntos automáticamente
  Timer? _actualizadorPuntos;
  
  // Lista de esqueletos cargados desde Firebase
  List<Map<String, dynamic>> _esqueletos = [];
  
  // Esqueleto seleccionado para el DeviceStream
  Map<String, dynamic>? _esqueletoSeleccionadoParaStream;
  
  // Contadores de puntos (ahora para DeviceStream)
  int _puntosSeccion1 = 0; // Representará puntosIzquierda para DeviceStream
  int _puntosSeccion2 = 0; // Representará puntosDerecha para DeviceStream
  
  // Estado de carga
  bool _cargando = true;
  String? _error;

  // Historial de donadores
  final Map<String, Donador> _donadores = {};
  Donador? _mayorDonador;

  // Propiedades para el temporizador
  int _tiempoSeleccionado = 3600; // 1 hora por defecto
  bool _temporizadorPausado = false;

  @override
  void initState() {
    super.initState();
    _cargarEsqueletos();
    
    // Configurar listeners para TikTok
    _configurarTikTokListeners();
  }
  
  // Configurar listeners para el servicio TikTok
  void _configurarTikTokListeners() {
    // Escuchar cambios en el estado de conexión
    _tikTokService.client.connectionStateStream.listen((event) {
      setState(() {
        _tiktokConectado = event.isConnected;
        _tiktokUsuario = event.username;
      });
      
      // Iniciar o detener el timer de actualización según el estado de conexión
      if (_tiktokConectado) {
        _iniciarActualizadorPuntos();
      } else {
        _detenerActualizadorPuntos();
      }
    });

    // Escuchar eventos de regalos para actualizar donadores
    _tikTokService.client.giftStream.listen((giftEvent) {
      // Crear un mapa con la información necesaria
      Map<String, dynamic> data = {
        'eventName': 'gift',
        'user': {
          'uniqueId': giftEvent.userId,
          'nickname': giftEvent.username,
          'profilePictureUrl': giftEvent.avatarUrl,
        },
        'gift': {
          'diamondCount': giftEvent.diamondCount,
          'repeatCount': giftEvent.repeatCount,
        }
      };
      
      _actualizarDonadores(data);
    });
  }

  // Actualizar la lista de donadores cuando se recibe un regalo
  void _actualizarDonadores(Map<String, dynamic> data) {
    try {
      final userData = data['user'] as Map<String, dynamic>?;
      final giftData = data['gift'] as Map<String, dynamic>?;
      
      if (userData == null || giftData == null) return;
      
      final uniqueId = userData['uniqueId'] as String;
      final nickname = userData['nickname'] as String;
      
      // Manejar el nuevo formato de profilePictureUrl que ahora es un objeto con urls
      String? profilePictureUrl;
      final profilePicData = userData['profilePictureUrl'];
      
      if (profilePicData is String) {
        // Formato antiguo: directamente una URL
        profilePictureUrl = profilePicData;
      } else if (profilePicData is Map<String, dynamic>) {
        // Nuevo formato: objeto con array de URLs
        final urls = profilePicData['urls'];
        if (urls is List && urls.isNotEmpty) {
          profilePictureUrl = urls[0] as String?;
        }
      }
      
      final diamondCount = giftData['diamondCount'] as int;
      final repeatCount = giftData['repeatCount'] as int? ?? 1;
      
      // Calcular valor total de la donación
      final valorTotal = diamondCount * repeatCount;
      
      // Actualizar o crear registro del donador
      if (_donadores.containsKey(uniqueId)) {
        _donadores[uniqueId]!.agregarDonacion(valorTotal);
      } else {
        _donadores[uniqueId] = Donador(
          uniqueId: uniqueId,
          nickname: nickname,
          profilePictureUrl: profilePictureUrl,
          diamantesTotales: valorTotal,
        );
      }
      
      // Actualizar mayor donador
      _actualizarMayorDonador();
      
      // Actualizar UI
      if (mounted) {
        setState(() {});
      }
      
      AppLogger.info(
        'Donación registrada: $nickname donó $valorTotal diamantes (Total: ${_donadores[uniqueId]!.diamantesTotales})',
        name: 'ActivarLivePage'
      );
    } catch (e, s) {
      AppLogger.error(
        'Error al procesar donación', 
        name: 'ActivarLivePage',
        error: e,
        stackTrace: s
      );
    }
  }
  
  // Determinar quién es el mayor donador
  void _actualizarMayorDonador() {
    if (_donadores.isEmpty) {
      _mayorDonador = null;
      return;
    }
    
    Donador? topDonador;
    int maxDiamantes = 0;
    
    for (final donador in _donadores.values) {
      if (donador.diamantesTotales > maxDiamantes) {
        maxDiamantes = donador.diamantesTotales;
        topDonador = donador;
      }
    }
    
    setState(() {
      _mayorDonador = topDonador;
    });
  }
  
  // Reiniciar historial de donadores
  void _reiniciarDonadores() {
    setState(() {
      _donadores.clear();
      _mayorDonador = null;
    });
    
    AppLogger.info('Historial de donadores reiniciado', name: 'ActivarLivePage');
  }
  
  // Iniciar timer para actualizar puntos periódicamente
  void _iniciarActualizadorPuntos() {
    AppLogger.info('Iniciando actualizador de puntos automático', name: 'ActivarLivePage');
    _actualizadorPuntos?.cancel();
    
    // Actualizar inmediatamente
    _actualizarContadores();
    
    // Configurar el timer para actualizaciones periódicas
    _actualizadorPuntos = Timer.periodic(const Duration(seconds: 1), (_) {
      _actualizarContadores();
    });
  }
  
  // Actualizar los contadores manualmente
  void _actualizarContadores() {
    if (mounted) {
      final puntos1 = _tikTokService.puntosContendiente1;
      final puntos2 = _tikTokService.puntosContendiente2;
      
      AppLogger.info(
        'Actualizando contadores UI - Contendiente 1: $puntos1, Contendiente 2: $puntos2', 
        name: 'ActivarLivePage'
      );
      
      setState(() {
        _puntosSeccion1 = puntos1;
        _puntosSeccion2 = puntos2;
      });
    }
  }
  
  // Detener timer de actualización
  void _detenerActualizadorPuntos() {
    AppLogger.info('Deteniendo actualizador de puntos', name: 'ActivarLivePage');
    _actualizadorPuntos?.cancel();
    _actualizadorPuntos = null;
  }
  
  // Conectar a usuario TikTok
  Future<void> _conectarUsuarioTikTok() async {
    final username = _usuarioTikTokController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre de usuario')),
      );
      return;
    }
    
    setState(() {
      _cargando = true;
    });
    
    try {
      final conectado = await _tikTokService.conectarUsuario(username);
      
      if (!mounted) return;
      
      if (conectado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conectado a @$username')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo conectar a @$username')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }
  
  // Desconectar de TikTok
  void _desconectarTikTok() {
    _tikTokService.desconectar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Desconectado de TikTok')),
    );
  }

  // Cargar esqueletos desde Firebase
  Future<void> _cargarEsqueletos() async {
    AppLogger.info('Cargando esqueletos en ActivarLivePage', name: 'ActivarLivePage');
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final esqueletos = await _esqueletoService.obtenerEsqueletos();
      
      if (!mounted) return;
      
      if (esqueletos.isEmpty) {
        AppLogger.info('No se encontraron esqueletos guardados', name: 'ActivarLivePage');
        setState(() {
          _esqueletos = [];
          _cargando = false;
          _error = 'No hay esqueletos guardados. Por favor, crea un esqueleto primero.';
        });
      } else {
        AppLogger.info('${esqueletos.length} esqueletos cargados correctamente', name: 'ActivarLivePage');
        setState(() {
          _esqueletos = esqueletos;
          _cargando = false;
        });
      }
    } catch (e, s) {
      AppLogger.error(
        'Error al cargar esqueletos', 
        name: 'ActivarLivePage',
        error: e,
        stackTrace: s
      );
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Error al cargar esqueletos: $e';
      });
    }
  }

  // Widget que muestra al mayor donador
  Widget _buildMayorDonadorCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.amber.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Mayor Donador',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              if (_mayorDonador == null)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Esperando donaciones...',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Avatar con imagen de perfil
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Fondo brillante
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Colors.amber.shade300, Colors.amber.shade100.withAlpha(100)],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        // Avatar
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.amber.shade200,
                          backgroundImage: _mayorDonador!.profilePictureUrl != null
                              ? NetworkImage(_mayorDonador!.profilePictureUrl!)
                              : null,
                          child: _mayorDonador!.profilePictureUrl == null
                              ? Icon(Icons.person, size: 40, color: Colors.amber.shade800)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Nombre del donador
                    Text(
                      _mayorDonador!.nickname,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '@${_mayorDonador!.uniqueId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Última donación
                    Text(
                      'Última donación: ${_mayorDonador!.tiempoTranscurrido}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Total de diamantes
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade200.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond, color: Colors.amber.shade800, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '${_mayorDonador!.diamantesTotales}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
              const SizedBox(height: 16),
              
              // Botón para reiniciar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar donadores'),
                  onPressed: _reiniciarDonadores,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade800,
                    side: BorderSide(color: Colors.amber.shade300),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Panel de control de TikTok
  Widget _buildTikTokControlPanel() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Control de TikTok Live',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Estado de conexión
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _tiktokConectado ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _tiktokConectado ? Icons.check_circle : Icons.error, 
                    color: _tiktokConectado ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _tiktokConectado 
                          ? 'Conectado a @$_tiktokUsuario' 
                          : 'Desconectado',
                      style: TextStyle(
                        color: _tiktokConectado ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Campo de usuario y botones
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usuarioTikTokController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario TikTok',
                      prefixText: '@',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_tiktokConectado,
                  ),
                ),
                const SizedBox(width: 8),
                _tiktokConectado
                    ? ElevatedButton(
                        onPressed: _desconectarTikTok,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Desconectar'),
                      )
                    : ElevatedButton(
                        onPressed: _conectarUsuarioTikTok,
                        child: const Text('Conectar'),
                      ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Contadores actuales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Puntos acumulados:', style: Theme.of(context).textTheme.titleMedium),
                
                // Botón para actualizar contadores manualmente
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _tiktokConectado ? _actualizarContadores : null,
                  tooltip: 'Actualizar contadores manualmente',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildContadorTikTok('Contendiente 1', _puntosSeccion1, Colors.blue),
                _buildContadorTikTok('Contendiente 2', _puntosSeccion2, Colors.red),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botón para reiniciar contadores
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reiniciar contadores'),
                onPressed: _tiktokConectado ? () {
                  _tikTokService.reiniciarPuntos();
                  _actualizarContadores();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para mostrar contadores de TikTok
  Widget _buildContadorTikTok(String nombre, int puntos, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            nombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$puntos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para controlar el temporizador
  Widget _buildControlTemporizador() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control de Temporizador',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Tiempo actual
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(_tiempoSeleccionado),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _tiempoSeleccionado < 300 ? Colors.red : 
                          _tiempoSeleccionado < 900 ? Colors.orange : 
                          Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Presets de tiempo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimePresetButton('30s', 30),
                _buildTimePresetButton('1m', 60),
                _buildTimePresetButton('5m', 300),
                _buildTimePresetButton('30m', 1800),
                _buildTimePresetButton('1h', 3600),
              ],
            ),
            const SizedBox(height: 16),
            
            // Botones de control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón para reducir 1 minuto
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _ajustarTiempo(-60),
                  tooltip: 'Reducir 1 minuto',
                  iconSize: 30,
                  color: Colors.red,
                ),
                
                // Botón para pausar/reanudar
                ElevatedButton.icon(
                  icon: Icon(_temporizadorPausado ? Icons.play_arrow : Icons.pause),
                  label: Text(_temporizadorPausado ? 'Reanudar' : 'Pausar'),
                  onPressed: _togglePausa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _temporizadorPausado ? Colors.green : Colors.amber,
                    foregroundColor: _temporizadorPausado ? Colors.white : Colors.black87,
                  ),
                ),
                
                // Botón para agregar 1 minuto
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _ajustarTiempo(60),
                  tooltip: 'Añadir 1 minuto',
                  iconSize: 30,
                  color: Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botón para reiniciar el temporizador
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar temporizador'),
                onPressed: _reiniciarTemporizador,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Formatear tiempo en formato HH:MM:SS
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
  
  // Botón para presets de tiempo
  Widget _buildTimePresetButton(String label, int seconds) {
    final bool isSelected = _tiempoSeleccionado == seconds;
    
    return ElevatedButton(
      onPressed: () => _establecerTiempo(seconds),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
  
  // Métodos para controlar el temporizador
  void _establecerTiempo(int seconds) {
    setState(() {
      _tiempoSeleccionado = seconds;
    });
  }
  
  void _ajustarTiempo(int segundosAjuste) {
    setState(() {
      _tiempoSeleccionado = (_tiempoSeleccionado + segundosAjuste).clamp(0, 7200); // Limitar entre 0 y 2 horas
    });
  }
  
  void _togglePausa() {
    setState(() {
      _temporizadorPausado = !_temporizadorPausado;
    });
  }
  
  void _reiniciarTemporizador() {
    setState(() {
      _tiempoSeleccionado = 3600; // Volver a 1 hora
      _temporizadorPausado = false;
    });
  }
  
  // Método para actualizar el tiempo desde el widget DeviceStream
  void _actualizarTiempoDesdeStream(int nuevoTiempo) {
    if (!_temporizadorPausado && mounted) {
      setState(() {
        _tiempoSeleccionado = nuevoTiempo;
      });
    }
  }

  // Widget para seleccionar el esqueleto para el DeviceStream
  Widget _buildSelectorEsqueleto() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración del Live',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Text(_error!, style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic))
                  : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar fondo y contendientes',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                      ),
                      value: _esqueletoSeleccionadoParaStream?['id'],
                      hint: const Text('Elige un esqueleto'),
                      isExpanded: true,
                      items: _esqueletos.map((esqueleto) {
                        return DropdownMenuItem<String>(
                          value: esqueleto['id'],
                          child: Text(
                            '${esqueleto['titulo'] ?? 'Esqueleto sin título'} (${esqueleto['contendiente1'] ?? 'N/A'} vs ${esqueleto['contendiente2'] ?? 'N/A'})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? esqueletoId) {
                        if (esqueletoId != null) {
                          final seleccionado = _esqueletos.firstWhere(
                            (e) => e['id'] == esqueletoId,
                            orElse: () => {},
                          );
                          setState(() {
                            _esqueletoSeleccionadoParaStream = seleccionado.isNotEmpty ? seleccionado : null;
                          });
                        } else {
                          setState(() {
                            _esqueletoSeleccionadoParaStream = null;
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Por favor selecciona un esqueleto' : null,
                    ),
          ],
        ),
      ),
    );
  }

  // Widget para el panel de control lateral
  Widget _buildPanelDeControl() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTikTokControlPanel(),
          const SizedBox(height: 16),
          _buildControlTemporizador(), // Nuevo control de temporizador
          const SizedBox(height: 16),
          _buildSelectorEsqueleto(),
          const SizedBox(height: 16),
          _buildMayorDonadorCard(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usuarioTikTokController.dispose();
    _tikTokService.dispose();
    _detenerActualizadorPuntos();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activar Live'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEsqueletos,
            tooltip: 'Recargar esqueletos',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Diseño responsivo mejorado basado en el ancho de la pantalla
            if (constraints.maxWidth > 1200) {
              // Pantalla muy ancha - Panel de control a la derecha, más espacio para el stream
              return Row(
                children: [
                  Expanded(
                    flex: 4, // Más espacio para el stream en pantallas más grandes
                    child: Center(
                      child: DeviceStream(
                        esqueleto: _esqueletoSeleccionadoParaStream,
                        puntosIzquierda: _puntosSeccion1,
                        puntosDerecha: _puntosSeccion2,
                        mayorDonador: _mayorDonador,
                        tiempoInicial: _tiempoSeleccionado,
                        pausarTemporizador: _temporizadorPausado,
                        onTiempoActualizado: _actualizarTiempoDesdeStream,
                      ),
                    ),
                  ),
                  Container(
                    width: 380, // Ancho fijo para el panel de control
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300, width: 1)
                      ),
                    ),
                    child: _buildPanelDeControl(),
                  ),
                ],
              );
            } else if (constraints.maxWidth > 800) {
              // Pantalla ancha - Panel de control a la derecha, menos espacio para el stream
              return Row(
                children: [
                  Expanded(
                    flex: 3, 
                    child: Center(
                      child: DeviceStream(
                        esqueleto: _esqueletoSeleccionadoParaStream,
                        puntosIzquierda: _puntosSeccion1,
                        puntosDerecha: _puntosSeccion2,
                        mayorDonador: _mayorDonador,
                        tiempoInicial: _tiempoSeleccionado,
                        pausarTemporizador: _temporizadorPausado,
                        onTiempoActualizado: _actualizarTiempoDesdeStream,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 350, // Ancho fijo para el panel de control
                    child: _buildPanelDeControl(),
                  ),
                ],
              );
            } else if (constraints.maxWidth > 600) {
              // Tablet - Vista separada pero con mejor proporción
              return Column(
                children: [
                  SizedBox(
                    height: constraints.maxHeight * 0.6,
                    child: Center(
                      child: DeviceStream(
                        esqueleto: _esqueletoSeleccionadoParaStream,
                        puntosIzquierda: _puntosSeccion1,
                        puntosDerecha: _puntosSeccion2,
                        mayorDonador: _mayorDonador,
                        tiempoInicial: _tiempoSeleccionado,
                        pausarTemporizador: _temporizadorPausado,
                        onTiempoActualizado: _actualizarTiempoDesdeStream,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _buildPanelDeControl(),
                  ),
                ],
              );
            } else {
              // Teléfono - Vista apilada compacta
              return SingleChildScrollView(
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 9/16,
                      child: DeviceStream(
                        esqueleto: _esqueletoSeleccionadoParaStream,
                        puntosIzquierda: _puntosSeccion1,
                        puntosDerecha: _puntosSeccion2,
                        mayorDonador: _mayorDonador,
                        tiempoInicial: _tiempoSeleccionado,
                        pausarTemporizador: _temporizadorPausado,
                        onTiempoActualizado: _actualizarTiempoDesdeStream,
                      ),
                    ),
                    const Divider(height: 1),
                    _buildPanelDeControl(),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
} 