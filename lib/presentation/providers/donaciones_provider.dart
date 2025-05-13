import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:battle_live/domain/entities/donacion.dart';
import 'package:battle_live/domain/usecases/get_donaciones_stream.dart';
import 'package:battle_live/domain/usecases/enviar_donacion.dart';
import 'package:battle_live/domain/usecases/get_totales_contendientes.dart';
import 'package:battle_live/data/datasources/socket_service.dart';
import 'package:battle_live/data/repositories/donaciones_repository_impl.dart';
import 'package:battle_live/core/logging/app_logger.dart';

/// Provider para gestionar el estado de las donaciones
class DonacionesProvider with ChangeNotifier {
  final GetDonacionesStream _getDonacionesStream;
  final EnviarDonacion _enviarDonacion;
  final GetTotalesContendientes _getTotalesContendientes;
  
  // Estado
  final List<Donacion> _historicoDeEventos = [];
  int _contador1 = 0;
  int _contador2 = 0;
  bool _isLoading = false;
  String _error = '';
  
  // Suscripción al stream de donaciones
  StreamSubscription<Donacion>? _donacionesSubscription;
  
  // Getters
  List<Donacion> get historicoDeEventos => List.unmodifiable(_historicoDeEventos);
  int get contador1 => _contador1;
  int get contador2 => _contador2;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  DonacionesProvider({
    required GetDonacionesStream getDonacionesStream,
    required EnviarDonacion enviarDonacion,
    required GetTotalesContendientes getTotalesContendientes,
  }) : _getDonacionesStream = getDonacionesStream,
       _enviarDonacion = enviarDonacion,
       _getTotalesContendientes = getTotalesContendientes {
    _inicializarStreams();
    _cargarTotales();
  }
  
  void _inicializarStreams() {
    AppLogger.info('Inicializando streams de donaciones', name: 'WebSocketEventProcessing');
    _donacionesSubscription = _getDonacionesStream().listen(
      (donacion) {
        AppLogger.info('Donación recibida en stream: ${donacion.toString()}', name: 'WebSocketEventProcessing');
        _procesarDonacion(donacion);
      },
      onError: (error) {
        _error = error.toString();
        AppLogger.error('Error en stream de donaciones: $_error', name: 'WebSocketEventProcessing', error: error);
        notifyListeners();
      }
    );
  }
  
  Future<void> _cargarTotales() async {
    _isLoading = true;
    notifyListeners();
    
    AppLogger.info('Cargando totales de contendientes', name: 'WebSocketEventProcessing');
    
    try {
      final totales = await _getTotalesContendientes();
      _contador1 = totales[1] ?? 0;
      _contador2 = totales[2] ?? 0;
      
      AppLogger.info('Totales cargados - Contador1: $_contador1, Contador2: $_contador2', name: 'WebSocketEventProcessing');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error al cargar totales: $_error', name: 'WebSocketEventProcessing', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _procesarDonacion(Donacion donacion) {
    // Añadir al histórico
    _historicoDeEventos.insert(0, donacion);
    
    // Registrar información detallada sobre la donación procesada
    AppLogger.info(
      'Procesando donación: ID=${donacion.id}, Usuario=${donacion.usuario}, Contendiente=${donacion.contendienteId}, Cantidad=${donacion.cantidad}, Plataforma=${donacion.plataforma}',
      name: 'WebSocketEventProcessing'
    );
    
    // Limitar el tamaño del histórico
    if (_historicoDeEventos.length > 20) {
      _historicoDeEventos.removeLast();
    }
    
    // Actualizar contadores
    if (donacion.contendienteId == 1) {
      _contador1 += donacion.cantidad;
      AppLogger.info('Contador 1 actualizado: $_contador1', name: 'WebSocketEventProcessing');
    } else {
      _contador2 += donacion.cantidad;
      AppLogger.info('Contador 2 actualizado: $_contador2', name: 'WebSocketEventProcessing');
    }
    
    notifyListeners();
  }
  
  Future<void> enviarDonacion({
    required int contendienteId,
    required int cantidad,
    required String usuario,
    required String plataforma,
  }) async {
    try {
      await _enviarDonacion(
        contendienteId: contendienteId,
        cantidad: cantidad,
        usuario: usuario,
        plataforma: plataforma,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Incrementar contadores manualmente (para pruebas)
  void incrementarContador1() {
    const cantidad = 5;
    enviarDonacion(
      contendienteId: 1,
      cantidad: cantidad,
      usuario: 'Usuario App',
      plataforma: 'App',
    );
  }
  
  void incrementarContador2() {
    const cantidad = 5;
    enviarDonacion(
      contendienteId: 2,
      cantidad: cantidad,
      usuario: 'Usuario App',
      plataforma: 'App',
    );
  }
  
  // Método para obtener el SocketService (para reconexiones)
  SocketService? getSocketService() {
    try {
      // Intentar acceder al SocketService a través del caso de uso y repository
      final getDonaStream = _getDonacionesStream;
      if (getDonaStream.repository is DonacionesRepositoryImpl) {
        final repository = getDonaStream.repository as DonacionesRepositoryImpl;
        AppLogger.info('SocketService encontrado a través del repositorio', name: 'DonacionesProvider');
        return repository.getSocketService();
      }
          
      AppLogger.warning('No se pudo obtener SocketService: repository no es del tipo correcto', name: 'DonacionesProvider');
      return null;
    } catch (e) {
      AppLogger.error('Error al obtener SocketService', name: 'DonacionesProvider', error: e);
      return null;
    }
  }
  
  @override
  void dispose() {
    _donacionesSubscription?.cancel();
    super.dispose();
  }
} 