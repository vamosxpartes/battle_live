import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Eventos soportados por el servidor
enum SocketEvent {
  connect,
  disconnect,
  error,
  donacion,
  updateContador,
  liveActivado,
  liveDesactivado,
}

/// Servicio para manejar conexiones de socket con el servidor Node.js
class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Socket instance
  IO.Socket? _socket;
  
  // Stream controllers para cada tipo de evento
  final _connectController = StreamController<bool>.broadcast();
  final _donacionController = StreamController<Map<String, dynamic>>.broadcast();
  final _contadorUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _liveStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  // Getters para los streams
  Stream<bool> get onConnect => _connectController.stream;
  Stream<Map<String, dynamic>> get onDonacion => _donacionController.stream;
  Stream<Map<String, dynamic>> get onContadorUpdate => _contadorUpdateController.stream;
  Stream<Map<String, dynamic>> get onLiveStatusChange => _liveStatusController.stream;
  Stream<String> get onError => _errorController.stream;
  
  // Estado de conexión
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Inicializar y conectar al servidor socket
  /// 
  /// [serverUrl] URL completa del servidor (ej: 'http://localhost:3000')
  /// [authToken] Token de autenticación opcional
  void init({required String serverUrl, String? authToken}) {
    try {
      // Cerrar conexión previa si existe
      disconnect();
      
      // Configuración del socket
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $authToken'})
            .build(),
      );

      // Configurar listeners para eventos del socket
      _setupSocketListeners();
      
      // Conectar al servidor
      _socket?.connect();
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar socket: $e');
      }
      _errorController.add('Error al conectar: $e');
    }
  }

  /// Configura los listeners para los eventos del socket
  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      _isConnected = true;
      _connectController.add(true);
      if (kDebugMode) {
        print('Conexión establecida');
      }
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      _connectController.add(false);
      if (kDebugMode) {
        print('Desconectado del servidor');
      }
    });

    _socket?.onError((error) {
      _errorController.add(error.toString());
      if (kDebugMode) {
        print('Error en la conexión: $error');
      }
    });

    // Eventos específicos de la aplicación
    _socket?.on('donacion', (data) {
      _donacionController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('updateContador', (data) {
      _contadorUpdateController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('liveActivado', (data) {
      _liveStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on('liveDesactivado', (data) {
      _liveStatusController.add(Map<String, dynamic>.from(data));
    });
  }

  /// Desconectar del servidor
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Enviar evento al servidor
  /// 
  /// [event] Nombre del evento
  /// [data] Datos a enviar
  void emit(String event, dynamic data) {
    if (_isConnected) {
      _socket?.emit(event, data);
    } else {
      _errorController.add('No se pudo enviar el evento: no hay conexión');
    }
  }

  /// Subscribirse a un evento específico
  /// 
  /// [event] Nombre del evento
  /// [handler] Función que maneja el evento
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Enviar evento de donación
  /// 
  /// [contendienteId] ID del contendiente (1 o 2)
  /// [cantidad] Cantidad de la donación
  /// [usuario] Nombre del usuario
  /// [plataforma] Plataforma origen de la donación
  void enviarDonacion({
    required int contendienteId,
    required int cantidad,
    required String usuario,
    required String plataforma,
  }) {
    emit('donacion', {
      'contendienteId': contendienteId,
      'cantidad': cantidad,
      'usuario': usuario,
      'plataforma': plataforma,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Activar un live
  /// 
  /// [liveId] ID del esqueleto de live a activar
  void activarLive(String liveId) {
    emit('activarLive', {'liveId': liveId});
  }

  /// Desactivar un live activo
  /// 
  /// [liveId] ID del live activo
  void desactivarLive(String liveId) {
    emit('desactivarLive', {'liveId': liveId});
  }

  /// Solicitar estado actual de los contadores
  void solicitarEstadoContadores() {
    emit('getContadores', {});
  }

  /// Destruir todos los controllers cuando ya no se necesitan
  void dispose() {
    disconnect();
    _connectController.close();
    _donacionController.close();
    _contadorUpdateController.close();
    _liveStatusController.close();
    _errorController.close();
  }
} 