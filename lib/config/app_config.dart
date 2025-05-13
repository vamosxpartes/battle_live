/// Configuración de la aplicación
class AppConfig {
  /// Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Configuración del servidor Socket.io
  late String _socketServerUrl;
  String get socketServerUrl => _socketServerUrl;

  // Variables de entorno
  bool _isProduction = false;
  bool get isProduction => _isProduction;

  // URLs de servidor según el ambiente
  static const String _devSocketUrl = 'http://192.168.100.105:3000';
  static const String _prodSocketUrl = 'https://api.battlelive.com';

  /// Inicializa la configuración de la aplicación
  void init({bool isProduction = false}) {
    _isProduction = isProduction;
    _socketServerUrl = _isProduction ? _prodSocketUrl : _devSocketUrl;
  }

  /// Cambiar la URL del servidor socket
  void setSocketServerUrl(String url) {
    _socketServerUrl = url;
  }
} 