import 'package:battle_live/domain/repositories/donaciones_repository.dart';

/// Caso de uso para obtener los totales por contendiente
class GetTotalesContendientes {
  final DonacionesRepository repository;
  
  GetTotalesContendientes(this.repository);
  
  Future<Map<int, int>> call() async {
    return repository.getTotalesPorContendiente();
  }
} 