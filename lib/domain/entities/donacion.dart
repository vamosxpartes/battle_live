/// Entidad de dominio para representar una donación
class Donacion {
  final String id;
  final String usuario;
  final int cantidad;
  final int contendienteId; // 1 o 2 para indicar para quién es la donación
  final String plataforma; // Ej: "YouTube", "Twitch", "Instagram", "TikTok"
  final DateTime timestamp;

  Donacion({
    this.id = '',
    required this.usuario,
    required this.cantidad,
    required this.contendienteId,
    required this.plataforma,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Obtener el tiempo transcurrido desde la donación como string
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