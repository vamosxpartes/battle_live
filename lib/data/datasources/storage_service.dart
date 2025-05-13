import 'dart:io';
import 'dart:typed_data'; // Necesario para Uint8List
import 'package:battle_live/core/logging/app_logger.dart'; // Importar AppLogger
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Necesario para kIsWeb

class StorageService {
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  /// Sube una imagen a Firebase Storage y devuelve la URL de descarga.
  /// 
  /// [imageFile]: El archivo de imagen a subir (obtenido de image_picker).
  /// [path]: La ruta en Firebase Storage donde se guardará la imagen 
  ///         (ej: 'esqueletos_live/imagenes_fondo/nombre_del_archivo.jpg').
  Future<String?> uploadImage(XFile imageFile, String path) async {
    AppLogger.info('Iniciando subida de imagen a Firebase Storage: $path', name: 'StorageService');
    
    try {
      final firebase_storage.Reference ref = _storage.ref().child(path);
      AppLogger.info('Referencia de storage creada: ${ref.fullPath}', name: 'StorageService');
      
      firebase_storage.UploadTask uploadTask;

      if (kIsWeb) {
        // Web: usa putData con los bytes de la imagen
        AppLogger.info('Subiendo desde plataforma web, convirtiendo a bytes', name: 'StorageService');
        final Uint8List bytes = await imageFile.readAsBytes();
        AppLogger.info('Imagen leída como bytes: ${bytes.length} bytes', name: 'StorageService');
        uploadTask = ref.putData(bytes);
      } else {
        // Móvil/Escritorio: usa putFile con el path del archivo
        AppLogger.info('Subiendo desde móvil/escritorio, usando archivo: ${imageFile.path}', name: 'StorageService');
        final File file = File(imageFile.path);
        uploadTask = ref.putFile(file);
      }
      
      // Escuchar progreso de subida
      uploadTask.snapshotEvents.listen((firebase_storage.TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        AppLogger.info(
          'Progreso de subida: ${(progress * 100).toStringAsFixed(2)}% - Estado: ${snapshot.state.name}',
          name: 'StorageService'
        );
      });
      
      // Espera a que la subida se complete
      AppLogger.info('Esperando a que se complete la subida...', name: 'StorageService');
      final firebase_storage.TaskSnapshot snapshot = await uploadTask;
      
      // Obtiene la URL de descarga
      AppLogger.info('Subida completada. Obteniendo URL de descarga...', name: 'StorageService');
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      AppLogger.info('URL de descarga obtenida exitosamente', name: 'StorageService');
      return downloadUrl;
    } catch (e, s) { // Añadir StackTrace s
      AppLogger.error(
        'Error al subir la imagen a ${path}', 
        name: 'StorageService', 
        error: e, 
        stackTrace: s
      );
      return null;
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
    } catch (e, s) { // Añadir StackTrace s
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