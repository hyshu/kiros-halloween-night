import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/start_screen.dart';
import '../screens/game_over_screen.dart';
import '../scene/grid_scene_manager.dart';
import '../rendering/grid_renderer.dart';
import '../core/world_generator.dart';
import '../core/tile_map.dart';
import '../core/ghost_character.dart';
import '../core/position.dart';
import '../managers/input_manager.dart';
import '../managers/model_manager.dart';
import '../widgets/dialogue_ui.dart';
import '../widgets/inventory_ui.dart';
import '../widgets/gift_ui.dart';
import '../widgets/story_dialogue.dart';

enum AppScreen { start, story, game, gameOver }

enum GameResult { victory, defeat }

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppScreen _currentScreen = AppScreen.start;

  // Game state
  GridSceneManager? _sceneManager;
  TileMap? _tileMap;
  GhostCharacter? _ghostCharacter;
  InputManager? _inputManager;
  bool _isLoading = false;
  String _loadingStatus = '';
  bool _showInventory = false;
  Position? _previousPlayerPosition;

  // Game statistics for game over screen
  int _candyCollected = 0;
  int _enemiesDefeated = 0;
  int _candiesGiven = 0;
  Duration _survivalTime = Duration.zero;
  DateTime? _gameStartTime;
  GameResult _gameResult = GameResult.defeat;

  @override
  void initState() {
    super.initState();
    // Initialize game settings
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    // This will be called when settings are accessed
  }

  void _navigateToScreen(AppScreen screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  void _startGame() async {
    setState(() {
      _currentScreen = AppScreen.story;
    });
  }

  void _startActualGame() async {
    setState(() {
      _currentScreen = AppScreen.game;
      _isLoading = true;
      _gameStartTime = DateTime.now();
      _candyCollected = 0;
      _enemiesDefeated = 0;
      _candiesGiven = 0;
    });

    await _initializeWorldMap();
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  void _onGameOver({required bool isVictory}) {
    final endTime = DateTime.now();
    if (_gameStartTime != null) {
      _survivalTime = endTime.difference(_gameStartTime!);
    }

    _gameResult = isVictory ? GameResult.victory : GameResult.defeat;

    // Calculate statistics from current game state
    if (_ghostCharacter?.inventory != null) {
      _candyCollected = _ghostCharacter!.inventory.candyItems.length;
    }

    // Get statistics from scene manager if available
    if (_sceneManager?.gameLoopManager != null) {
      _enemiesDefeated = _sceneManager!.gameLoopManager!
          .getEnemiesDefeatedCount();
      _candiesGiven = _sceneManager!.gameLoopManager!.candiesGiven;
    }

    _navigateToScreen(AppScreen.gameOver);
  }

  void _resetGame() {
    setState(() {
      _sceneManager = null;
      _tileMap = null;
      _ghostCharacter = null;
      _inputManager = null;
      _previousPlayerPosition = null;
      _showInventory = false;
      _isLoading = false;
      _loadingStatus = '';
    });
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
      _loadingStatus = 'Generating 100x200 world map...';
    });

    // Generate the large world map
    final worldGenStopwatch = Stopwatch()..start();
    final worldGenerator = WorldGenerator(); // Use random seed for varied maps
    _tileMap = worldGenerator.generateWorld();
    worldGenStopwatch.stop();
    debugPrint('World generation: ${worldGenStopwatch.elapsedMilliseconds}ms');

    setState(() {
      _loadingStatus = 'Initializing scene manager...';
    });

    // Create scene manager with the large world
    final sceneManagerStopwatch = Stopwatch()..start();
    _sceneManager = GridSceneManager.withTileMap(_tileMap!);
    sceneManagerStopwatch.stop();
    debugPrint(
      'Scene manager creation: ${sceneManagerStopwatch.elapsedMilliseconds}ms',
    );

    setState(() {
      _loadingStatus = 'Loading world objects...';
    });

    // Initialize the scene with the generated world
    final sceneInitStopwatch = Stopwatch()..start();
    await _sceneManager!.initializeWithTileMap(_tileMap!);
    sceneInitStopwatch.stop();
    debugPrint(
      'Scene initialization: ${sceneInitStopwatch.elapsedMilliseconds}ms',
    );

    setState(() {
      _loadingStatus = 'Creating Kiro ghost character...';
    });

    // Create the ghost character at the spawn position
    final ghostCharStopwatch = Stopwatch()..start();
    final spawnPosition = _tileMap!.playerSpawn ?? const Position(10, 10);
    _ghostCharacter = GhostCharacter(
      id: 'kiro',
      position: spawnPosition,
      health: 100,
      maxHealth: 100,
    );

    // Add the ghost character to the scene
    await _sceneManager!.addGhostCharacter(_ghostCharacter!);

    // Initialize previous position for animation tracking
    _previousPlayerPosition = spawnPosition;

    ghostCharStopwatch.stop();
    debugPrint(
      'Ghost character creation and adding: ${ghostCharStopwatch.elapsedMilliseconds}ms',
    );

    setState(() {
      _loadingStatus = 'Spawning enemies across the world...';
    });

    // Spawn enemies across the world map
    final enemySpawnStopwatch = Stopwatch()..start();
    await _sceneManager!.spawnEnemies(
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
      ghostCharacter: _ghostCharacter!,
      tileMap: _tileMap!,
      sceneManager: _sceneManager!,
      onCharacterMoved: () async {
        // Capture the actual current position at the moment of movement call
        final currentPosition = _ghostCharacter!.position;
        final actualPreviousPosition = _previousPlayerPosition;

        // Update previous position BEFORE calling updateGhostCharacterPosition
        // to ensure the next movement has the correct starting position
        _previousPlayerPosition = currentPosition;

        // Update the scene when character moves
        await _sceneManager!.updateGhostCharacterPosition(
          fromPosition: actualPreviousPosition,
        );
      },
      onInventoryToggle: () {
        setState(() {
          _showInventory = !_showInventory;
        });
      },
      onGiftToggle: () {
        // Start gift process with first adjacent enemy - this shows the candy selection UI
        final adjacentEnemies = _sceneManager!.gameLoopManager!
            .getAdjacentGiftableEnemies();
        if (adjacentEnemies.isNotEmpty) {
          final success = _sceneManager!.gameLoopManager!.initiateGiftToEnemy(
            adjacentEnemies.first,
          );
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
    debugPrint(
      'Input manager setup: ${inputManagerStopwatch.elapsedMilliseconds}ms',
    );

    setState(() {
      _loadingStatus = 'Initializing combat systems...';
    });

    // Initialize game loop with combat system and spawn boss
    final gameLoopStopwatch = Stopwatch()..start();
    await _sceneManager!.initializeGameLoop();

    // Set up victory callback
    _sceneManager!.gameLoopManager!.onVictory = () {
      _onGameOver(isVictory: true);
    };

    // Set up defeat callback (if player dies)
    _sceneManager!.gameLoopManager!.onDefeat = () {
      _onGameOver(isVictory: false);
    };

    gameLoopStopwatch.stop();
    debugPrint(
      'Game loop initialization: ${gameLoopStopwatch.elapsedMilliseconds}ms',
    );

    totalStopwatch.stop();
    debugPrint(
      '=== TOTAL INITIALIZATION TIME: ${totalStopwatch.elapsedMilliseconds}ms ===',
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AppScreen.start:
        return StartScreen(onStartGame: _startGame, onExit: _exitApp);

      case AppScreen.story:
        return StoryDialogue(onContinue: _startActualGame);

      case AppScreen.game:
        return _buildGameScreen();

      case AppScreen.gameOver:
        return GameOverScreen(
          isVictory: _gameResult == GameResult.victory,
          candyCollected: _candyCollected,
          enemiesDefeated: _enemiesDefeated,
          candiesGiven: _candiesGiven,
          survivalTime: _survivalTime,
          onRestart: () {
            _resetGame();
            _startActualGame();
          },
          onMainMenu: () {
            _resetGame();
            _navigateToScreen(AppScreen.start);
          },
        );
    }
  }

  Widget _buildGameScreen() {
    if (_isLoading || _sceneManager == null || _ghostCharacter == null) {
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
              const Text(
                'Creating rooms and narrow corridors...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _inputManager!.createKeyboardListener(
        child: Stack(
          children: [
            GridRenderer(
              backgroundColor: const Color(0xFF050510),
              sceneManager: _sceneManager!,
            ),
            DialogueUI(dialogueManager: _sceneManager!.dialogueManager),
            if (_sceneManager!.gameLoopManager?.giftSystem.isGiftUIActive ==
                true)
              GiftOverlay(
                giftSystem: _sceneManager!.gameLoopManager!.giftSystem,
                onConfirmGift: () {
                  _sceneManager!.gameLoopManager!.confirmGift();
                  setState(() {});
                },
                onCancelGift: () {
                  _sceneManager!.gameLoopManager!.cancelGift();
                  setState(() {});
                },
              ),
            if (_showInventory)
              InventoryOverlay(
                inventory: _ghostCharacter!.inventory,
                onUseCandy: (candyId) {
                  _ghostCharacter!.useCandy(candyId);
                  setState(() {}); // Refresh UI after using candy
                },
                onGiveCandy: (candyId) {
                  // Find adjacent giftable enemies
                  final adjacentEnemies = _sceneManager!.gameLoopManager!
                      .getAdjacentGiftableEnemies();
                  if (adjacentEnemies.isNotEmpty) {
                    // Directly give the selected candy to the first adjacent enemy
                    final targetEnemy = adjacentEnemies.first;
                    final success = _sceneManager!.gameLoopManager!
                        .initiateGiftToEnemy(targetEnemy);
                    if (success) {
                      // Find and select the candy that was chosen
                      final availableCandy = _sceneManager!
                          .gameLoopManager!
                          .giftSystem
                          .availableCandy;
                      final selectedCandy = availableCandy.firstWhere(
                        (candy) => candy.id == candyId,
                        orElse: () => availableCandy.first,
                      );
                      _sceneManager!.gameLoopManager!.giftSystem.selectCandy(
                        selectedCandy,
                      );

                      // Immediately confirm the gift
                      _sceneManager!.gameLoopManager!.confirmGift();

                      setState(() {
                        _showInventory = false; // Close inventory
                      });
                    }
                  }
                },
                checkCanGiveToEnemies: () {
                  return _sceneManager!.gameLoopManager?.canGiveGifts() ??
                      false;
                },
                onClose: () {
                  setState(() {
                    _showInventory = false;
                  });
                },
              ),

            // Map coordinates display (positioned at bottom to avoid dialogue overlap)
            Positioned(
              bottom: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.deepPurple.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'X: ${_ghostCharacter!.position.x}, Z: ${_ghostCharacter!.position.z}, ←↓↑→: Move, i: Show Candy menu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // HP bar display (positioned at bottom to avoid dialogue overlap)
            Positioned(
              bottom: 40,
              right: 20,
              child: StatefulBuilder(
                builder: (context, setHPState) {
                  return StreamBuilder<void>(
                    stream: Stream.periodic(const Duration(milliseconds: 100)),
                    builder: (context, snapshot) {
                      return Container(
                        width: 200,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.deepPurple.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'HP: ${_ghostCharacter!.health}/${_ghostCharacter!.maxHealth}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                widthFactor:
                                    (_ghostCharacter!.health /
                                            _ghostCharacter!.maxHealth)
                                        .clamp(0.0, 1.0),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _ghostCharacter!.health >
                                            _ghostCharacter!.maxHealth * 0.3
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
