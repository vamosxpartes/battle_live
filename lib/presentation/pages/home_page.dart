import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:battle_live/presentation/providers/donaciones_provider.dart';
import 'package:battle_live/presentation/pages/crear_esqueleto_page.dart';
import 'package:battle_live/presentation/pages/activar_live_page.dart';
import 'package:battle_live/presentation/pages/tiktok_stream_page.dart';
import 'package:battle_live/core/config/app_config.dart';
import 'package:battle_live/core/logging/app_logger.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _errorMensaje = '';
  final bool _socketConectado = false;
  
  // Datos hardcodeados para simular contendientes
  final Map<String, dynamic> _contendienteData = {
    'contendiente1': {
      'nombre': 'Equipo Azul',
      'imagen': 'assets/equipo_azul.jpg', // Placeholder - crear este archivo después
    },
    'contendiente2': {
      'nombre': 'Equipo Rojo',
      'imagen': 'assets/equipo_rojo.jpg', // Placeholder - crear este archivo después
    },
  };
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Live'),
        actions: [
          // Indicador de conexión de socket
          Consumer<DonacionesProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Tooltip(
                  message: _socketConectado 
                    ? 'Conectado al servidor' 
                    : 'Usando datos locales simulados',
                  child: Icon(
                    _socketConectado ? Icons.cloud_done : Icons.cloud_off,
                    color: _socketConectado ? Colors.green : Colors.grey,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Battle Live',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Crear esqueleto de live'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CrearEsqueletoPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_filled),
              title: const Text('Activar live'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ActivarLivePage()),
                );
              },
            ),
            // Nueva opción para TikTok Live
            ListTile(
              leading: const Icon(Icons.live_tv),
              title: const Text('TikTok Live'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TikTokStreamPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de eventos'),
              onTap: () {
                Navigator.pop(context);
                _mostrarHistorico(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(_socketConectado ? Icons.link : Icons.link_off),
              title: Text(_socketConectado ? 'Conectado al servidor' : 'Desconectado'),
              subtitle: _errorMensaje.isNotEmpty ? Text(_errorMensaje, style: TextStyle(color: Colors.red.shade700)) : null,
              onTap: _reconnectSocket,
              trailing: _socketConectado ? null : const Icon(Icons.refresh),
            ),
            if (!_socketConectado)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración del servidor'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarConfiguracionServidor(context);
                },
              ),
          ],
        ),
      ),
      body: Consumer<DonacionesProvider>(
        builder: (context, donacionesProvider, child) {
          if (donacionesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (donacionesProvider.error.isNotEmpty) {
            return Center(child: Text('Error: ${donacionesProvider.error}'));
          }

          return Column(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildContendiente(
                        _contendienteData['contendiente1']['nombre'],
                        donacionesProvider.contador1,
                        donacionesProvider.incrementarContador1,
                        Colors.blue.shade100,
                      ),
                    ),
                    Expanded(
                      child: _buildContendiente(
                        _contendienteData['contendiente2']['nombre'],
                        donacionesProvider.contador2,
                        donacionesProvider.incrementarContador2,
                        Colors.red.shade100,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.grey.shade200,
                  child: donacionesProvider.historicoDeEventos.isEmpty 
                    ? const Center(child: Text('No hay eventos recientes'))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: donacionesProvider.historicoDeEventos.length,
                        itemBuilder: (context, index) {
                          final donacion = donacionesProvider.historicoDeEventos[index];
                          return Card(
                            color: donacion.contendienteId == 1 
                              ? Colors.blue.shade100 
                              : Colors.red.shade100,
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(donacion.usuario, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('+${donacion.cantidad}', style: const TextStyle(fontSize: 18)),
                                  Text(donacion.plataforma, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Reconectar al servidor socket
  void _reconnectSocket() {
    AppLogger.info('Intentando reconectar socket con URL: ${AppConfig().socketServerUrl}', name: 'HomePage');
    
    setState(() {
      _errorMensaje = '';
    });
    
    // Obtener el provider de donaciones
    final donacionesProvider = Provider.of<DonacionesProvider>(context, listen: false);
    
    // Reinicar la conexión del socket a través del Provider
    try {
      // El DonacionesProvider contiene una referencia al repositorio que a su vez contiene al SocketService
      // Vamos a acceder directamente al SocketService para reiniciarlo
      final socketService = donacionesProvider.getSocketService();
      
      if (socketService != null) {
        AppLogger.info('Reiniciando conexión Socket', name: 'HomePage');
        socketService.init(); // Esto usará la URL actual en AppConfig
        
        // Solicitar estado actual después de la reconexión
        Future.delayed(const Duration(seconds: 1), () {
          socketService.solicitarEstadoContadores();
          socketService.solicitarHistorial();
        });
      } else {
        AppLogger.error('No se pudo obtener referencia al SocketService', name: 'HomePage');
        setState(() {
          _errorMensaje = 'Error al reconectar: No se pudo acceder al servicio de socket';
        });
      }
    } catch (e) {
      AppLogger.error('Error al reconectar socket', name: 'HomePage', error: e);
      setState(() {
        _errorMensaje = 'Error al reconectar: $e';
      });
    }
  }
  
  // Mostrar diálogo de configuración del servidor
  void _mostrarConfiguracionServidor(BuildContext context) {
    final serverUrlController = TextEditingController(text: AppConfig().socketServerUrl);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configuración del Servidor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: serverUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL del Servidor',
                  hintText: 'http://tuservidor.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'URL actual: ${AppConfig().socketServerUrl}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final newUrl = serverUrlController.text.trim();
                if (newUrl.isNotEmpty) {
                  AppLogger.info('Cambiando URL del servidor a: $newUrl', name: 'HomePage');
                  AppConfig().setSocketServerUrl(newUrl);
                  _reconnectSocket();
                  Navigator.of(context).pop();
                  
                  // Mostrar notificación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('URL del servidor actualizada: $newUrl')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarHistorico(BuildContext context) {
    final donacionesProvider = Provider.of<DonacionesProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Histórico de Donaciones'),
          content: SizedBox(
            width: double.maxFinite,
            child: donacionesProvider.historicoDeEventos.isEmpty
                ? const Center(child: Text('No hay donaciones registradas'))
                : ListView.builder(
                    itemCount: donacionesProvider.historicoDeEventos.length,
                    itemBuilder: (context, index) {
                      final donacion = donacionesProvider.historicoDeEventos[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: donacion.contendienteId == 1 
                              ? Colors.blue 
                              : Colors.red,
                          child: Text(donacion.contendienteId.toString()),
                        ),
                        title: Text(donacion.usuario),
                        subtitle: Text('Desde ${donacion.plataforma} - ${donacion.tiempoTranscurrido}'),
                        trailing: Text(
                          '+${donacion.cantidad}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContendiente(String nombre, int contador, VoidCallback onIncrement, Color color) {
    return Container(
      color: color,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            nombre,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey,
              border: Border.all(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 80),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '$contador',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onIncrement,
            child: const Text('Donar +5'),
          ),
        ],
      ),
    );
  }
} 