import 'package:flutter/material.dart';

import 'entrenar_screen.dart';
import 'gimnasios_screen.dart';
import 'perfil_screen.dart';
import 'progreso_screen.dart';
import 'rutinas_screen.dart';

/// Pantalla principal con las pestañas de abajo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pestana = 0;

  @override
  Widget build(BuildContext context) {
    // Cada vez que cambias de pestaña la pantalla se vuelve a crear
    // y recarga sus datos (así el estado Premium y la XP siempre están al día).
    final pantallas = [
      const EntrenarScreen(),
      const RutinasScreen(),
      const ProgresoScreen(),
      const GimnasiosScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: pantallas[_pestana],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Entrenar',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Rutinas',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Gimnasios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
