import 'dart:io';
import 'dart:typed_data'; // Necesario para Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:battle_live/data/datasources/storage_service.dart';
import 'package:battle_live/data/datasources/esqueleto_service.dart';
import 'package:battle_live/core/logging/app_logger.dart';

class CrearEsqueletoPage extends StatefulWidget {
  const CrearEsqueletoPage({super.key});

  @override
  State<CrearEsqueletoPage> createState() => _CrearEsqueletoPageState();
}

class _CrearEsqueletoPageState extends State<CrearEsqueletoPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _contendiente1Controller = TextEditingController();
  final _contendiente2Controller = TextEditingController();
  
  // Servicios para almacenamiento y base de datos
  final StorageService _storageService = StorageService();
  final EsqueletoService _esqueletoService = EsqueletoService();
  
  XFile? _imagenSeleccionada;
  bool _guardando = false;
  double _progresoSubida = 0.0; // Progreso de subida de imagen (0.0 a 1.0)
  bool _subiendoImagen = false; // Flag específico para la subida de imagen

  @override
  void initState() {
    super.initState();
    AppLogger.info('Inicializando CrearEsqueletoPage', name: 'CrearEsqueletoPage');
    // Listeners para actualizar la UI de previsualización en tiempo real
    _tituloController.addListener(() => setState(() {}));
    _contendiente1Controller.addListener(() => setState(() {}));
    _contendiente2Controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contendiente1Controller.dispose();
    _contendiente2Controller.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    AppLogger.info('Iniciando selección de imagen', name: 'CrearEsqueletoPage');
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      AppLogger.info('Imagen seleccionada: ${imagen.path}', name: 'CrearEsqueletoPage');
      setState(() {
        _imagenSeleccionada = imagen;
      });
    } else {
      AppLogger.info('Selección de imagen cancelada', name: 'CrearEsqueletoPage');
    }
  }

  Future<void> _guardarEsqueleto() async {
    if (_formKey.currentState!.validate()) {
      // Validar que se haya seleccionado una imagen
      if (_imagenSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una imagen de fondo')),
        );
        return;
      }
      
      // Evitar múltiples envíos
      if (_guardando) {
        return;
      }
      
      setState(() {
        _guardando = true;
        _progresoSubida = 0.0;
        _subiendoImagen = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparando subida de imagen y esqueleto...')),
      );
      
      try {
        AppLogger.info('Iniciando proceso de guardado de esqueleto', name: 'CrearEsqueletoPage');
        
        // 1. Subir imagen a Firebase Storage
        // Determinar extensión del archivo de manera segura
        String extension = 'jpg'; // Extensión por defecto
        if (_imagenSeleccionada!.name.contains('.')) {
          extension = _imagenSeleccionada!.name.split('.').last.toLowerCase();
          // Si la extensión contiene caracteres no válidos, usar jpg
          if (extension.contains(':') || extension.contains('/')) {
            extension = 'jpg';
          }
        }
        
        final String fileName = 'esqueleto_live_background_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final String storagePath = 'esqueletos_live/imagenes_fondo/$fileName';
        
        AppLogger.info('Subiendo imagen a Storage: $storagePath', name: 'CrearEsqueletoPage');
        
        // Actualizar estado para mostrar que estamos subiendo la imagen
        setState(() {
          _subiendoImagen = true;
        });
        
        // Llamar a showSnackBar para indicar que estamos subiendo la imagen
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subiendo imagen... Esto puede tomar un momento'),
            duration: Duration(seconds: 15),
          ),
        );
        
        final String? imageUrl = await _storageService.uploadImage(
          _imagenSeleccionada!,
          storagePath,
          comprimir: true,
          calidadCompresion: 85, // Calidad ligeramente más alta para mantener buena apariencia visual
          onProgress: (progress) {
            setState(() {
              _progresoSubida = progress;
            });
          },
        );
        
        // Restablecer bandera de subida de imagen
        setState(() {
          _subiendoImagen = false;
        });
        
        if (imageUrl == null) {
          AppLogger.error('Error al subir imagen a Firebase Storage', name: 'CrearEsqueletoPage');
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir la imagen. Inténtalo de nuevo.')),
          );
          setState(() {
            _guardando = false;
          });
          return;
        }
        
        // 2. Guardar documento en Firestore
        AppLogger.info('Guardando información del esqueleto en Firestore', name: 'CrearEsqueletoPage');
        final esqueletoData = {
          'titulo': _tituloController.text,
          'contendiente1': _contendiente1Controller.text,
          'contendiente2': _contendiente2Controller.text,
          'imagenUrl': imageUrl,
        };
        
        final String? esqueletoId = await _esqueletoService.guardarEsqueleto(
          titulo: _tituloController.text,
          contendiente1: _contendiente1Controller.text,
          contendiente2: _contendiente2Controller.text,
          imagenUrl: imageUrl,
        );
        
        if (esqueletoId == null) {
          AppLogger.error('Error al guardar esqueleto en Firestore', name: 'CrearEsqueletoPage');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar información del esqueleto. La imagen se subió correctamente.')),
          );
          setState(() {
            _guardando = false;
          });
          return;
        }
        
        AppLogger.info(
          'Esqueleto guardado exitosamente. ID: $esqueletoId, Datos: $esqueletoData', 
          name: 'CrearEsqueletoPage'
        );
        
        // 3. Mostrar mensaje de éxito y volver a la pantalla anterior
        if (mounted) {
          setState(() {
            _guardando = false;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Esqueleto de Live guardado con éxito')),
          );
          Navigator.of(context).pop();
        }
      } catch (e, s) {
        AppLogger.error('Error al guardar esqueleto', name: 'CrearEsqueletoPage', error: e, stackTrace: s);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e')),
          );
          setState(() {
            _guardando = false;
          });
        }
      }
    }
  }

  Widget _buildFormulario() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título del Live',
                hintText: 'Ej: Final del Torneo 2023',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Contendientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contendiente1Controller,
              decoration: const InputDecoration(
                labelText: 'Nombre del Contendiente 1',
                hintText: 'Ej: Equipo Azul',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un nombre para el Contendiente 1';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contendiente2Controller,
              decoration: const InputDecoration(
                labelText: 'Nombre del Contendiente 2',
                hintText: 'Ej: Equipo Rojo',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un nombre para el Contendiente 2';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text('Imagen de Fondo (Formato 9:16)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarImagen,
              child: Container(
                height: 160, // Reducido para que quepa mejor en el form
                width: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _imagenSeleccionada != null
                    ? (kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: _imagenSeleccionada!.readAsBytes(),
                            builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain, // Contain para verla completa en el picker
                                  width: double.infinity,
                                  height: double.infinity,
                                );
                              } else if (snapshot.error != null) {
                                AppLogger.error('Error cargando imagen en UI', name: 'CrearEsqueletoPage', error: snapshot.error);
                                return const Center(child: Text('Error al cargar imagen'));
                              } else {
                                return const Center(child: CircularProgressIndicator());
                              }
                            },
                          )
                        : Image.file(
                            File(_imagenSeleccionada!.path),
                            fit: BoxFit.contain, // Contain para verla completa en el picker
                            width: double.infinity,
                            height: double.infinity,
                          ))
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40),
                            SizedBox(height: 8),
                            Text('Seleccionar', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Barra de progreso de subida de imagen (solo visible durante la subida)
            if (_subiendoImagen) ...[
              const Text('Subiendo imagen...', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _progresoSubida,
                backgroundColor: Colors.grey[300],
                semanticsLabel: 'Progreso de subida de imagen',
                semanticsValue: '${(_progresoSubida * 100).toInt()}%',
              ),
              Text(
                '${(_progresoSubida * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _guardando ? null : _guardarEsqueleto,
              child: _guardando 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ),
                      SizedBox(width: 10),
                      Text('Guardando...', style: TextStyle(fontSize: 16)),
                    ],
                  )
                : const Text('Guardar Esqueleto', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewEmulator() {
    // Dimensiones para simular una pantalla de teléfono (aspecto 9:16)
    const double phoneWidth = 400;
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
        child: ClipRRect( // Para que el contenido no se salga de los bordes redondeados de la pantalla interna
          borderRadius: BorderRadius.circular(10), 
          child: Container(
            width: phoneWidth,
            height: phoneHeight,
            color: Colors.grey[300], // Color de fondo si no hay imagen
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagen de fondo
                if (_imagenSeleccionada != null)
                  kIsWeb
                      ? FutureBuilder<Uint8List>(
                          future: _imagenSeleccionada!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                              return Image.memory(snapshot.data!, fit: BoxFit.cover);
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        )
                      : Image.file(File(_imagenSeleccionada!.path), fit: BoxFit.cover),
                
                // Overlay con título y contadores
                Container(
                  decoration: BoxDecoration(
                     // Gradiente sutil para legibilidad del texto
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
                        _tituloController.text.isEmpty ? 'Título del Live' : _tituloController.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                      ),
                      // Contadores
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildContadorPreview(_contendiente1Controller.text.isEmpty ? 'Contendiente 1' : _contendiente1Controller.text, '00'),
                          _buildContadorPreview(_contendiente2Controller.text.isEmpty ? 'Contendiente 2' : _contendiente2Controller.text, '00'),
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

  Widget _buildContadorPreview(String nombre, String puntaje) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 12, shadows: [Shadow(blurRadius: 1, color: Colors.black54)])),
        const SizedBox(height: 4),
        Text(puntaje, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Esqueleto de Live'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 700) { // Si es suficientemente ancho, mostrar dos columnas
              return Row(
                children: [
                  Expanded(flex: 2, child: _buildFormulario()), // Formulario ocupa más espacio
                  Expanded(flex: 1, child: _buildPreviewEmulator()),
                ],
              );
            } else { // Si no, mostrar en una sola columna (formulario arriba, previsualización abajo)
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFormulario(),
                    const SizedBox(height: 20),
                    _buildPreviewEmulator(),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
          }
        ),
      ),
    );
  }
} 