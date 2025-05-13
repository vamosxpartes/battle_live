import 'package:battle_live/domain/entities/donacion.dart';

/// Interfaz del repositorio de donaciones
abstract class DonacionesRepository {
  /// Obtener el flujo de donaciones en tiempo real
  Stream<Donacion> getDonacionesStream();
  
  /// Enviar una donación
  Future<void> enviarDonacion({
    required int contendienteId,
    required int cantidad,
    required String usuario,
    required String plataforma,
  });
  
  /// Obtener el historial de donaciones
  Future<List<Donacion>> getHistorialDonaciones();
  
  /// Obtener los totales actuales de donaciones por contendiente
  Future<Map<int, int>> getTotalesPorContendiente();
} 