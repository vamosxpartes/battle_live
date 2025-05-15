import 'package:flutter/material.dart';
import 'package:battle_live/services/tiktok_service.dart';
import 'package:battle_live/services/tiktok_live_client.dart';
import 'package:battle_live/config/app_config.dart';
import 'package:battle_live/models/donacion_model.dart';
import 'package:battle_live/core/logging/app_logger.dart';

class TikTokStreamPage extends StatefulWidget {
  const TikTokStreamPage({super.key});

  @override
  State<TikTokStreamPage> createState() => _TikTokStreamPageState();
}

class _TikTokStreamPageState extends State<TikTokStreamPage> {
  // Cliente TikTok Live - inicializado con valor por defecto
  final TikTokService _tikTokService = TikTokService(
    serverUrl: AppConfig().socketServerUrl
  );
  
  // Lista de mensajes
  final List<ChatEvent> _messages = [];
  
  // Lista de regalos
  final List<GiftEvent> _gifts = [];
  
  // Contadores
  int _viewerCount = 0;
  int _likeCount = 0;
  
  // Estado de conexión
  bool _isConnected = false;
  String _statusMessage = 'Desconectado';
  
  // Controller para el campo de texto
  final TextEditingController _usernameController = TextEditingController();
  
  // Lista de donaciones procesadas
  final List<Donacion> _donaciones = [];
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar servicio - ya no es necesario, se inicializa en la declaración
    AppLogger.info('TikTokService ya inicializado en TikTokStreamPage con URL: ${AppConfig().socketServerUrl}', name: 'TikTokStreamPage');
    
    // Configurar listener para donaciones
    _tikTokService.addDonacionListener(_procesarDonacion);
    
    // Configurar listeners
    _setupListeners();
  }
  
  void _setupListeners() {
    // Obtener el cliente interno para eventos específicos que no son donaciones
    final client = _tikTokService.client;
    
    // Escuchar mensajes de chat
    client.chatStream.listen((event) {
      setState(() {
        _messages.add(event);
        if (_messages.length > 50) {
          _messages.removeAt(0); // Limitar cantidad de mensajes
        }
      });
    });
    
    // Escuchar regalos
    client.giftStream.listen((event) {
      setState(() {
        _gifts.add(event);
        if (_gifts.length > 20) {
          _gifts.removeAt(0); // Limitar cantidad de regalos
        }
      });
    });
    
    // Escuchar conteo de espectadores
    client.viewerCountStream.listen((event) {
      setState(() {
        _viewerCount = event.count;
      });
    });
    
    // Escuchar likes
    client.likeStream.listen((event) {
      setState(() {
        _likeCount += event.likeCount.toInt();
      });
    });
    
    // Escuchar estado de conexión
    client.connectionStateStream.listen((event) {
      setState(() {
        _isConnected = event.isConnected;
        _statusMessage = event.isConnected 
            ? 'Conectado a @${event.username}' 
            : 'Desconectado';
      });
    });
    
    // Escuchar errores
    client.errorStream.listen((event) {
      setState(() {
        _statusMessage = 'Error: ${event.message}';
      });
      
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.message)),
      );
    });
  }
  
  // Procesar donación
  void _procesarDonacion(Donacion donacion) {
    setState(() {
      _donaciones.add(donacion);
      
      // Limitar el tamaño de la lista
      if (_donaciones.length > 50) {
        _donaciones.removeAt(0);
      }
    });
    
    // Mostrar notificación de donación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '¡${donacion.usuario} ha donado ${donacion.cantidad} para el Equipo ${donacion.contendienteId}!',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: donacion.contendienteId == 1 ? Colors.blue : Colors.red,
      ),
    );
  }
  
  // Conectar a un usuario de TikTok
  Future<void> _connectToUser() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre de usuario')),
      );
      return;
    }
    
    setState(() {
      _statusMessage = 'Conectando a @$username...';
      _messages.clear();
      _gifts.clear();
      _viewerCount = 0;
      _likeCount = 0;
    });
    
    AppLogger.info('Intentando conectar a usuario TikTok: @$username usando URL: ${AppConfig().socketServerUrl}', name: 'TikTokStreamPage');
    final success = await _tikTokService.conectarUsuario(username);
    
    AppLogger.info('Resultado de conexión a @$username: ${success ? 'Éxito' : 'Fallo'}', name: 'TikTokStreamPage');
    
    if (!success) {
      setState(() {
        _statusMessage = 'Error al conectar a @$username';
      });
      AppLogger.error('Falló la conexión a @$username', name: 'TikTokStreamPage');
    }
  }
  
  @override
  void dispose() {
    // Liberar recursos
    _tikTokService.dispose();
    _usernameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TikTok Live Chat'),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
      ),
      body: Column(
        children: [
          // Estado de conexión
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            width: double.infinity,
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          // Estadísticas
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(icon: Icons.visibility, value: '$_viewerCount', label: 'Espectadores'),
                _buildStatCard(icon: Icons.favorite, value: '$_likeCount', label: 'Likes'),
                _buildStatCard(icon: Icons.card_giftcard, value: '${_gifts.length}', label: 'Regalos'),
              ],
            ),
          ),
          
          // Campo para ingresar usuario
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario de TikTok',
                      prefixText: '@',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _connectToUser(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _connectToUser,
                  child: const Text('Conectar'),
                ),
              ],
            ),
          ),
          
          // Pestañas para mensajes, regalos y donaciones
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Chat', icon: Icon(Icons.chat)),
                      Tab(text: 'Regalos', icon: Icon(Icons.card_giftcard)),
                      Tab(text: 'Donaciones', icon: Icon(Icons.attach_money)),
                    ],
                    labelColor: Colors.blue,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Pestaña de mensajes de chat
                        _messages.isEmpty
                            ? const Center(child: Text('Esperando mensajes...'))
                            : ListView.builder(
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      child: message.avatarUrl.isNotEmpty
                                          ? Image.network(message.avatarUrl)
                                          : const Icon(Icons.person),
                                    ),
                                    title: Text(message.username),
                                    subtitle: Text(message.message),
                                  );
                                },
                              ),
                        
                        // Pestaña de regalos
                        _gifts.isEmpty
                            ? const Center(child: Text('Esperando regalos...'))
                            : ListView.builder(
                                itemCount: _gifts.length,
                                itemBuilder: (context, index) {
                                  final gift = _gifts[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.amber,
                                      child: Text('${gift.diamondCount}'),
                                    ),
                                    title: Text('${gift.username} envió ${gift.giftName}'),
                                    subtitle: Text('${gift.diamondCount} diamonds x ${gift.repeatCount}'),
                                    trailing: const Icon(Icons.card_giftcard, color: Colors.amber),
                                  );
                                },
                              ),
                        
                        // Pestaña de donaciones procesadas
                        _donaciones.isEmpty
                            ? const Center(child: Text('Esperando donaciones...'))
                            : ListView.builder(
                                itemCount: _donaciones.length,
                                itemBuilder: (context, index) {
                                  final donacion = _donaciones[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: donacion.contendienteId == 1 ? Colors.blue : Colors.red,
                                      child: Text('${donacion.contendienteId}'),
                                    ),
                                    title: Text(donacion.usuario),
                                    subtitle: Text('Desde ${donacion.plataforma}'),
                                    trailing: Text(
                                      '+${donacion.cantidad}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
} 