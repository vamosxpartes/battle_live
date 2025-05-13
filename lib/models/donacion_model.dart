import 'package:intl/intl.dart';

/// Modelo para las donaciones
class Donacion {
  final String id;
  final String usuario;
  final int cantidad;
  final int contendienteId; // 1 o 2 para indicar para quién es la donación
  final String plataforma; // Ej: "YouTube", "Twitch", "Instagram"
  final DateTime timestamp;

  Donacion({
    this.id = '',
    required this.usuario,
    required this.cantidad,
    required this.contendienteId,
    required this.plataforma,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Crear una donación desde un mapa de datos (JSON del servidor)
  factory Donacion.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(json['timestamp'] ?? '');
    } catch (e) {
      timestamp = DateTime.now();
    }

    return Donacion(
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

  /// Obtener el tiempo transcurrido desde la donación
  String get tiempoTranscurrido {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Ahora';
    }
  }
} 