import 'package:battle_live/models/donacion_model.dart';
import 'package:battle_live/services/tiktok_live_client.dart';
import 'package:battle_live/core/logging/app_logger.dart';
import 'package:battle_live/services/tiktok_gift_classifier.dart';

/// Servicio adaptador para integrar TikTokLiveClient con la aplicación
class TikTokService {
  // Cliente TikTok Live - accesible públicamente para eventos específicos
  final TikTokLiveClient client;
  
  // Clasificador de regalos TikTok
  final TikTokGiftClassifier _giftClassifier = TikTokGiftClassifier();
  
  // Stream controllers para eventos procesados
  final List<Function(Donacion)> _onDonacionListeners = [];
  
  // Estado 
  bool _isConnected = false;
  String _currentUsername = '';
  String _errorMessage = '';
  
  // Contadores de puntos por contendiente
  int _puntosContendiente1 = 0;
  int _puntosContendiente2 = 0;
  
  // Getters
  bool get isConnected => _isConnected;
  String get currentUsername => _currentUsername;
  String get errorMessage => _errorMessage;
  int get puntosContendiente1 => _puntosContendiente1;
  int get puntosContendiente2 => _puntosContendiente2;
  
  // Constructor
  TikTokService({required String serverUrl}) 
    : client = TikTokLiveClient(serverUrl: serverUrl) {
    AppLogger.info('Creando TikTokService con URL: $serverUrl', name: 'TikTokService');
    _initializeClient();
  }
  
  // Inicializar el cliente y configurar los listeners
  void _initializeClient() {
    AppLogger.info('Inicializando TikTok Live Client', name: 'TikTokService');
    client.initialize();
    
    // Escuchar eventos de conexión
    client.connectionStateStream.listen((event) {
      _isConnected = event.isConnected;
      _currentUsername = event.username;
      
      // Reiniciar contadores al conectar/desconectar
      if (!_isConnected) {
        _puntosContendiente1 = 0;
        _puntosContendiente2 = 0;
        AppLogger.info('Contadores reiniciados por desconexión', name: 'TikTokService');
      }
      
      AppLogger.info(
        'Estado de conexión actualizado: ${event.isConnected ? 'Conectado' : 'Desconectado'} a @${event.username}',
        name: 'TikTokService'
      );
    });
    
    // Escuchar errores
    client.errorStream.listen((event) {
      _errorMessage = event.message;
      AppLogger.error(
        'Error recibido del cliente TikTok', 
        name: 'TikTokService',
        error: event.message,
        stackTrace: event.originalError is StackTrace ? event.originalError : null
      );
    });
    
    // Convertir regalos/donaciones de TikTok a nuestro modelo
    client.giftStream.listen((gift) {
      AppLogger.info(
        'Regalo recibido: ${gift.username} envió ${gift.giftName} (${gift.diamondCount} diamantes)',
        name: 'TikTokService'
      );
      
      // VERIFICAR FORMATO DE DATOS DEL REGALO
      AppLogger.info(
        'Datos completos del regalo - nombre: "${gift.giftName}", diamantes: ${gift.diamondCount}, repeticiones: ${gift.repeatCount}',
        name: 'TikTokGiftDebug'
      );
      
      // No procesar regalos vacíos o inválidos
      if (gift.giftName.isEmpty || gift.giftName == "Regalo" && gift.diamondCount == 0) {
        AppLogger.warning(
          'Ignorando regalo con datos incompletos: ${gift.giftName} (${gift.diamondCount})',
          name: 'TikTokGiftDebug'
        );
        return;
      }
      
      // Usar el clasificador para procesar el regalo
      final infoRegalo = _giftClassifier.procesarRegalo(gift.giftName, gift.diamondCount);
      
      AppLogger.info(
        'Regalo clasificado - grupo: ${infoRegalo['grupo']}, valor: ${infoRegalo['valor']}, contendiente: ${infoRegalo['contendienteId']}',
        name: 'TikTokGiftDebug'
      );
      
      // Si el valor está en 0 pero los diamantes están disponibles, usar los diamantes
      final valorFinal = infoRegalo['valor'] == 0 && gift.diamondCount > 0 
          ? gift.diamondCount 
          : infoRegalo['valor'];
          
      // Multiplicar por el número de repeticiones si es mayor que 1
      final valorTotal = valorFinal * (gift.repeatCount > 1 ? gift.repeatCount : 1);
      
      // Crear una donación a partir del regalo clasificado
      final donacion = Donacion(
        usuario: gift.username,
        cantidad: valorTotal,
        contendienteId: infoRegalo['contendienteId'],
        plataforma: 'TikTok',
      );
      
      // Actualizar contadores de puntos
      _actualizarPuntos(donacion.contendienteId, donacion.cantidad);
      
      AppLogger.info(
        'Contadores actualizados - Contendiente 1: $_puntosContendiente1, Contendiente 2: $_puntosContendiente2',
        name: 'TikTokGiftDebug'
      );
      
      // Notificar a los listeners
      for (var listener in _onDonacionListeners) {
        listener(donacion);
      }
      
      AppLogger.info(
        'Regalo procesado: ${gift.giftName} (${gift.diamondCount} diamantes) asignado al Grupo ${infoRegalo['grupo']} con valor final $valorTotal para contendiente ${infoRegalo['contendienteId']}',
        name: 'TikTokService'
      );
    });
    
    // También podríamos convertir mensajes de chat en donaciones si contienen ciertas palabras clave
    client.chatStream.listen((chat) {
      // Ejemplo: Si el mensaje contiene "azul" o "rojo", lo consideramos como apoyo
      final mensaje = chat.message.toLowerCase();
      int? contendienteId;
      
      if (mensaje.contains('azul')) {
        contendienteId = 1;
      } else if (mensaje.contains('rojo')) {
        contendienteId = 2;
      }
      
      // Si se identificó un contendiente, crear una donación simbólica
      if (contendienteId != null) {
        AppLogger.info(
          'Mensaje de apoyo recibido: ${chat.username} apoya al equipo $contendienteId',
          name: 'TikTokService'
        );
        
        final donacion = Donacion(
          usuario: chat.username,
          cantidad: 1, // Valor simbólico por mensaje
          contendienteId: contendienteId,
          plataforma: 'TikTok Chat',
        );
        
        // Actualizar contadores de puntos
        _actualizarPuntos(donacion.contendienteId, donacion.cantidad);
        
        // Notificar a los listeners
        for (var listener in _onDonacionListeners) {
          listener(donacion);
        }
      }
    });
  }
  
  // Actualizar contadores de puntos
  void _actualizarPuntos(int contendienteId, int cantidad) {
    AppLogger.info(
      'Actualizando puntos - Contendiente: $contendienteId, Cantidad: $cantidad',
      name: 'TikTokGiftDebug'
    );
    
    if (contendienteId == 1) {
      _puntosContendiente1 += cantidad;
      AppLogger.info('Contendiente 1 ahora tiene $_puntosContendiente1 puntos', name: 'TikTokGiftDebug');
    } else if (contendienteId == 2) {
      _puntosContendiente2 += cantidad;
      AppLogger.info('Contendiente 2 ahora tiene $_puntosContendiente2 puntos', name: 'TikTokGiftDebug');
    } else {
      AppLogger.warning('ID de contendiente inválido: $contendienteId', name: 'TikTokGiftDebug');
    }
  }
  
  // Reiniciar contadores de puntos
  void reiniciarPuntos() {
    _puntosContendiente1 = 0;
    _puntosContendiente2 = 0;
    AppLogger.info(
      'Contadores reiniciados manualmente - Contendiente 1: $_puntosContendiente1, Contendiente 2: $_puntosContendiente2',
      name: 'TikTokGiftDebug'
    );
  }
  
  // Añadir puntos manualmente
  void anadirPuntos(int contendienteId, int cantidad) {
    AppLogger.info(
      'Añadiendo puntos manualmente - Contendiente: $contendienteId, Cantidad: $cantidad',
      name: 'TikTokGiftDebug'
    );
    
    _actualizarPuntos(contendienteId, cantidad);
  }
  
  // Conectar a un usuario de TikTok
  Future<bool> conectarUsuario(String username) async {
    AppLogger.info('Solicitando conexión a usuario TikTok: @$username', name: 'TikTokService');
    final result = await client.connectToUser(username);
    AppLogger.info(
      'Resultado de conexión a @$username: ${result ? 'Éxito' : 'Fallo'}',
      name: 'TikTokService'
    );
    return result;
  }
  
  // Desconectar
  void desconectar() {
    AppLogger.info('Desconectando TikTokService', name: 'TikTokService');
    client.disconnect();
  }
  
  // Añadir listener para donaciones
  void addDonacionListener(Function(Donacion) listener) {
    _onDonacionListeners.add(listener);
  }
  
  // Remover listener
  void removeDonacionListener(Function(Donacion) listener) {
    _onDonacionListeners.remove(listener);
  }
  
  // Liberar recursos
  void dispose() {
    AppLogger.info('Liberando recursos de TikTokService', name: 'TikTokService');
    client.dispose();
    _onDonacionListeners.clear();
  }
} 