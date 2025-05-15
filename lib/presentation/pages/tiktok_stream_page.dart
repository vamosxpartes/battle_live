import 'package:flutter/material.dart';
import 'package:battle_live/data/datasources/tiktok_live_client.dart';
import 'package:battle_live/core/config/app_config.dart';
import 'package:provider/provider.dart';
import 'package:battle_live/presentation/providers/donaciones_provider.dart';
import 'package:battle_live/core/logging/app_logger.dart';

class TikTokStreamPage extends StatefulWidget {
  const TikTokStreamPage({super.key});

  @override
  State<TikTokStreamPage> createState() => _TikTokStreamPageState();
}

class _TikTokStreamPageState extends State<TikTokStreamPage> {
  // Cliente TikTok Live
  late TikTokLiveClient _tikTokClient;
  
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
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar cliente
    _tikTokClient = TikTokLiveClient(serverUrl: AppConfig().socketServerUrl);
    _tikTokClient.initialize();
    
    // Configurar listeners
    _setupListeners();
  }
  
  void _setupListeners() {
    // Escuchar mensajes de chat
    _tikTokClient.chatStream.listen((event) {
      setState(() {
        _messages.add(event);
        if (_messages.length > 50) {
          _messages.removeAt(0); // Limitar cantidad de mensajes
        }
      });
    });
    
    // Escuchar regalos
    _tikTokClient.giftStream.listen((event) {
      setState(() {
        _gifts.add(event);
        if (_gifts.length > 20) {
          _gifts.removeAt(0); // Limitar cantidad de regalos
        }
      });
      
      // Procesar como donación (usando el provider)
      final donacionesProvider = Provider.of<DonacionesProvider>(context, listen: false);
      donacionesProvider.enviarDonacion(
        contendienteId: _determinarContendiente(event.username),
        cantidad: event.diamondCount,
        usuario: event.username,
        plataforma: 'TikTok',
      );
    });
    
    // Escuchar conteo de espectadores
    _tikTokClient.viewerCountStream.listen((event) {
      setState(() {
        _viewerCount = event.count;
      });
    });
    
    // Escuchar likes
    _tikTokClient.likeStream.listen((event) {
      AppLogger.info('Procesando evento like en UI: username=${event.username}, count=${event.likeCount}', name: 'WebSocketEventProcessing');
      setState(() {
        _likeCount += event.likeCount.toInt();
        AppLogger.info('Contador de likes actualizado a: $_likeCount', name: 'WebSocketEventProcessing');
      });
    });
    
    // Escuchar estado de conexión
    _tikTokClient.connectionStateStream.listen((event) {
      setState(() {
        _isConnected = event.isConnected;
        _statusMessage = event.isConnected 
            ? 'Conectado a @${event.username}' 
            : 'Desconectado';
      });
    });
    
    // Escuchar errores
    _tikTokClient.errorStream.listen((event) {
      setState(() {
        _statusMessage = 'Error: ${event.message}';
      });
      
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.message)),
      );
    });
  }
  
  // Determinar a qué contendiente apoya el usuario
  int _determinarContendiente(String username) {
    // Ejemplo: Basado en la primera letra del nombre
    final firstChar = username.toLowerCase().codeUnitAt(0);
    return firstChar % 2 == 0 ? 1 : 2; // Par -> Equipo 1, Impar -> Equipo 2
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
    
    final success = await _tikTokClient.connectToUser(username);
    
    if (!success) {
      setState(() {
        _statusMessage = 'Error al conectar a @$username';
      });
    }
  }
  
  @override
  void dispose() {
    // Liberar recursos
    _tikTokClient.dispose();
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
          
          // Pestañas para mensajes y regalos
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Chat', icon: Icon(Icons.chat)),
                      Tab(text: 'Regalos', icon: Icon(Icons.card_giftcard)),
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
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        child: message.avatarUrl.isNotEmpty
                                            ? ClipOval(
                                                child: Image.network(
                                                  message.avatarUrl,
                                                  errorBuilder: (context, error, stackTrace) => 
                                                    const Icon(Icons.person),
                                                ),
                                              )
                                            : const Icon(Icons.person),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              message.username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (message.formattedTime.isNotEmpty)
                                            Text(
                                              message.formattedTime,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(message.message),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (message.isSubscriber)
                                                _buildBadge(Icons.workspace_premium, Colors.purple),
                                              if (message.isModerator)
                                                _buildBadge(Icons.shield, Colors.blue),
                                            ],
                                          ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                    ),
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
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    color: _getGiftColor(gift.giftName),
                                    child: ListTile(
                                      leading: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: gift.giftImageUrl.isNotEmpty
                                            ? Image.network(
                                                gift.giftImageUrl,
                                                errorBuilder: (context, error, stackTrace) => 
                                                  _getGiftIcon(gift.giftName),
                                              )
                                            : _getGiftIcon(gift.giftName),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text('${gift.username} envió ${gift.giftName}'),
                                          ),
                                          if (gift.formattedTime.isNotEmpty)
                                            Text(
                                              gift.formattedTime,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${gift.diamondCount} diamonds ${gift.repeatCount > 1 ? 'x${gift.repeatCount}' : ''} = ${gift.totalValue} total',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      trailing: CircleAvatar(
                                        backgroundColor: Colors.amber[800],
                                        child: Text(
                                          '${gift.totalValue}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
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
  
  Widget _buildBadge(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
            Text(
              icon == Icons.workspace_premium ? 'Suscriptor' : 'Moderador',
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getGiftColor(String giftName) {
    final giftNameLower = giftName.toLowerCase();
    if (giftNameLower.contains('rose') || giftNameLower.contains('rosa')) 
      return Colors.pink[50]!;
    if (giftNameLower.contains('heart') || giftNameLower.contains('corazon')) 
      return Colors.red[50]!;
    if (giftNameLower.contains('bear') || giftNameLower.contains('oso')) 
      return Colors.brown[50]!;
    if (giftNameLower.contains('crown') || giftNameLower.contains('corona')) 
      return Colors.yellow[50]!;
    return Colors.amber[50]!;
  }
  
  Widget _getGiftIcon(String giftName) {
    final giftNameLower = giftName.toLowerCase();
    if (giftNameLower.contains('rose') || giftNameLower.contains('rosa')) 
      return const Icon(Icons.local_florist, color: Colors.pink);
    if (giftNameLower.contains('heart') || giftNameLower.contains('corazon')) 
      return const Icon(Icons.favorite, color: Colors.red);
    if (giftNameLower.contains('bear') || giftNameLower.contains('oso')) 
      return const Icon(Icons.pets, color: Colors.brown);
    if (giftNameLower.contains('crown') || giftNameLower.contains('corona')) 
      return const Icon(Icons.emoji_events, color: Colors.amber);
    return const Icon(Icons.card_giftcard, color: Colors.amber);
  }
} 