# Clasificación de Regalos TikTok - Battle Live

Este documento describe la implementación del sistema de clasificación de regalos de TikTok en la aplicación Battle Live.

## Funcionamiento

El sistema clasifica los regalos de TikTok en dos grupos (Grupo_A y Grupo_B) y asigna puntos basados en el valor de diamantes de cada regalo. Cada grupo corresponde a un contendiente (1 o 2) en la batalla.

### Clasificación de Regalos

Los regalos se clasifican según su nombre y valor en diamantes:

- Los regalos del **Grupo_A** suman puntos para el **Contendiente 1**
- Los regalos del **Grupo_B** suman puntos para el **Contendiente 2**

Si un regalo no está en la lista de regalos conocidos, se clasifica automáticamente según su valor en diamantes.

## Archivos Implementados

1. **TikTokGiftClassifier** (`lib/services/tiktok_gift_classifier.dart`)
   - Servicio que clasifica los regalos en grupos y asigna puntos
   - Contiene el mapeo de regalos por grupo y valor

2. **TikTokService** (`lib/services/tiktok_service.dart`)
   - Modificado para usar el clasificador de regalos
   - Mantiene un contador de puntos por contendiente

3. **ActivarLivePage** (`lib/presentation/pages/activar_live_page.dart`)
   - Integra el servicio TikTok para mostrar los contadores
   - Proporciona una interfaz para conectarse a streams de TikTok

## Mapeo de Regalos

El sistema utiliza un mapeo de regalos por grupo y valor en diamantes. Ejemplos:

### Grupo A (Contendiente 1)
- **1 punto**: Rose, GG, Coffee, etc.
- **5 puntos**: Finger Heart, Chic, Duckling, etc.
- **10 puntos**: Dolphin, Rosa, Christmas Wreath, etc.
- (Más valores en el código)

### Grupo B (Contendiente 2)
- **1 punto**: Flame Heart, Lightning Bolt, Mini Speaker, etc.
- **5 puntos**: Pandas, Hi, Finger Heart, etc.
- **10 puntos**: Festive Potato, Little Ghost, etc.
- (Más valores en el código)

## Uso

1. En la página `ActivarLivePage`, conectarse a un usuario TikTok ingresando su nombre
2. Los puntos se acumularán automáticamente según los regalos recibidos
3. Los contadores mostrarán los puntos por contendiente
4. Se puede reiniciar los contadores con el botón correspondiente

## Personalización

El mapeo de regalos se puede actualizar modificando la variable `_giftGroups` en la clase `TikTokGiftClassifier`. 