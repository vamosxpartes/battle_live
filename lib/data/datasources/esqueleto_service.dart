import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:battle_live/core/logging/app_logger.dart';

class EsqueletoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _esqueletosCollection;

  EsqueletoService() : _esqueletosCollection = FirebaseFirestore.instance.collection('esqueletos_live');

  /// Guarda un nuevo esqueleto en Firestore
  /// 
  /// Retorna el ID del documento creado si se guarda correctamente, o null si hay un error
  Future<String?> guardarEsqueleto({
    required String titulo,
    required String contendiente1,
    required String contendiente2,
    required String imagenUrl,
  }) async {
    AppLogger.info('Intentando guardar nuevo esqueleto: "$titulo"', name: 'EsqueletoService');
    
    try {
      AppLogger.info('Validando parámetros de entrada...', name: 'EsqueletoService');
      if (titulo.isEmpty || contendiente1.isEmpty || contendiente2.isEmpty || imagenUrl.isEmpty) {
        AppLogger.warning('Datos inválidos para guardar esqueleto: algún campo está vacío', name: 'EsqueletoService');
        return null;
      }
      
      final Map<String, dynamic> esqueletoData = {
        'titulo': titulo,
        'contendiente1': contendiente1,
        'contendiente2': contendiente2,
        'imagenUrl': imagenUrl,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'activo': false,
      };

      AppLogger.info('Datos del esqueleto a guardar: $esqueletoData', name: 'EsqueletoService');
      
      // Guardar documento en Firestore
      AppLogger.info('Iniciando operación add() en Firestore...', name: 'EsqueletoService');
      AppLogger.info('Colección objetivo: ${_esqueletosCollection.path}', name: 'EsqueletoService');
      
      DocumentReference? docRef;
      try {
        AppLogger.info('Ejecutando add() en Firestore...', name: 'EsqueletoService');
        docRef = await _esqueletosCollection.add(esqueletoData);
        AppLogger.info('Operación add() completada, obteniendo ID...', name: 'EsqueletoService');
      } catch (e, s) {
        AppLogger.error('Error específico durante la operación add() en Firestore', 
          name: 'EsqueletoService', 
          error: e,
          stackTrace: s
        );
        return null;
      }
      
      if (docRef == null) {
        AppLogger.error('Error: La referencia del documento es nula después de add()', name: 'EsqueletoService');
        return null;
      }
      
      final String esqueletoId = docRef.id;
      AppLogger.info('ID del documento obtenido: $esqueletoId', name: 'EsqueletoService');
      
      // Verificar que el documento fue creado correctamente
      try {
        AppLogger.info('Verificando que el documento existe en Firestore...', name: 'EsqueletoService');
        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          AppLogger.warning('El documento no existe después de crearlo', name: 'EsqueletoService');
        } else {
          AppLogger.info('Documento verificado y existe en Firestore', name: 'EsqueletoService');
        }
      } catch (e, s) {
        AppLogger.warning('Error al verificar documento: ${e.toString()}', name: 'EsqueletoService');
        // No retornamos aquí porque ya tenemos el ID y la operación principal ya se completó
      }
      
      AppLogger.info('Esqueleto guardado exitosamente con ID: $esqueletoId', name: 'EsqueletoService');
      return esqueletoId;
    } catch (e, s) {
      AppLogger.error(
        'Error al guardar esqueleto en Firestore: ${e.toString()}', 
        name: 'EsqueletoService',
        error: e,
        stackTrace: s
      );
      return null;
    }
  }

  /// Obtiene un esqueleto por su ID
  Future<Map<String, dynamic>?> obtenerEsqueleto(String esqueletoId) async {
    AppLogger.info('Obteniendo esqueleto con ID: $esqueletoId', name: 'EsqueletoService');
    
    try {
      final DocumentSnapshot doc = await _esqueletosCollection.doc(esqueletoId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        AppLogger.info('Esqueleto encontrado: ${data['titulo']}', name: 'EsqueletoService');
        return {
          'id': doc.id,
          ...data,
        };
      } else {
        AppLogger.warning('Esqueleto no encontrado: $esqueletoId', name: 'EsqueletoService');
        return null;
      }
    } catch (e, s) {
      AppLogger.error(
        'Error al obtener esqueleto $esqueletoId: ${e.toString()}', 
        name: 'EsqueletoService',
        error: e,
        stackTrace: s
      );
      return null;
    }
  }

  /// Obtiene todos los esqueletos disponibles
  Future<List<Map<String, dynamic>>> obtenerEsqueletos() async {
    AppLogger.info('Obteniendo lista de esqueletos', name: 'EsqueletoService');
    
    try {
      AppLogger.info('Ejecutando query para obtener esqueletos...', name: 'EsqueletoService');
      final QuerySnapshot querySnapshot = await _esqueletosCollection
          .orderBy('fechaCreacion', descending: true)
          .get();
      
      AppLogger.info('Query completada, procesando resultados...', name: 'EsqueletoService');
      final List<Map<String, dynamic>> esqueletos = querySnapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...(doc.data() as Map<String, dynamic>),
          })
          .toList();
      
      AppLogger.info('${esqueletos.length} esqueletos recuperados', name: 'EsqueletoService');
      return esqueletos;
    } catch (e, s) {
      AppLogger.error(
        'Error al obtener lista de esqueletos: ${e.toString()}', 
        name: 'EsqueletoService',
        error: e,
        stackTrace: s
      );
      return [];
    }
  }

  /// Actualiza un esqueleto existente
  Future<bool> actualizarEsqueleto({
    required String esqueletoId,
    String? titulo,
    String? contendiente1,
    String? contendiente2,
    String? imagenUrl,
    bool? activo,
  }) async {
    AppLogger.info('Actualizando esqueleto: $esqueletoId', name: 'EsqueletoService');
    
    try {
      final Map<String, dynamic> updateData = {};
      
      if (titulo != null) updateData['titulo'] = titulo;
      if (contendiente1 != null) updateData['contendiente1'] = contendiente1;
      if (contendiente2 != null) updateData['contendiente2'] = contendiente2;
      if (imagenUrl != null) updateData['imagenUrl'] = imagenUrl;
      if (activo != null) updateData['activo'] = activo;
      
      updateData['fechaActualizacion'] = FieldValue.serverTimestamp();
      
      AppLogger.info('Datos a actualizar: $updateData', name: 'EsqueletoService');
      
      AppLogger.info('Ejecutando operación update() en Firestore...', name: 'EsqueletoService');
      await _esqueletosCollection.doc(esqueletoId).update(updateData);
      
      AppLogger.info('Esqueleto actualizado exitosamente', name: 'EsqueletoService');
      return true;
    } catch (e, s) {
      AppLogger.error(
        'Error al actualizar esqueleto $esqueletoId: ${e.toString()}', 
        name: 'EsqueletoService',
        error: e,
        stackTrace: s
      );
      return false;
    }
  }

  /// Elimina un esqueleto
  Future<bool> eliminarEsqueleto(String esqueletoId) async {
    AppLogger.info('Eliminando esqueleto: $esqueletoId', name: 'EsqueletoService');
    
    try {
      AppLogger.info('Ejecutando operación delete() en Firestore...', name: 'EsqueletoService');
      await _esqueletosCollection.doc(esqueletoId).delete();
      
      AppLogger.info('Esqueleto eliminado exitosamente', name: 'EsqueletoService');
      return true;
    } catch (e, s) {
      AppLogger.error(
        'Error al eliminar esqueleto $esqueletoId: ${e.toString()}', 
        name: 'EsqueletoService',
        error: e,
        stackTrace: s
      );
      return false;
    }
  }
} 