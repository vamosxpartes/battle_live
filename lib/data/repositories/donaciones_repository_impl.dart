import 'package:battle_live/data/datasources/socket_service.dart';
import 'package:battle_live/domain/entities/donacion.dart';
import 'package:battle_live/domain/repositories/donaciones_repository.dart';

/// Implementación del repositorio de donaciones
class DonacionesRepositoryImpl implements DonacionesRepository {
  final SocketService _socketService;
  
  // Caché de totales por contendiente
  final Map<int, int> _totalesPorContendiente = {1: 0, 2: 0};
  
  DonacionesRepositoryImpl(this._socketService) {
    // Escuchar actualizaciones de contadores
    _socketService.onContadorUpdate.listen((data) {
      _totalesPorContendiente[1] = data['contador1'] ?? _totalesPorContendiente[1];
      _totalesPorContendiente[2] = data['contador2'] ?? _totalesPorContendiente[2];
    });
    
    // Actualizar contadores cuando llegan donaciones
    _socketService.onDonacion.listen((donacion) {
      _totalesPorContendiente[donacion.contendienteId] = 
          (_totalesPorContendiente[donacion.contendienteId] ?? 0) + donacion.cantidad;
    });
    
    // Solicitar estado inicial
    _socketService.solicitarEstadoContadores();
  }
  
  @override
  Stream<Donacion> getDonacionesStream() {
    return _socketService.onDonacion;
  }
  
  @override
  Future<void> enviarDonacion({
    required int contendienteId,
    required int cantidad,
    required String usuario,
    required String plataforma,
  }) async {
    _socketService.enviarDonacion(
      contendienteId: contendienteId,
      cantidad: cantidad,
      usuario: usuario,
      plataforma: plataforma,
    );
  }
  
  @override
  Future<List<Donacion>> getHistorialDonaciones() async {
    // En una implementación real, probablemente solicitaríamos
    // el historial al servidor y esperaríamos la respuesta
    _socketService.solicitarHistorial();
    
    // Por ahora, devolvemos una lista vacía 
    // (en una implementación real, esto debería esperar la respuesta del servidor)
    return [];
  }
  
  @override
  Future<Map<int, int>> getTotalesPorContendiente() async {
    return Map.from(_totalesPorContendiente);
  }
  
  // Método para permitir acceso al SocketService desde fuera
  // Esto es necesario para poder reiniciar la conexión desde la UI
  SocketService getSocketService() {
    return _socketService;
  }
} 