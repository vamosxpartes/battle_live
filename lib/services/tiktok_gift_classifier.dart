// Servicio para clasificar regalos de TikTok en grupos y asignar puntos
import 'package:battle_live/core/logging/app_logger.dart';
import 'dart:math';

class TikTokGiftClassifier {
  // Mapeo de grupos y regalos con sus valores en diamantes
  final Map<String, Map<String, List<String>>> _giftGroups = {
    "Grupo_A": {
      "1": ["Rose", "Coffee", "Alien Peace Sign"],
      "5": ["Finger Heart", "Chic", "Duckling", "Cotton's Shell", "Ice Cream Cone"],
      "10": ["Dolphin", "Rosa", "Christmas Wreath", "Gold Boxing Glove", "Hi Bear", "Sausage"],
      "20": ["Cake"],
      "99": ["Hand Hearts", "Confetti", "Bubble Gum", "Fest Crown", "Paper Crane", "Level-up Sparks"],
      "199": ["Massage for You", "Wooly Hat", "Eye See You", "Dancing Hands", "Santa's Mailbox"],
      "299": ["Corgi", "Elephant Trunk", "Fruit Friends", "Play for You", "Rock Star"],
      "399": ["Tom's Hug", "Relaxed Goose", "Rosie the Rose Bean", "Jolly the Joy Bean", "Good Afternoon"],
      "500": ["Dragon Crown", "You're Amazing", "Money Gun", "Gem Gun", "Manifesting"],
      "1000": ["Galaxy", "Drums", "Blooming Ribbons", "Glowing Jellyfish", "Watermelon Love"],
      "1500": ["Love Explosion", "Under Control", "Greeting Card", "Card to You", "Chasing the Dream"],
      "2000": ["Christmas Carousel", "Baby Dragon"],
      "5000": ["Silver Sports Car", "Ellie the Elephant", "Wanda the Witch", "Flying Jets", "Diamond Gun"],
      "10000": ["Interstellar", "Sunset Speedway", "Octopus", "Luxury Yacht"],
      "15000": ["Bob's Town", "Party On&On", "Rosa Nebula", "Future Journey", "Big Ben"],
      "20000": ["TikTok Shuttle", "Castle Fantasy"],
      "25999": ["Phoenix", "Adam's Dream", "Griffin"],
      "26999": ["Dragon Flame"],
      "29999": ["Lion", "Golden Sports Car"],
      "30000": ["Sam the Whale", "Gorilla"],
      "34000": ["Leon and Lion", "Zeus"],
      "34500": ["Seal and Whale"],
      "39999": ["TikTok Stars"],
      "41999": ["Fire Phoenix"],
      "42999": ["Pegasus"],
      "44999": ["TikTok Universe"]
    },
    "Grupo_B": {
      "1": ["GG", "Lightning Bolt", "Hi July", "Football"],
      "5": ["Fire", "Mic", "Pandas", "Hi", "Finger Heart", "Chic", "Duckling"],
      "10": ["Festive Potato", "Little Ghost", "Friendship Necklace", "Tiny Dino", "Cheer You Up", "Pretzel"],
      "20": ["S Flower"],
      "99": ["Flowers", "Super GG", "Love Painting", "Little Crown", "Birthday"],
      "199": ["Hearts", "Potato in Paris", "Hanging Lights", "Night Star", "Headphones"],
      "299": ["Butterfly for You", "Paddington Hat", "Elf's Hat", "Dancing Flower", "Boxing Gloves"],
      "399": ["Good Morning", "Beating Heart", "Coral", "Hands Up", "Sage the Smart Bean"],
      "500": ["DJ Glasses", "Star Map Polaris", "VR Goggles", "Swan"],
      "1000": ["Gerry the Giraffe", "Shiny Air Balloon", "Fireworks", "Diamond Tree"],
      "1500": ["Future Encounter", "Shooting Stars", "Here We Go"],
      "2000": ["Red Telephone Box", "Whale Diving"],
      "5000": ["Santa's Express", "Hands Up High", "Future City", "Work Hard Play Harder"],
      "10000": ["Fly Love", "Sports Car"],
      "15000": ["Amusement Park", "Fly Love"],
      "20000": ["Party Boat"],
      "25999": ["Dragon Flame"],
      "26999": ["Lion"],
      "29999": ["Golden Sports Car"],
      "30000": ["Sam the Whale", "Gorilla"],
      "34000": ["Leon and Lion", "Zeus"],
      "34500": ["Seal and Whale"],
      "39999": ["Thunder Falcon"],
      "41999": ["Fire Phoenix"],
      "42999": ["Pegasus"],
      "44999": ["TikTok Universe"]
    }
  };

  // Mapeo directo para regalos específicos a su valor y grupo
  // Útil para coincidencias exactas y rápidas
  final Map<String, Map<String, dynamic>> _directGiftMapping = {
    "rose": {"grupo": "Grupo_A", "valor": 1}, //revisado
    "gg": {"grupo": "Grupo_B", "valor": 1}, //revisado

    "fire": {"grupo": "Grupo_B", "valor": 5},
    "Mic": {"grupo": "Grupo_B", "valor": 5}, //revisado
    "finger heart": {"grupo": "Grupo_A", "valor": 5}, //revisado
    "ice cream cone": {"grupo": "Grupo_A", "valor": 5}, //revisado

    "pretzel": {"grupo": "Grupo_B", "valor": 10}, //revisado
    "sausage": {"grupo": "Grupo_A", "valor": 10}, //revisado

    "s flower": {"grupo": "Grupo_B", "valor": 20}, //revisado
    "cake": {"grupo": "Grupo_A", "valor": 20}, //revisado
    

    "birthday": {"grupo": "Grupo_B", "valor": 99}, //revisado
    "level-up sparks": {"grupo": "Grupo_A", "valor": 99}, //revisado
  };

  // Mapeo de nombres de regalo a su grupo y valor
  final Map<String, Map<String, dynamic>> _giftLookup = {};

  // Constructor que preprocesa los datos para búsqueda rápida
  TikTokGiftClassifier() {
    _inicializarBusquedaRegalos();
  }

  // Inicializa el mapeo para buscar regalos rápidamente
  void _inicializarBusquedaRegalos() {
    AppLogger.info('Inicializando mapeo de regalos de TikTok', name: 'TikTokGiftClassifier');
    int totalRegalos = 0;
    
    // Primero agregar los mapeos directos para asegurar prioridad
    _directGiftMapping.forEach((regalo, info) {
      _giftLookup[regalo.toLowerCase()] = info;
      totalRegalos++;
    });
    
    // Luego agregar los del mapeo general
    _giftGroups.forEach((grupo, valoresRegalos) {
      valoresRegalos.forEach((valor, regalos) {
        for (var regalo in regalos) {
          final nombreNormalizado = regalo.toLowerCase();
          // Solo agregar si no existe ya en el mapeo directo
          if (!_giftLookup.containsKey(nombreNormalizado)) {
            _giftLookup[nombreNormalizado] = {
              'grupo': grupo,
              'valor': int.parse(valor)
            };
            totalRegalos++;
          }
        }
      });
    });
    
    AppLogger.info('Mapeo de regalos completado. Total: $totalRegalos regalos registrados', name: 'TikTokGiftClassifier');
  }

  // Obtiene información de un regalo: grupo y valor en puntos
  Map<String, dynamic>? clasificarRegalo(String nombreRegalo) {
    // Normalizar el nombre del regalo para búsqueda
    final nombreNormalizado = nombreRegalo.toLowerCase().trim();
    
    AppLogger.info('Buscando regalo: "$nombreRegalo" (normalizado: "$nombreNormalizado")', name: 'TikTokGiftDebug');
    
    // Intentar buscar en el mapeo directo primero (más rápido)
    final directMatch = _directGiftMapping[nombreNormalizado];
    if (directMatch != null) {
      AppLogger.info('Regalo encontrado en mapeo directo: ${directMatch['grupo']} - ${directMatch['valor']} puntos', name: 'TikTokGiftDebug');
      return directMatch;
    }
    
    // Buscar en el mapeo completo
    final resultado = _giftLookup[nombreNormalizado];
    
    if (resultado != null) {
      AppLogger.info('Regalo encontrado en la clasificación: ${resultado['grupo']} - ${resultado['valor']} puntos', name: 'TikTokGiftDebug');
      return resultado;
    } else {
      AppLogger.warning('Regalo NO encontrado en la clasificación: "$nombreRegalo"', name: 'TikTokGiftDebug');
      
      // Intentar búsqueda aproximada
      for (var entry in _giftLookup.entries) {
        if (entry.key.contains(nombreNormalizado) || nombreNormalizado.contains(entry.key)) {
          AppLogger.info('Posible coincidencia aproximada: "${entry.key}" para "$nombreNormalizado"', name: 'TikTokGiftDebug');
        }
      }
    }
    
    return resultado;
  }

  // Determina a qué contendiente corresponde un grupo
  int obtenerContendienteDeGrupo(String grupo) {
    return grupo == "Grupo_A" ? 1 : 2;
  }

  // Procesa un regalo de TikTok y devuelve un mapa con la información procesada
  Map<String, dynamic> procesarRegalo(String nombreRegalo, int diamondCount) {
    AppLogger.info('Procesando regalo: "$nombreRegalo" con $diamondCount diamantes', name: 'TikTokGiftDebug');
    
    // Normalizar el nombre para buscar (convertir a minúsculas para mayor compatibilidad)
    final nombreNormalizado = nombreRegalo.toLowerCase().trim();
    
    // Intentar clasificar el regalo por nombre
    final infoRegalo = clasificarRegalo(nombreNormalizado);
    
    // Si tenemos un valor de diamantes válido pero no encontramos el regalo,
    // podemos confiar en el valor de diamantes para asignarlo directamente
    if (infoRegalo == null && diamondCount > 0) {
      // Determinar grupo basado en el valor de diamantes
      final String grupo = _determinarGrupoPorDiamantes(diamondCount);
      
      AppLogger.info(
        'Usando diamondCount directo para clasificar: "$nombreRegalo" ($diamondCount) -> grupo $grupo',
        name: 'TikTokGiftDebug'
      );
      
      final resultado = {
        'grupo': grupo,
        'valor': diamondCount,
        'contendienteId': obtenerContendienteDeGrupo(grupo),
        'clasificado': false
      };
      
      AppLogger.info(
        'Regalo clasificado por diamantes: "$nombreRegalo" ($diamondCount) -> ${resultado['grupo']}, ${resultado['valor']} puntos, contendiente ${resultado['contendienteId']}',
        name: 'TikTokGiftDebug'
      );
      
      return resultado;
    } else if (infoRegalo != null) {
      // Si encontramos el regalo en nuestra clasificación
      final resultado = {
        'grupo': infoRegalo['grupo'],
        'valor': infoRegalo['valor'],
        'contendienteId': obtenerContendienteDeGrupo(infoRegalo['grupo']),
        'clasificado': true
      };
      
      AppLogger.info(
        'Regalo clasificado por nombre: "$nombreRegalo" -> ${resultado['grupo']}, ${resultado['valor']} puntos, contendiente ${resultado['contendienteId']}',
        name: 'TikTokGiftDebug'
      );
      
      return resultado;
    } else {
      // Si no encontramos el regalo y el diamondCount es 0, usamos valor por defecto
      final String grupo = _determinarGrupoPorNombre(nombreRegalo);
      final resultado = {
        'grupo': grupo,
        'valor': diamondCount > 0 ? diamondCount : 1, // Valor mínimo de 1 para que sume algo
        'contendienteId': obtenerContendienteDeGrupo(grupo),
        'clasificado': false
      };
      
      AppLogger.info(
        'Regalo clasificado por nombre fallback: "$nombreRegalo" -> ${resultado['grupo']}, ${resultado['valor']} puntos, contendiente ${resultado['contendienteId']}',
        name: 'TikTokGiftDebug'
      );
      
      return resultado;
    }
  }

  // Determina el grupo basado en el valor de diamantes cuando no encontramos el regalo en nuestra lista
  String _determinarGrupoPorDiamantes(int diamondCount) {
    // Asignación aleatoria en lugar de basarse en el valor
    final random = Random();
    final grupo = random.nextBool() ? "Grupo_A" : "Grupo_B";
    
    AppLogger.info('Asignando grupo aleatoriamente por valor de diamantes: $diamondCount -> $grupo', name: 'TikTokGiftDebug');
    
    return grupo;
  }
  
  // Determina el grupo basado en el nombre del regalo
  String _determinarGrupoPorNombre(String nombre) {
    // Selección aleatoria entre Grupo_A y Grupo_B
    final random = Random();
    final grupo = random.nextBool() ? "Grupo_A" : "Grupo_B";
    
    AppLogger.info('Asignando grupo aleatoriamente para regalo no clasificado: "$nombre" -> $grupo', name: 'TikTokGiftDebug');
    
    return grupo;
  }
} 