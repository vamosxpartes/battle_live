import 'package:flutter/material.dart';

class ActivarLivePage extends StatelessWidget {
  const ActivarLivePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulación de datos hardcodeados de esqueletos guardados
    final List<Map<String, dynamic>> esqueletosSimulados = [
      {
        'id': '1',
        'titulo': 'Gran Final 2023',
        'contendiente1': 'Equipo Alpha',
        'contendiente2': 'Equipo Omega',
        'fechaCreacion': '12/05/2023',
      },
      {
        'id': '2',
        'titulo': 'Semifinal Torneo Regional',
        'contendiente1': 'Los Tigres',
        'contendiente2': 'Las Águilas',
        'fechaCreacion': '15/06/2023',
      },
      {
        'id': '3',
        'titulo': 'Concurso de Talentos',
        'contendiente1': 'Grupo A',
        'contendiente2': 'Grupo B',
        'fechaCreacion': '22/07/2023',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activar Live'),
      ),
      body: esqueletosSimulados.isEmpty
          ? const Center(child: Text('No hay esqueletos guardados'))
          : ListView.builder(
              itemCount: esqueletosSimulados.length,
              itemBuilder: (context, index) {
                final esqueleto = esqueletosSimulados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(esqueleto['titulo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${esqueleto['contendiente1']} vs ${esqueleto['contendiente2']}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Implementar activación real del live
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Activando ${esqueleto['titulo']}...')),
                        );
                      },
                      child: const Text('Activar'),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(esqueleto['titulo']),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Contendiente 1: ${esqueleto['contendiente1']}'),
                                const SizedBox(height: 8),
                                Text('Contendiente 2: ${esqueleto['contendiente2']}'),
                                const SizedBox(height: 8),
                                Text('Creado el: ${esqueleto['fechaCreacion']}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cerrar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // TODO: Implementar edición de esqueleto
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Función de edición en desarrollo')),
                                  );
                                },
                                child: const Text('Editar'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
} 