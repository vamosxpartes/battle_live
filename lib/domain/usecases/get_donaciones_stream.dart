import 'package:battle_live/domain/entities/donacion.dart';
import 'package:battle_live/domain/repositories/donaciones_repository.dart';

/// Caso de uso para obtener el flujo de donaciones en tiempo real
class GetDonacionesStream {
  final DonacionesRepository repository;
  
  GetDonacionesStream(this.repository);
  
  Stream<Donacion> call() {
    return repository.getDonacionesStream();
  }
} 