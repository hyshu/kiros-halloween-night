import 'package:flutter/material.dart';

import 'scene/grid_scene_manager.dart';
import 'rendering/grid_renderer.dart';
import 'core/world_generator.dart';
import 'core/tile_map.dart';
import 'core/ghost_character.dart';
import 'core/position.dart';
import 'managers/input_manager.dart';
import 'managers/model_manager.dart';
import 'widgets/dialogue_ui.dart';
import 'widgets/inventory_ui.dart';
import 'widgets/gift_ui.dart';
import 'l10n/strings.g.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();
  runApp(TranslationProvider(child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (_) => t.game.title,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    locale: TranslationProvider.of(context).flutterLocale,
    supportedLocales: AppLocale.values.map((locale) => locale.flutterLocale),
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
  late GhostCharacter _ghostCharacter;
  late InputManager _inputManager;
  bool _isLoading = true;
  String _loadingStatus = '';
  bool _showInventory = false;

  @override
  void initState() {
    super.initState();
    _initializeWorldMap();
  }

  Future<void> _initializeWorldMap() async {
    final totalStopwatch = Stopwatch()..start();
    
    setState(() {
      _loadingStatus = 'Preloading common 3D models...';
    });

    // Preload common models to improve performance
    final preloadStopwatch = Stopwatch()..start();
    final modelManager = ModelManager();
    await modelManager.preloadCommonModels();
    preloadStopwatch.stop();
    debugPrint('Model preloading: ${preloadStopwatch.elapsedMilliseconds}ms');
    
    setState(() {
      _loadingStatus = 'Generating 200x400 world map...';
    });

    // Generate the large world map
    final worldGenStopwatch = Stopwatch()..start();
    final worldGenerator = WorldGenerator(seed: 42);
    _tileMap = worldGenerator.generateWorld();
    worldGenStopwatch.stop();
    debugPrint('World generation: ${worldGenStopwatch.elapsedMilliseconds}ms');

    setState(() {
      _loadingStatus = 'Initializing scene manager...';
    });

    // Create scene manager with the large world
    final sceneManagerStopwatch = Stopwatch()..start();
    _sceneManager = GridSceneManager.withTileMap(_tileMap);
    sceneManagerStopwatch.stop();
    debugPrint('Scene manager creation: ${sceneManagerStopwatch.elapsedMilliseconds}ms');

    setState(() {
      _loadingStatus = 'Loading world objects...';
    });

    // Initialize the scene with the generated world
    final sceneInitStopwatch = Stopwatch()..start();
    await _sceneManager.initializeWithTileMap(_tileMap);
    sceneInitStopwatch.stop();
    debugPrint('Scene initialization: ${sceneInitStopwatch.elapsedMilliseconds}ms');

    setState(() {
      _loadingStatus = 'Creating Kiro ghost character...';
    });

    // Create the ghost character at the spawn position
    final ghostCharStopwatch = Stopwatch()..start();
    final spawnPosition = _tileMap.playerSpawn ?? const Position(10, 10);
    _ghostCharacter = GhostCharacter(
      id: 'kiro',
      position: spawnPosition,
      health: 100,
      maxHealth: 100,
    );

    // Add the ghost character to the scene
    await _sceneManager.addGhostCharacter(_ghostCharacter);
    ghostCharStopwatch.stop();
    debugPrint('Ghost character creation and adding: ${ghostCharStopwatch.elapsedMilliseconds}ms');

    setState(() {
      _loadingStatus = 'Spawning enemies across the world...';
    });

    // Spawn enemies across the world map
    final enemySpawnStopwatch = Stopwatch()..start();
    await _sceneManager.spawnEnemies(
      spawnDensity: 0.125, // 0.125 enemies per 100 tiles (approx 100 enemies)
      playerSpawn: spawnPosition,
    );
    enemySpawnStopwatch.stop();
    debugPrint('Enemy spawning: ${enemySpawnStopwatch.elapsedMilliseconds}ms');

    setState(() {
      _loadingStatus = 'Setting up input controls...';
    });

    // Create input manager
    final inputManagerStopwatch = Stopwatch()..start();
    _inputManager = InputManager(
      ghostCharacter: _ghostCharacter,
      tileMap: _tileMap,
      sceneManager: _sceneManager,
      onCharacterMoved: () {
        // Update the scene when character moves
        _sceneManager.updateGhostCharacterPosition();
      },
      onInventoryToggle: () {
        setState(() {
          _showInventory = !_showInventory;
        });
      },
      onGiftToggle: () {
        // Start gift process with first adjacent enemy - this shows the candy selection UI
        final adjacentEnemies = _sceneManager.gameLoopManager!.getAdjacentGiftableEnemies();
        if (adjacentEnemies.isNotEmpty) {
          final success = _sceneManager.gameLoopManager!.initiateGiftToEnemy(adjacentEnemies.first);
          if (success) {
            setState(() {
              _showInventory = false; // Close inventory if open
            });
          }
        } else {
          debugPrint('No adjacent enemies to give gifts to');
        }
      },
    );
    inputManagerStopwatch.stop();
    debugPrint('Input manager setup: ${inputManagerStopwatch.elapsedMilliseconds}ms');

    setState(() {
      _loadingStatus = 'Initializing combat systems...';
    });

    // Initialize game loop with combat system
    final gameLoopStopwatch = Stopwatch()..start();
    _sceneManager.initializeGameLoop();
    gameLoopStopwatch.stop();
    debugPrint('Game loop initialization: ${gameLoopStopwatch.elapsedMilliseconds}ms');

    totalStopwatch.stop();
    debugPrint('=== TOTAL INITIALIZATION TIME: ${totalStopwatch.elapsedMilliseconds}ms ===');

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
              const CircularProgressIndicator(color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(
                _loadingStatus,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Creating rooms and narrow corridors...',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _inputManager.createKeyboardListener(
        child: Stack(
          children: [
            GridRenderer(
              backgroundColor: const Color(0xFF050510),
              sceneManager: _sceneManager,
            ),
            DialogueUI(dialogueManager: _sceneManager.dialogueManager),
            if (_sceneManager.gameLoopManager?.giftSystem.isGiftUIActive == true)
              GiftOverlay(
                giftSystem: _sceneManager.gameLoopManager!.giftSystem,
                onConfirmGift: () {
                  _sceneManager.gameLoopManager!.confirmGift();
                  setState(() {});
                },
                onCancelGift: () {
                  _sceneManager.gameLoopManager!.cancelGift();
                  setState(() {});
                },
              ),
            if (_showInventory)
              InventoryOverlay(
                inventory: _ghostCharacter.inventory,
                onUseCandy: (candyId) {
                  _ghostCharacter.useCandy(candyId);
                  setState(() {}); // Refresh UI after using candy
                },
                onGiveCandy: (candyId) {
                  // Find adjacent giftable enemies
                  final adjacentEnemies = _sceneManager.gameLoopManager!.getAdjacentGiftableEnemies();
                  if (adjacentEnemies.isNotEmpty) {
                    // Directly give the selected candy to the first adjacent enemy
                    final targetEnemy = adjacentEnemies.first;
                    final success = _sceneManager.gameLoopManager!.initiateGiftToEnemy(targetEnemy);
                    if (success) {
                      // Find and select the candy that was chosen
                      final availableCandy = _sceneManager.gameLoopManager!.giftSystem.availableCandy;
                      final selectedCandy = availableCandy.firstWhere(
                        (candy) => candy.id == candyId,
                        orElse: () => availableCandy.first,
                      );
                      _sceneManager.gameLoopManager!.giftSystem.selectCandy(selectedCandy);
                      
                      // Immediately confirm the gift
                      _sceneManager.gameLoopManager!.confirmGift();
                      
                      setState(() {
                        _showInventory = false; // Close inventory
                      });
                    }
                  }
                },
                checkCanGiveToEnemies: () {
                  return _sceneManager.gameLoopManager?.canGiveGifts() ?? false;
                },
                onClose: () {
                  setState(() {
                    _showInventory = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
