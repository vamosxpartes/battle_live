/// Clase de configuración global de la aplicación
/// Implementa el patrón Singleton para acceder a la configuración desde cualquier parte
class AppConfig {
  // Instancia única de AppConfig (patrón Singleton)
  static final AppConfig _instance = AppConfig._internal();
  
  // Constructor factory que devuelve la instancia del singleton
  factory AppConfig() => _instance;
  
  // Constructor privado
  AppConfig._internal();
  
  // Valores de configuración
  bool _isProduction = false;
  String _socketServerUrl = 'http://192.168.100.106:3030';
  
  // Inicializar configuración
  void init({required bool isProduction}) {
    _isProduction = isProduction;
    
    // Configurar URLs según el entorno
    if (_isProduction) {
      _socketServerUrl = 'https://battle-live-server.com'; // URL de producción
    } else {
      _socketServerUrl = 'http://192.168.100.106:3030'; // URL de desarrollo local
    }
  }
  
  // Getters
  bool get isProduction => _isProduction;
  String get socketServerUrl => _socketServerUrl;
  
  // Cambiar URL del servidor socket
  void setSocketServerUrl(String url) {
    _socketServerUrl = url;
  }
} 