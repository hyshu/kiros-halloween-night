import 'package:flutter/material.dart';

import 'scene/grid_scene_manager.dart';
import 'rendering/grid_renderer.dart';
import 'core/world_generator.dart';
import 'core/tile_map.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Kiro's Ghost Roguelike",
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  late GridSceneManager _sceneManager;
  late TileMap _tileMap;
  bool _isLoading = true;
  String _loadingStatus = 'Generating world...';

  @override
  void initState() {
    super.initState();
    _initializeWorldMap();
  }

  Future<void> _initializeWorldMap() async {
    setState(() {
      _loadingStatus = 'Generating 500x1000 world map...';
    });

    // Generate the large world map
    final worldGenerator = WorldGenerator(seed: 42);
    _tileMap = worldGenerator.generateWorld();

    setState(() {
      _loadingStatus = 'Initializing scene manager...';
    });

    // Create scene manager with the large world
    _sceneManager = GridSceneManager.withTileMap(_tileMap);

    setState(() {
      _loadingStatus = 'Loading world objects...';
    });

    // Initialize the scene with the generated world
    await _sceneManager.initializeWithTileMap(_tileMap);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              Text(
                _loadingStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This may take a moment for the large world...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: GridRenderer(
        backgroundColor: const Color(0xFF050510),
        sceneManager: _sceneManager,
      ),
    );
  }
}
