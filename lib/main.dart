import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

// Importación de Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Importación de repositorios y fuentes de datos
import 'package:battle_live/data/datasources/socket_service.dart';
import 'package:battle_live/data/repositories/donaciones_repository_impl.dart';

// Importación de casos de uso
import 'package:battle_live/domain/usecases/get_donaciones_stream.dart';
import 'package:battle_live/domain/usecases/enviar_donacion.dart';
import 'package:battle_live/domain/usecases/get_totales_contendientes.dart';

// Importación de providers
import 'package:battle_live/presentation/providers/donaciones_provider.dart';

// Importación de páginas
import 'package:battle_live/presentation/pages/home_page.dart';

// Importación de configuración
import 'package:battle_live/core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!kIsWeb) {
      await Firebase.initializeApp();
    } else {
      debugPrint('Error inicializando Firebase: $e');
    }
  }
  
  // Inicializar configuración
  AppConfig().init(isProduction: false);
  
  // Inicializar servicio de socket
  final socketService = SocketService();
  socketService.init();
  
  // Inicializar repositorio
  final donacionesRepository = DonacionesRepositoryImpl(socketService);
  
  // Inicializar casos de uso
  final getDonacionesStream = GetDonacionesStream(donacionesRepository);
  final enviarDonacion = EnviarDonacion(donacionesRepository);
  final getTotalesContendientes = GetTotalesContendientes(donacionesRepository);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DonacionesProvider(
            getDonacionesStream: getDonacionesStream,
            enviarDonacion: enviarDonacion,
            getTotalesContendientes: getTotalesContendientes,
          ),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}
