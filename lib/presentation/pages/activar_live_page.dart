import 'package:flutter/material.dart';
import 'package:battle_live/data/datasources/esqueleto_service.dart';
import 'package:battle_live/core/logging/app_logger.dart';
import 'package:battle_live/services/tiktok_service.dart';
import 'package:battle_live/config/app_config.dart';
import 'dart:async';

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
  
  // Esqueletos seleccionados para cada sección
  Map<String, dynamic>? _esqueleto1Seleccionado;
  Map<String, dynamic>? _esqueleto2Seleccionado;
  
  // Contadores de puntos por sección
  int _puntosSeccion1 = 0;
  int _puntosSeccion2 = 0;
  
  // Estado de carga
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEsqueletos();
    
    // Ya no es necesario inicializar el servicio TikTok aquí
    
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

  // Activar el esqueleto seleccionado (implementación pendiente)
  Future<void> _activarEsqueleto(Map<String, dynamic>? esqueleto, int seccion) async {
    if (esqueleto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecciona un esqueleto para la sección $seccion')),
      );
      return;
    }

    // TODO: Implementar la lógica real de activación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Activando "${esqueleto['titulo']}" en sección $seccion...')),
    );
  }

  // Construir el widget de pantalla de teléfono con previsualización
  Widget _buildPhonePreview(Map<String, dynamic>? esqueleto, int seccion) {
    // Determinar los puntos según la sección
    final puntos = seccion == 1 ? _puntosSeccion1 : _puntosSeccion2;
    
    // Dimensiones para simular una pantalla de teléfono (aspecto 9:16)
    const double phoneWidth = 180;
    const double phoneHeight = phoneWidth * (16 / 9);

    return Center(
      child: Container(
        width: phoneWidth + 20, // Ancho extra para el borde del "teléfono"
        height: phoneHeight + 40, // Altura extra para el borde
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade700, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: phoneWidth,
            height: phoneHeight,
            color: Colors.grey[300], // Color de fondo si no hay imagen
            child: esqueleto == null
                ? const Center(child: Text('Selecciona un esqueleto', style: TextStyle(color: Colors.black54)))
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // Imagen de fondo
                      esqueleto['imagenUrl'] != null
                          ? Image.network(
                              esqueleto['imagenUrl'],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.broken_image, size: 50));
                              },
                            )
                          : Container(color: Colors.grey),
                      
                      // Overlay con título y contadores
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.5), Colors.transparent, Colors.black.withOpacity(0.5)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5, 1.0]
                          )
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Título del Live
                            Text(
                              esqueleto['titulo'] ?? 'Título del Live',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 14, 
                                fontWeight: FontWeight.bold, 
                                shadows: [Shadow(blurRadius: 2, color: Colors.black54)]
                              ),
                            ),
                            // Contadores
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildContadorPreview(esqueleto['contendiente1'] ?? 'Contendiente 1', '$puntos'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Construir los widgets de contador para la previsualización
  Widget _buildContadorPreview(String nombre, String puntaje) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nombre, 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 10, 
            shadows: [Shadow(blurRadius: 1, color: Colors.black54)]
          )
        ),
        const SizedBox(height: 4),
        Text(
          puntaje, 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.bold, 
            shadows: [Shadow(blurRadius: 2, color: Colors.black54)]
          )
        ),
      ],
    );
  }

  // Construir una sección completa (pantalla, dropdown, botón)
  Widget _buildSeccion(int numeroSeccion) {
    // Determinar qué esqueleto está seleccionado para esta sección
    Map<String, dynamic>? esqueletoSeleccionado = 
        numeroSeccion == 1 ? _esqueleto1Seleccionado : _esqueleto2Seleccionado;
    
    // Función para actualizar el esqueleto seleccionado
    void onEsqueletoSeleccionado(Map<String, dynamic>? nuevoEsqueleto) {
      setState(() {
        if (numeroSeccion == 1) {
          _esqueleto1Seleccionado = nuevoEsqueleto;
        } else {
          _esqueleto2Seleccionado = nuevoEsqueleto;
        }
      });
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título de la sección
            Text(
              'Sección $numeroSeccion',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Previsualización del esqueleto seleccionado
            _buildPhonePreview(esqueletoSeleccionado, numeroSeccion),
            const SizedBox(height: 24),
            
            // Dropdown para seleccionar esqueleto
            _cargando
            ? const CircularProgressIndicator()
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar esqueleto',
                      border: OutlineInputBorder(),
                    ),
                    value: esqueletoSeleccionado?['id'],
                    hint: const Text('Selecciona un esqueleto'),
                    items: _esqueletos.map((esqueleto) {
                      return DropdownMenuItem<String>(
                        value: esqueleto['id'],
                        child: Text('${esqueleto['titulo']} (${esqueleto['contendiente1']} vs ${esqueleto['contendiente2']})'),
                      );
                    }).toList(),
                    onChanged: (String? esqueletoId) {
                      if (esqueletoId != null) {
                        final esqueletoSeleccionado = _esqueletos.firstWhere(
                          (esqueleto) => esqueleto['id'] == esqueletoId,
                          orElse: () => {},
                        );
                        onEsqueletoSeleccionado(esqueletoSeleccionado);
                      } else {
                        onEsqueletoSeleccionado(null);
                      }
                    },
                  ),
            const SizedBox(height: 24),
            
            // Botón para activar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _cargando || _error != null
                    ? null
                    : () => _activarEsqueleto(
                          numeroSeccion == 1
                              ? _esqueleto1Seleccionado
                              : _esqueleto2Seleccionado,
                          numeroSeccion,
                        ),
                child: const Text('Activar'),
              ),
            ),
          ],
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
            // Si el ancho es suficiente, mostrar secciones en filas y columnas
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel de TikTok en la izquierda
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: _buildTikTokControlPanel(),
                    ),
                  ),
                  
                  // Secciones a la derecha
                  Expanded(
                    flex: 2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildSeccion(1)),
                        Expanded(child: _buildSeccion(2)),
                      ],
                    ),
                  ),
                ],
              );
            } else if (constraints.maxWidth > 700) {
              // En pantallas intermedias, mostrar secciones en fila abajo del panel
              return Column(
                children: [
                  // Panel de TikTok arriba
                  _buildTikTokControlPanel(),
                  
                  // Secciones abajo
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildSeccion(1)),
                        Expanded(child: _buildSeccion(2)),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // En pantallas más estrechas, mostrar todo en columna
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTikTokControlPanel(),
                    _buildSeccion(1),
                    _buildSeccion(2),
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