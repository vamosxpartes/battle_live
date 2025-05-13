import 'package:battle_live/domain/repositories/donaciones_repository.dart';

/// Caso de uso para enviar una donación
class EnviarDonacion {
  final DonacionesRepository repository;
  
  EnviarDonacion(this.repository);
  
  Future<void> call({
    required int contendienteId,
    required int cantidad,
    required String usuario,
    required String plataforma,
  }) async {
    return repository.enviarDonacion(
      contendienteId: contendienteId,
      cantidad: cantidad,
      usuario: usuario,
      plataforma: plataforma,
    );
  }
} 