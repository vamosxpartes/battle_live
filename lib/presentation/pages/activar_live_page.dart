
import 'package:flutter/material.dart';
import 'package:battle_live/data/datasources/esqueleto_service.dart';
import 'package:battle_live/core/logging/app_logger.dart';

class ActivarLivePage extends StatefulWidget {
  const ActivarLivePage({super.key});

  @override
  State<ActivarLivePage> createState() => _ActivarLivePageState();
}

class _ActivarLivePageState extends State<ActivarLivePage> {
  final EsqueletoService _esqueletoService = EsqueletoService();
  
  // Lista de esqueletos cargados desde Firebase
  List<Map<String, dynamic>> _esqueletos = [];
  
  // Esqueletos seleccionados para cada sección
  Map<String, dynamic>? _esqueleto1Seleccionado;
  Map<String, dynamic>? _esqueleto2Seleccionado;
  
  // Estado de carga
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEsqueletos();
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
  Widget _buildPhonePreview(Map<String, dynamic>? esqueleto) {
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
                                _buildContadorPreview(esqueleto['contendiente1'] ?? 'Contendiente 1', '00'),
                                _buildContadorPreview(esqueleto['contendiente2'] ?? 'Contendiente 2', '00'),
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
            _buildPhonePreview(esqueletoSeleccionado),
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
            // Si el ancho es suficiente, mostrar las secciones en fila
            if (constraints.maxWidth > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSeccion(1)),
                  Expanded(child: _buildSeccion(2)),
                ],
              );
            } else {
              // En pantallas más estrechas, mostrar las secciones en columna
              return SingleChildScrollView(
                child: Column(
                  children: [
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