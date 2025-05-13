import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:battle_live/core/logging/app_logger.dart';

/// Eventos de chat recibidos del stream de TikTok
class ChatEvent {
  final String username;
  final String message;
  final String userId;
  final String avatarUrl;
  final String timestamp;
  final String formattedTime;
  final bool isSubscriber;
  final bool isModerator;
  final List<dynamic> badges; 
  final Map<String, dynamic> rawData;

  ChatEvent({
    required this.username,
    required this.message,
    this.userId = '',
    this.avatarUrl = '',
    this.timestamp = '',
    this.formattedTime = '',
    this.isSubscriber = false,
    this.isModerator = false,
    this.badges = const [],
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
  final String timestamp;
  final String formattedTime;
  final int giftId;
  final int totalValue;
  final String giftImageUrl;
  final Map<String, dynamic> rawData;

  GiftEvent({
    required this.username,
    required this.giftName,
    required this.diamondCount,
    this.repeatCount = 1,
    this.userId = '',
    this.avatarUrl = '',
    this.timestamp = '',
    this.formattedTime = '',
    this.giftId = 0,
    this.totalValue = 0,
    this.giftImageUrl = '',
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
      // Configurar el socket
      _socket = IO.io(
        serverUrl, 
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew()
            .build()
      );
      
      // Configurar manejadores de eventos
      _setupEventHandlers();
      
    } catch (e) {
      _errorController.add(ErrorEvent(
        message: 'Error al inicializar el cliente: $e',
        originalError: e
      ));
    }
  }
  
  // Configurar los manejadores de eventos del socket
  void _setupEventHandlers() {
    _socket?.onConnect((_) {
      _isConnected = true;
      _connectionStateController.add(ConnectionStateEvent(
        isConnected: true,
        username: _currentUser,
      ));
    });
    
    _socket?.onDisconnect((_) {
      _isConnected = false;
      _connectionStateController.add(ConnectionStateEvent(
        isConnected: false,
        username: _currentUser,
      ));
    });
    
    _socket?.onConnectError((error) {
      _errorController.add(ErrorEvent(
        message: 'Error de conexión: $error',
        originalError: error,
      ));
    });
    
    _socket?.onError((error) {
      _errorController.add(ErrorEvent(
        message: 'Error en el socket: $error',
        originalError: error,
      ));
    });
    
    // Eventos específicos de TikTok Live
    _socket?.on('chat', (data) {
      try {
        AppLogger.info('Evento chat recibido en TikTokLiveClient: $data', name: 'WebSocketEventContent');
        
        // Extraer datos del usuario para el avatar
        String avatarUrl = '';
        if (data['userDetails'] != null && 
            data['userDetails']['profilePicture'] != null && 
            data['userDetails']['profilePicture']['urls'] != null) {
          final urls = data['userDetails']['profilePicture']['urls'];
          if (urls is List && urls.isNotEmpty) {
            avatarUrl = urls[0].toString();
          }
        }
        
        // Extraer badges
        List<dynamic> badges = [];
        if (data['userDetails'] != null && data['userDetails']['badges'] != null) {
          badges = data['userDetails']['badges'];
        }
        
        _chatController.add(ChatEvent(
          username: data['userDetails']?['nickname'] ?? data['user']?['nickname'] ?? 'Usuario',
          message: data['comment'] ?? '',
          userId: data['userDetails']?['userId']?.toString() ?? data['user']?['userId']?.toString() ?? '',
          avatarUrl: avatarUrl,
          timestamp: data['timestamp']?.toString() ?? '',
          formattedTime: data['formattedTimestamp'] ?? '',
          isSubscriber: data['isSubscriber'] == true,
          isModerator: data['isModerator'] == true,
          badges: badges,
          rawData: data,
        ));
      } catch (e) {
        AppLogger.error('Error al procesar mensaje de chat: $e', name: 'TikTokLiveClient', error: e);
        _errorController.add(ErrorEvent(
          message: 'Error al procesar mensaje de chat: $e',
          originalError: e,
        ));
      }
    });
    
    _socket?.on('gift', (data) {
      try {
        AppLogger.info('Evento gift recibido en TikTokLiveClient: $data', name: 'WebSocketEventContent');
        
        // Obtener la URL de la imagen del regalo
        String giftImageUrl = '';
        if (data['rawGiftData'] != null && 
            data['rawGiftData']['giftDetails'] != null && 
            data['rawGiftData']['giftDetails']['giftImage'] != null) {
          giftImageUrl = data['rawGiftData']['giftDetails']['giftImage']['giftPictureUrl'] ?? '';
        }
        
        _giftController.add(GiftEvent(
          username: data['user']?['nickname'] ?? 'Usuario',
          giftName: data['gift']?['name'] ?? '',
          diamondCount: data['gift']?['diamondCount'] ?? 0,
          repeatCount: data['gift']?['repeatCount'] ?? 1,
          userId: data['user']?['userId']?.toString() ?? '',
          avatarUrl: data['user']?['profilePictureUrl'] ?? '',
          timestamp: data['timestamp']?.toString() ?? '',
          formattedTime: data['formattedTimestamp'] ?? '',
          giftId: data['gift']?['id'] ?? 0,
          totalValue: data['totalValue'] ?? 0,
          giftImageUrl: giftImageUrl,
          rawData: data,
        ));
      } catch (e) {
        AppLogger.error('Error al procesar regalo: $e', name: 'TikTokLiveClient', error: e);
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
  }
  
  // Conectar a un usuario de TikTok
  Future<bool> connectToUser(String username) async {
    if (_socket == null) {
      _errorController.add(ErrorEvent(
        message: 'Socket no inicializado. Llama a initialize() primero.',
      ));
      return false;
    }
    
    // Guardar usuario actual
    _currentUser = username;
    
    // Desconectar si ya estaba conectado
    if (_isConnected) {
      _socket?.disconnect();
    }
    
    // Conectar al servidor
    _socket?.connect();
    
    // Enviar solicitud para conectar a un usuario específico
    _socket?.emitWithAck('connectToUser', {'username': username}, ack: (data) {
      if (data != null && data['success'] == true) {
        return true;
      } else {
        _errorController.add(ErrorEvent(
          message: 'Error al conectar a @$username: ${data?['message'] ?? 'Error desconocido'}',
          originalError: data,
        ));
        return false;
      }
    });
    
    // Retornar true para simular conexión exitosa
    // En una implementación real, deberías esperar la respuesta del servidor
    return true;
  }
  
  // Desconectar del usuario actual
  void disconnect() {
    _socket?.disconnect();
  }
  
  // Liberar recursos
  void dispose() {
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