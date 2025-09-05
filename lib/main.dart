import 'package:flutter/material.dart';

import 'scene/grid_scene_manager.dart';
import 'rendering/grid_renderer.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Kiro's Halloween Night",
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    home: const GridSceneView(),
  );
}

class GridSceneView extends StatefulWidget {
  const GridSceneView({super.key});

  @override
  State<GridSceneView> createState() => _GridSceneViewState();
}

class _GridSceneViewState extends State<GridSceneView> {
  final GridSceneManager _sceneManager = GridSceneManager();

  @override
  void initState() {
    super.initState();
    _initializeScene();
  }

  void _initializeScene() {
    final pattern = [
      [
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
      ],
      ['fence', null, null, 'grave', null, null, 'grave', null, null, 'fence'],
      ['fence', null, 'tree', null, null, null, null, 'tree', null, 'fence'],
      [
        'fence',
        'grave',
        null,
        null,
        'crypt',
        null,
        null,
        null,
        'grave',
        'fence',
      ],
      ['fence', null, null, null, null, null, null, null, null, 'fence'],
      ['fence', null, null, 'zombie', null, null, 'ghost', null, null, 'fence'],
      ['fence', 'grave', null, null, null, null, null, null, 'grave', 'fence'],
      [
        'fence',
        null,
        'tree',
        null,
        'skeleton',
        null,
        null,
        'tree',
        null,
        'fence',
      ],
      [
        'fence',
        null,
        null,
        'grave',
        null,
        null,
        'grave',
        null,
        'lantern',
        'fence',
      ],
      [
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
        'fence',
      ],
    ];

    _sceneManager.initializeWithPattern(pattern);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: GridRenderer(
        backgroundColor: const Color(0xFF050510),
        sceneManager: _sceneManager,
      ),
    );
  }
}
