import 'package:battle_live/models/donacion_model.dart';
import 'package:battle_live/services/tiktok_live_client.dart';
import 'package:battle_live/core/logging/app_logger.dart';

/// Servicio adaptador para integrar TikTokLiveClient con la aplicación
class TikTokService {
  // Cliente TikTok Live - accesible públicamente para eventos específicos
  final TikTokLiveClient client;
  
  // Stream controllers para eventos procesados
  final List<Function(Donacion)> _onDonacionListeners = [];
  
  // Estado 
  bool _isConnected = false;
  String _currentUsername = '';
  String _errorMessage = '';
  
  // Getters
  bool get isConnected => _isConnected;
  String get currentUsername => _currentUsername;
  String get errorMessage => _errorMessage;
  
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
      
      // Crear una donación a partir del regalo
      final donacion = Donacion(
        usuario: gift.username,
        cantidad: gift.diamondCount,
        // Asumimos que contendiente 1 = azul, 2 = rojo
        // Aquí podríamos hacer una lógica para determinar el contendiente
        contendienteId: _determinarContendiente(gift.username),
        plataforma: 'TikTok',
      );
      
      // Notificar a los listeners
      for (var listener in _onDonacionListeners) {
        listener(donacion);
      }
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
        
        // Notificar a los listeners
        for (var listener in _onDonacionListeners) {
          listener(donacion);
        }
      }
    });
  }
  
  // Determinar a qué contendiente apoya el usuario
  // Esta es una lógica simple de ejemplo, se puede personalizar
  int _determinarContendiente(String username) {
    // Ejemplo: Basado en la primera letra del nombre
    final firstChar = username.toLowerCase().codeUnitAt(0);
    return firstChar % 2 == 0 ? 1 : 2; // Par -> Equipo 1, Impar -> Equipo 2
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