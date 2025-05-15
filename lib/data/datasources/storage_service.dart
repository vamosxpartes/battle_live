import 'dart:io';
import 'dart:typed_data'; // Necesario para Uint8List
import 'package:battle_live/core/logging/app_logger.dart'; // Importar AppLogger
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Necesario para kIsWeb
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  /// Sube una imagen a Firebase Storage y devuelve la URL de descarga.
  /// 
  /// [imageFile]: El archivo de imagen a subir (obtenido de image_picker).
  /// [path]: La ruta en Firebase Storage donde se guardará la imagen 
  ///         (ej: 'esqueletos_live/imagenes_fondo/nombre_del_archivo.jpg').
  /// [comprimir]: Si se debe comprimir la imagen antes de subirla (por defecto: true).
  /// [calidadCompresion]: Calidad de compresión de 0 a 100 (por defecto: 80).
  Future<String?> uploadImage(
    XFile imageFile, 
    String path, {
    bool comprimir = true,
    int calidadCompresion = 80,
    Function(double)? onProgress,
  }) async {
    AppLogger.info('Iniciando subida de imagen a Firebase Storage: $path', name: 'StorageService');
    
    try {
      final firebase_storage.Reference ref = _storage.ref().child(path);
      AppLogger.info('Referencia de storage creada: ${ref.fullPath}', name: 'StorageService');
      
      firebase_storage.UploadTask uploadTask;

      // Verificar el tamaño de la imagen antes de subirla
      final Uint8List bytesOriginales = await imageFile.readAsBytes();
      final int tamanoOriginal = bytesOriginales.length;
      
      AppLogger.info('Tamaño original de la imagen: ${(tamanoOriginal / 1024 / 1024).toStringAsFixed(2)} MB', 
          name: 'StorageService');
      
      // Determinar formato basado en la extensión del archivo
      String formato = path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(formato)) {
        formato = 'jpg'; // Formato por defecto si la extensión no es compatible
      }
      
      // Comprimir la imagen si es necesario
      Uint8List bytesImagen;
      bool usoImagenOriginal = false;
      
      if (comprimir && tamanoOriginal > 1024 * 50) { // Solo comprimir si es mayor a 50KB
        AppLogger.info('Comprimiendo imagen con calidad $calidadCompresion...', name: 'StorageService');
        
        try {
          Uint8List bytesComprimidos;
          
          if (kIsWeb) {
            // Web: compresión de bytes - ajustar calidad según el formato
            int calidadAjustada = calidadCompresion;
            // Reducir calidad para PNG y formatos grandes
            if (formato == 'png' && tamanoOriginal > 1024 * 1024) {
              calidadAjustada = calidadCompresion - 10; // Reducir calidad para PNG grandes
            }
            
            bytesComprimidos = await FlutterImageCompress.compressWithList(
              bytesOriginales,
              quality: calidadAjustada,
              format: _obtenerFormato(formato),
              // Reducir resolución para imágenes muy grandes
              minHeight: 1920, // Limitar altura máxima
              minWidth: 1080,  // Limitar ancho máximo
            );
          } else {
            // Móvil/Escritorio: compresión desde archivo
            final File tempFile = File(imageFile.path);
            
            // Crear un archivo temporal para la imagen comprimida
            final String dir = tempFile.parent.path;
            final String nombreArchivoComprimido = 'compressed_${DateTime.now().millisecondsSinceEpoch}.$formato';
            final String rutaComprimido = '$dir/$nombreArchivoComprimido';
            
            final XFile? archivoComprimido = await FlutterImageCompress.compressAndGetFile(
              imageFile.path,
              rutaComprimido,
              quality: calidadCompresion,
              format: _obtenerFormato(formato),
              // Reducir resolución para imágenes muy grandes
              minHeight: 1920, // Limitar altura máxima
              minWidth: 1080,  // Limitar ancho máximo
            ) as XFile?;
            
            if (archivoComprimido == null) {
              throw Exception('Error al comprimir la imagen');
            }
            
            bytesComprimidos = await archivoComprimido.readAsBytes();
            // Eliminar el archivo temporal después de leerlo
            final File archivoTemporal = File(archivoComprimido.path);
            if (await archivoTemporal.exists()) {
              await archivoTemporal.delete();
            }
          }
          
          final int tamanoComprimido = bytesComprimidos.length;
          final double porcentajeReduccion = 100 - (tamanoComprimido / tamanoOriginal * 100);
          
          AppLogger.info(
            'Compresión completada. Tamaño comprimido: ${(tamanoComprimido / 1024 / 1024).toStringAsFixed(2)} MB '
            '(reducción del ${porcentajeReduccion.toStringAsFixed(1)}%)',
            name: 'StorageService'
          );
          
          // Usar la versión comprimida SOLO si es más pequeña que la original
          if (tamanoComprimido < tamanoOriginal) {
            bytesImagen = bytesComprimidos;
            AppLogger.info('Usando imagen comprimida para la subida', name: 'StorageService');
          } else {
            bytesImagen = bytesOriginales;
            usoImagenOriginal = true;
            AppLogger.info(
              'La imagen comprimida es más grande que la original. Usando imagen original para la subida', 
              name: 'StorageService'
            );
          }
        } catch (e) {
          AppLogger.error('Error durante la compresión, usando imagen original', name: 'StorageService', error: e);
          bytesImagen = bytesOriginales;
          usoImagenOriginal = true;
        }
      } else {
        // No comprimir
        if (comprimir && tamanoOriginal <= 1024 * 50) {
          AppLogger.info('Imagen pequeña, no se requiere compresión', name: 'StorageService');
        } else if (!comprimir) {
          AppLogger.info('Compresión desactivada, subiendo imagen original', name: 'StorageService');
        }
        
        bytesImagen = bytesOriginales;
        usoImagenOriginal = true;
      }
      
      // Configurar metadatos para especificar el tipo de contenido
      final metadata = firebase_storage.SettableMetadata(
        contentType: 'image/$formato',
        customMetadata: {
          'picked-file-path': imageFile.name,
          'compressed': (!usoImagenOriginal).toString(),
        },
      );
      
      // Iniciar la subida
      AppLogger.info('Iniciando subida de imagen (${(bytesImagen.length / 1024 / 1024).toStringAsFixed(2)} MB)...', 
          name: 'StorageService');
      uploadTask = ref.putData(bytesImagen, metadata);
      
      // Escuchar progreso de subida con tiempo estimado
      final startTime = DateTime.now();
      int lastReportedProgress = 0;
      
      uploadTask.snapshotEvents.listen((firebase_storage.TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        final int progressPercentage = (progress * 100).round();
        
        // Notificar al callback de progreso para la barra de progreso UI
        if (onProgress != null) {
          onProgress(progress);
        }
        
        // Solo reportar cuando el progreso cambie significativamente (cada 10%)
        if (progressPercentage % 10 == 0 && progressPercentage != lastReportedProgress) {
          lastReportedProgress = progressPercentage;
          
          // Calcular tiempo transcurrido y estimar tiempo restante
          final timeElapsed = DateTime.now().difference(startTime);
          String timeInfo = '';
          
          if (progress > 0 && snapshot.totalBytes > 0) { // Asegurarse que totalBytes no sea cero
            final totalEstimatedTime = Duration(milliseconds: (timeElapsed.inMilliseconds / progress).round());
            final remainingTime = totalEstimatedTime - timeElapsed;
            
            timeInfo = ', Tiempo restante estimado: ${remainingTime.inSeconds} segundos';
          }
          
          AppLogger.info(
            'Progreso de subida: ${progressPercentage}% - Estado: ${snapshot.state.name}$timeInfo',
            name: 'StorageService'
          );
        }
      }, onError: (error, stackTrace) {
        // Manejar errores que ocurran durante el stream de eventos de la subida
        AppLogger.error(
          'Error durante el stream de eventos de subida (listen.onError)', 
          name: 'StorageService', 
          error: error, 
          stackTrace: stackTrace
        );
        // No se retorna nada aquí, el error debería propagarse al await de uploadTask
      });
      
      // Espera a que la subida se complete
      AppLogger.info('Esperando a que se complete la subida (await uploadTask)...', name: 'StorageService');
      
      firebase_storage.TaskSnapshot snapshot;
      try {
        // Aplicar un timeout a la operación de subida
        // Para una imagen de ~3MB, 2 minutos deberían ser más que suficientes.
        // Aumentar si se suben archivos mucho más grandes o con conexiones lentas.
        snapshot = await uploadTask.timeout(const Duration(minutes: 2), onTimeout: () {
          AppLogger.error(
            'Timeout: La subida de la imagen excedió los 2 minutos.',
            name: 'StorageService'
          );
          // Forzar la cancelación de la tarea en caso de timeout si es posible
          // y si la tarea no se ha completado/fallado por sí misma.
          if (uploadTask.snapshot.state == firebase_storage.TaskState.running || 
              uploadTask.snapshot.state == firebase_storage.TaskState.paused) {
            uploadTask.cancel(); 
          }
          throw firebase_storage.FirebaseException(
              plugin: 'firebase_storage', 
              code: 'upload-timeout', 
              message: 'La subida de la imagen excedió el tiempo límite.');
        });
        
        AppLogger.info('Subida (await uploadTask) completada. Estado final: ${snapshot.state.name}', name: 'StorageService');
      } catch (e, s) {
        // Capturar errores de la subida (incluyendo el timeout)
        AppLogger.error(
          'Error durante o después de await uploadTask (incluyendo posible timeout)', 
          name: 'StorageService', 
          error: e, 
          stackTrace: s
        );
        return null; // Indicar que la subida falló
      }

      if (snapshot.state == firebase_storage.TaskState.error || snapshot.state == firebase_storage.TaskState.canceled) {
        AppLogger.error(
          'La subida falló o fue cancelada. Estado: ${snapshot.state.name}', 
          name: 'StorageService', 
          error: snapshot.storage.bucket // Puede contener información adicional o una referencia al error
        );
        // Intentar obtener el error de la tarea si está disponible (puede no estarlo siempre)
        // Esto es más una medida de depuración
        try {
          await snapshot.ref.getDownloadURL(); // Esto fallará y podría dar más detalles del error
        } catch (e, s) {
          AppLogger.error(
            'Error al intentar obtener URL de descarga después de fallo/cancelación (diagnóstico)', 
            name: 'StorageService', 
            error: e, 
            stackTrace: s
          );
        }
        return null; // Indicar que la subida falló
      }

      if (snapshot.state == firebase_storage.TaskState.success) {
        // Obtiene la URL de descarga
        AppLogger.info('Subida exitosa. Obteniendo URL de descarga...', name: 'StorageService');
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        AppLogger.info(
          'URL de descarga obtenida exitosamente. Tiempo total de subida: ${duration.inSeconds} segundos', 
          name: 'StorageService'
        );
        
        return downloadUrl;
      } else {
        // Otros estados inesperados
        AppLogger.warning('Estado inesperado de la tarea de subida: ${snapshot.state.name}', name: 'StorageService');
        return null;
      }
    } catch (e, s) {
      AppLogger.error(
        'Error al subir la imagen a ${path}', 
        name: 'StorageService', 
        error: e, 
        stackTrace: s
      );
      return null;
    }
  }

  /// Determina el formato de compresión adecuado a partir de la extensión del archivo
  CompressFormat _obtenerFormato(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return CompressFormat.png;
      case 'webp':
        return CompressFormat.webp;
      case 'heic':
        return CompressFormat.heic;
      case 'jpg':
      case 'jpeg':
      default:
        return CompressFormat.jpeg;
    }
  }

  /// Elimina una imagen de Firebase Storage.
  /// 
  /// [imageUrl]: La URL de descarga de la imagen a eliminar.
  Future<void> deleteImage(String imageUrl) async {
    AppLogger.info('Intentando eliminar imagen: $imageUrl', name: 'StorageService');
    
    try {
      final firebase_storage.Reference ref = _storage.refFromURL(imageUrl);
      AppLogger.info('Referencia de imagen a eliminar: ${ref.fullPath}', name: 'StorageService');
      
      await ref.delete();
      AppLogger.info('Imagen eliminada exitosamente', name: 'StorageService');
    } catch (e, s) {
      AppLogger.error(
        'Error al eliminar la imagen $imageUrl', 
        name: 'StorageService', 
        error: e, 
        stackTrace: s
      );
      // Considera manejar este error de forma más robusta si es necesario
    }
  }
} 