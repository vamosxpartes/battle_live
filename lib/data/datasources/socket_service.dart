import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:battle_live/core/config/app_config.dart';
import 'package:battle_live/data/models/donacion_model.dart';
import 'package:battle_live/core/logging/app_logger.dart';

/// Servicio para conectarse con el servidor socket
class SocketService {
  // Socket para la conexión
  io.Socket? _socket;
  
  // Controladores de eventos
  final _onConnectController = StreamController<bool>.broadcast();
  final _onErrorController = StreamController<String>.broadcast();
  final _onDonacionController = StreamController<DonacionModel>.broadcast();
  final _onContadorUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Streams públicos
  Stream<bool> get onConnect => _onConnectController.stream;
  Stream<String> get onError => _onErrorController.stream;
  Stream<DonacionModel> get onDonacion => _onDonacionController.stream;
  Stream<Map<String, dynamic>> get onContadorUpdate => _onContadorUpdateController.stream;

  // Inicializar el servicio
  void init({String? serverUrl}) {
    try {
      final url = serverUrl ?? AppConfig().socketServerUrl;
      AppLogger.info('Inicializando SocketService con URL: $url', name: 'SocketService');
      
      // Si ya hay una conexión existente, cerrarla
      if (_socket != null) {
        AppLogger.info('Cerrando conexión de socket existente', name: 'SocketService');
        _socket!.dispose();
      }
      
      // Crear un nuevo socket
      AppLogger.info('Creando nueva conexión de socket en $url', name: 'SocketService');
      _socket = io.io(
        url,
        io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .build()
      );
      
      // Configurar manejadores de eventos
      _setupEventHandlers();
      
    } catch (e) {
      AppLogger.error('Error al inicializar socket', name: 'SocketService', error: e);
      _onErrorController.add('Error al conectar con el servidor: $e');
    }
  }
  
  // Configurar manejadores de eventos
  void _setupEventHandlers() {
    AppLogger.info('Configurando manejadores de eventos de socket', name: 'SocketService');
    
    // Conectado al servidor
    _socket?.onConnect((_) {
      AppLogger.info('Socket conectado exitosamente', name: 'SocketService');
      AppLogger.info('Evento de conexión websocket detectado', name: 'WebSocketEventContent');
      _onConnectController.add(true);
    });
    
    // Desconectado del servidor
    _socket?.onDisconnect((_) {
      AppLogger.warning('Socket desconectado', name: 'SocketService');
      AppLogger.info('Evento de desconexión websocket detectado', name: 'WebSocketEventContent');
      _onConnectController.add(false);
    });
    
    // Error de conexión
    _socket?.onConnectError((error) {
      AppLogger.error('Error de conexión de socket', name: 'SocketService', error: error);
      AppLogger.info('Evento de error de conexión websocket: $error', name: 'WebSocketEventContent');
      _onErrorController.add('Error de conexión: $error');
    });
    
    // Escuchar evento de donación
    _socket?.on('donacion', (data) {
      try {
        AppLogger.info('Evento donacion recibido: $data', name: 'SocketService');
        AppLogger.info('Contenido del evento donacion: ${data.toString()}', name: 'WebSocketEventContent');
        final donacion = DonacionModel.fromJson(data);
        _onDonacionController.add(donacion);
      } catch (e) {
        AppLogger.error('Error al procesar donación', name: 'SocketService', error: e);
        _onErrorController.add('Error al procesar donación: $e');
      }
    });
    
    // Escuchar evento de actualización de contadores
    _socket?.on('contador_update', (data) {
      try {
        AppLogger.info('Evento contador_update recibido: $data', name: 'SocketService');
        AppLogger.info('Contenido del evento contador_update: ${data.toString()}', name: 'WebSocketEventContent');
        _onContadorUpdateController.add(data);
      } catch (e) {
        AppLogger.error('Error al procesar actualización de contador', name: 'SocketService', error: e);
        _onErrorController.add('Error al procesar actualización de contador: $e');
      }
    });

    // Añadir listener para todos los eventos recibidos
    _socket?.onAny((event, data) {
      AppLogger.info('Evento genérico recibido: $event', name: 'SocketService');
      AppLogger.info('Contenido del evento $event: ${data?.toString() ?? "sin datos"}', name: 'WebSocketEventContent');
    });
  }
  
  // Enviar una donación al servidor
  void enviarDonacion({
    required int contendienteId,
    required int cantidad,
    required String usuario,
    required String plataforma,
  }) {
    final donacion = DonacionModel(
      contendienteId: contendienteId,
      cantidad: cantidad,
      usuario: usuario,
      plataforma: plataforma,
    );
    
    AppLogger.info(
      'Enviando donación al servidor: contendiente=$contendienteId, cantidad=$cantidad, usuario=$usuario', 
      name: 'SocketService'
    );
    
    if (_socket == null) {
      AppLogger.error('Intento de envío de donación con socket nulo', name: 'SocketService');
      return;
    }
    
    _socket?.emit('donacion', donacion.toJson());
  }
  
  // Solicitar estado actual de los contadores al servidor
  void solicitarEstadoContadores() {
    AppLogger.info('Solicitando estado de contadores al servidor', name: 'SocketService');
    
    if (_socket == null) {
      AppLogger.error('Intento de solicitar contadores con socket nulo', name: 'SocketService');
      return;
    }
    
    _socket?.emit('solicitar_contadores');
  }
  
  // Solicitar historial de eventos al servidor
  void solicitarHistorial() {
    AppLogger.info('Solicitando historial de eventos al servidor', name: 'SocketService');
    
    if (_socket == null) {
      AppLogger.error('Intento de solicitar historial con socket nulo', name: 'SocketService');
      return;
    }
    
    _socket?.emit('solicitar_historial');
  }
  
  // Dispose de los recursos
  void dispose() {
    AppLogger.info('Liberando recursos de SocketService', name: 'SocketService');
    _socket?.dispose();
    _onConnectController.close();
    _onErrorController.close();
    _onDonacionController.close();
    _onContadorUpdateController.close();
  }
} 