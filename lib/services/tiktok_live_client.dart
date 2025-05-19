import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:battle_live/core/logging/app_logger.dart';

/// Eventos de chat recibidos del stream de TikTok
class ChatEvent {
  final String username;
  final String message;
  final String userId;
  final String avatarUrl;
  final Map<String, dynamic> rawData;

  ChatEvent({
    required this.username,
    required this.message,
    this.userId = '',
    this.avatarUrl = '',
    this.rawData = const {},
  });
}

/// Eventos de regalos recibidos del stream de TikTok
class GiftEvent {
  final String username;
  final String giftName;
  final int diamondCount;
  final int repeatCount;
  final String userId;
  final String avatarUrl;
  final Map<String, dynamic> rawData;

  GiftEvent({
    required this.username,
    required this.giftName,
    required this.diamondCount,
    this.repeatCount = 1,
    this.userId = '',
    this.avatarUrl = '',
    this.rawData = const {},
  });
}

/// Evento de estado de conexión
class ConnectionStateEvent {
  final bool isConnected;
  final String username;

  ConnectionStateEvent({required this.isConnected, this.username = ''});
}

/// Evento de conteo de espectadores
class ViewerCountEvent {
  final int count;
  ViewerCountEvent({required this.count});
}

/// Evento de me gusta
class LikeEvent {
  final String username;
  final int likeCount;
  final String userId;

  LikeEvent({
    required this.username,
    required this.likeCount,
    this.userId = '',
  });
}

/// Evento de error
class ErrorEvent {
  final String message;
  final dynamic originalError;

  ErrorEvent({required this.message, this.originalError});
}

/// Servicio para conectarse con el servidor TikTok Live
class TikTokLiveClient {
  // URL del servidor
  final String serverUrl;
  
  // Socket para la conexión
  IO.Socket? _socket;
  
  // Controladores de eventos
  final _chatController = StreamController<ChatEvent>.broadcast();
  final _giftController = StreamController<GiftEvent>.broadcast();
  final _connectionStateController = StreamController<ConnectionStateEvent>.broadcast();
  final _viewerCountController = StreamController<ViewerCountEvent>.broadcast();
  final _likeController = StreamController<LikeEvent>.broadcast();
  final _errorController = StreamController<ErrorEvent>.broadcast();
  
  // Estado actual de conexión
  bool _isConnected = false;
  String _currentUser = '';
  
  // Streams públicos para escuchar eventos
  Stream<ChatEvent> get chatStream => _chatController.stream;
  Stream<GiftEvent> get giftStream => _giftController.stream;
  Stream<ConnectionStateEvent> get connectionStateStream => _connectionStateController.stream;
  Stream<ViewerCountEvent> get viewerCountStream => _viewerCountController.stream;
  Stream<LikeEvent> get likeStream => _likeController.stream;
  Stream<ErrorEvent> get errorStream => _errorController.stream;
  
  // Constructor
  TikTokLiveClient({required this.serverUrl});
  
  // Inicializar la conexión
  void initialize() {
    try {
      AppLogger.info('Inicializando TikTokLiveClient con URL: $serverUrl', name: 'TikTokLiveClient');
      
      // Configurar el socket
      _socket = IO.io(
        serverUrl, 
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew()
            .build()
      );
      
      AppLogger.info('Socket IO creado correctamente', name: 'TikTokLiveClient');
      
      // Configurar manejadores de eventos
      _setupEventHandlers();
      
    } catch (e) {
      AppLogger.error('Error al inicializar el cliente TikTok', name: 'TikTokLiveClient', error: e);
      _errorController.add(ErrorEvent(
        message: 'Error al inicializar el cliente: $e',
        originalError: e
      ));
    }
  }
  
  // Configurar los manejadores de eventos del socket
  void _setupEventHandlers() {
    AppLogger.info('Configurando manejadores de eventos del socket', name: 'TikTokLiveClient');
    
    _socket?.onConnect((_) {
      AppLogger.info('Socket conectado exitosamente', name: 'TikTokLiveClient');
      _isConnected = true;
      _connectionStateController.add(ConnectionStateEvent(
        isConnected: true,
        username: _currentUser,
      ));
    });
    
    _socket?.onDisconnect((_) {
      AppLogger.warning('Socket desconectado', name: 'TikTokLiveClient');
      _isConnected = false;
      _connectionStateController.add(ConnectionStateEvent(
        isConnected: false,
        username: _currentUser,
      ));
    });
    
    _socket?.onConnectError((error) {
      AppLogger.error('Error de conexión del socket', name: 'TikTokLiveClient', error: error);
      _errorController.add(ErrorEvent(
        message: 'Error de conexión: $error',
        originalError: error,
      ));
    });
    
    _socket?.onError((error) {
      AppLogger.error('Error en el socket', name: 'TikTokLiveClient', error: error);
      _errorController.add(ErrorEvent(
        message: 'Error en el socket: $error',
        originalError: error,
      ));
    });
    
    // Eventos específicos de TikTok Live
    _socket?.on('chat', (data) {
      try {
        _chatController.add(ChatEvent(
          username: data['username'] ?? 'Usuario',
          message: data['message'] ?? '',
          userId: data['userId'] ?? '',
          avatarUrl: data['avatarUrl'] ?? '',
          rawData: data,
        ));
      } catch (e) {
        _errorController.add(ErrorEvent(
          message: 'Error al procesar mensaje de chat: $e',
          originalError: e,
        ));
      }
    });
    
    _socket?.on('gift', (data) {
      try {
        // Imprimir datos completos para debugging
        AppLogger.info(
          'Datos completos del regalo recibido: ${data.toString()}',
          name: 'TikTokGiftDebug'
        );
        
        // Verificar la estructura del objeto gift
        final giftData = data['gift'] as Map<String, dynamic>?;
        
        if (giftData == null) {
          AppLogger.warning('Evento gift recibido sin objeto gift: $data', name: 'TikTokGiftDebug');
        }
        
        // Extraer nombre y valor del regalo de la estructura correcta
        final giftName = giftData?['name'] ?? data['giftName'] ?? 'Regalo';
        final diamondCount = giftData?['diamondCount'] ?? data['diamondCount'] ?? 0;
        final repeatCount = giftData?['repeatCount'] ?? data['repeatCount'] ?? 1;
        
        // Extraer información del usuario
        final user = data['user'] as Map<String, dynamic>?;
        final username = user?['nickname'] ?? data['username'] ?? 'Usuario';
        final userId = user?['userId'] ?? data['userId'] ?? '';
        
        // Procesar avatarUrl/profilePictureUrl que puede ser un objeto complejo
        String avatarUrl = '';
        final profilePicData = user?['profilePictureUrl'];
        
        if (profilePicData is String) {
          // Formato antiguo: directamente una URL
          avatarUrl = profilePicData;
        } else if (profilePicData is Map<String, dynamic> && profilePicData.containsKey('urls')) {
          // Nuevo formato: objeto con array de URLs
          final urls = profilePicData['urls'];
          if (urls is List && urls.isNotEmpty) {
            avatarUrl = urls[0].toString();
          }
        }
        
        AppLogger.info(
          'Regalo procesado: Usuario=$username, Regalo=$giftName, Diamantes=$diamondCount, Repeticiones=$repeatCount',
          name: 'TikTokGiftDebug'
        );
        
        _giftController.add(GiftEvent(
          username: username,
          giftName: giftName,
          diamondCount: diamondCount,
          repeatCount: repeatCount,
          userId: userId,
          avatarUrl: avatarUrl,
          rawData: data,
        ));
      } catch (e) {
        AppLogger.error('Error al procesar regalo', name: 'TikTokGiftDebug', error: e);
        _errorController.add(ErrorEvent(
          message: 'Error al procesar regalo: $e',
          originalError: e,
        ));
      }
    });
    
    _socket?.on('viewerCount', (data) {
      try {
        _viewerCountController.add(ViewerCountEvent(
          count: data['count'] ?? 0,
        ));
      } catch (e) {
        _errorController.add(ErrorEvent(
          message: 'Error al procesar conteo de espectadores: $e',
          originalError: e,
        ));
      }
    });
    
    _socket?.on('like', (data) {
      try {
        AppLogger.info('Evento like recibido en TikTokLiveClient: $data', name: 'WebSocketEventContent');
        AppLogger.info('Datos crudos del evento like: ${data.toString()}', name: 'WebSocketRawData');
        _likeController.add(LikeEvent(
          username: data['username'] ?? 'Usuario',
          likeCount: data['likeCount'] ?? 1,
          userId: data['userId'] ?? '',
        ));
      } catch (e) {
        _errorController.add(ErrorEvent(
          message: 'Error al procesar me gusta: $e',
          originalError: e,
        ));
      }
    });
    
    _socket?.on('error', (data) {
      _errorController.add(ErrorEvent(
        message: data['message'] ?? 'Error desconocido del servidor',
        originalError: data,
      ));
    });
    
    // Capturar todos los eventos para logging
    _socket?.onAny((event, data) {
      AppLogger.info('TikTok evento genérico: $event', name: 'WebSocketEventContent');
      AppLogger.info('TikTok datos crudos: ${data?.toString() ?? "sin datos"}', name: 'WebSocketRawData');
    });
  }
  
  // Conectar a un usuario de TikTok
  Future<bool> connectToUser(String username) async {
    AppLogger.info('Intentando conectar a usuario: @$username', name: 'TikTokLiveClient');
    
    if (_socket == null) {
      AppLogger.error('Socket no inicializado', name: 'TikTokLiveClient');
      _errorController.add(ErrorEvent(
        message: 'Socket no inicializado. Llama a initialize() primero.',
      ));
      return false;
    }
    
    // Guardar usuario actual
    _currentUser = username;
    
    // Desconectar si ya estaba conectado
    if (_isConnected) {
      AppLogger.info('Desconectando sesión anterior antes de conectar', name: 'TikTokLiveClient');
      _socket?.disconnect();
    }
    
    // Conectar al servidor
    AppLogger.info('Iniciando conexión al servidor: $serverUrl', name: 'TikTokLiveClient');
    _socket?.connect();
    
    // Enviar solicitud para conectar a un usuario específico
    AppLogger.info('Enviando solicitud connectToUser para @$username', name: 'TikTokLiveClient');
    _socket?.emitWithAck('connectToUser', {'username': username}, ack: (data) {
      AppLogger.info('Respuesta recibida para connectToUser: $data', name: 'TikTokLiveClient');
      if (data != null && data['success'] == true) {
        return true;
      } else {
        AppLogger.error(
          'Error en respuesta de connectToUser', 
          name: 'TikTokLiveClient', 
          error: data != null ? data['message'] : 'No data received'
        );
        _errorController.add(ErrorEvent(
          message: 'Error al conectar a @$username: ${data?['message'] ?? 'Error desconocido'}',
          originalError: data,
        ));
        return false;
      }
    });
    
    // Retornar true para simular conexión exitosa
    // En una implementación real, deberías esperar la respuesta del servidor
    AppLogger.info('Retornando resultado de conexión para @$username', name: 'TikTokLiveClient');
    return true;
  }
  
  // Desconectar del usuario actual
  void disconnect() {
    AppLogger.info('Desconectando del servidor', name: 'TikTokLiveClient');
    _socket?.disconnect();
  }
  
  // Liberar recursos
  void dispose() {
    AppLogger.info('Liberando recursos de TikTokLiveClient', name: 'TikTokLiveClient');
    disconnect();
    
    _chatController.close();
    _giftController.close();
    _connectionStateController.close();
    _viewerCountController.close();
    _likeController.close();
    _errorController.close();
    
    _socket?.dispose();
  }
} 