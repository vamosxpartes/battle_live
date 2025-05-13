import 'package:intl/intl.dart';
import 'package:battle_live/domain/entities/donacion.dart';

/// Modelo de datos para donaciones que extiende la entidad de dominio
class DonacionModel extends Donacion {
  DonacionModel({
    super.id = '',
    required super.usuario,
    required super.cantidad,
    required super.contendienteId,
    required super.plataforma,
    super.timestamp,
  });

  /// Crear una donación desde un mapa de datos (JSON del servidor)
  factory DonacionModel.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(json['timestamp'] ?? '');
    } catch (e) {
      timestamp = DateTime.now();
    }

    return DonacionModel(
      id: json['id'] ?? '',
      usuario: json['usuario'] ?? 'Anónimo',
      cantidad: json['cantidad'] ?? 0,
      contendienteId: json['contendienteId'] ?? 1,
      plataforma: json['plataforma'] ?? 'Desconocida',
      timestamp: timestamp,
    );
  }

  /// Convertir la donación a un mapa de datos (para enviar al servidor)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario': usuario,
      'cantidad': cantidad,
      'contendienteId': contendienteId,
      'plataforma': plataforma,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Obtener una representación formateada del timestamp
  String get tiempoFormateado {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(timestamp);
  }
  
  /// Crear un modelo a partir de la entidad
  factory DonacionModel.fromEntity(Donacion entity) {
    return DonacionModel(
      id: entity.id,
      usuario: entity.usuario,
      cantidad: entity.cantidad,
      contendienteId: entity.contendienteId,
      plataforma: entity.plataforma,
      timestamp: entity.timestamp,
    );
  }
} 