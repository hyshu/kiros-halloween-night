import 'package:flutter/foundation.dart';
import 'game_state.dart';
import 'position.dart';
import 'tile_type.dart';

/// Central manager for the roguelike game
class GameManager extends ChangeNotifier {
  /// The current game state
  final GameState _gameState = GameState();
  
  /// Singleton instance
  static GameManager? _instance;
  
  /// Private constructor for singleton pattern
  GameManager._();
  
  /// Gets the singleton instance
  static GameManager get instance {
    _instance ??= GameManager._();
    return _instance!;
  }

  /// Gets the current game state
  GameState get gameState => _gameState;

  /// Initializes the game manager
  Future<void> initialize() async {
    _gameState.setPhase(GamePhase.initializing);
    
    // Initialize core systems here
    // This will be expanded in future tasks
    
    notifyListeners();
  }

  /// Starts a new game
  Future<void> startNewGame() async {
    _gameState.resetGame();
    await initialize();
    _gameState.startGame();
    notifyListeners();
  }

  /// Handles player input for movement
  bool handlePlayerMovement(Position newPosition) {
    if (!_gameState.canCharactersMove) return false;
    
    final player = _gameState.playerCharacter;
    if (player == null) return false;
    
    // Basic movement validation (will be expanded with collision detection)
    if (player.moveTo(newPosition)) {
      _gameState.nextTurn();
      notifyListeners();
      return true;
    }
    
    return false;
  }

  /// Updates the game state (called each frame)
  void update(double deltaTime) {
    if (!_gameState.isRunning) return;
    
    // Update active characters
    final activeCharacters = _gameState.getActiveCharacters();
    for (final character in activeCharacters) {
      // Character update logic will be implemented in future tasks
      // For now, just ensure character is properly initialized
      character.setIdle();
    }
    
    // Check for game end conditions
    _checkGameEndConditions();
  }

  /// Checks if the game should end
  void _checkGameEndConditions() {
    final player = _gameState.playerCharacter;
    if (player == null || !player.isAlive) {
      _gameState.endGameWithDefeat();
      return;
    }
    
    // Victory conditions will be implemented in future tasks
  }

  /// Validates if a position is valid for movement
  bool isValidPosition(Position position) {
    // Basic bounds checking - will be expanded with world map
    // For now, just ensure position is not negative
    return position.x >= 0 && position.z >= 0;
  }

  /// Gets the tile type at a specific position
  TileType getTileTypeAt(Position position) {
    // Placeholder implementation - will be replaced with actual world map
    if (!isValidPosition(position)) {
      return TileType.wall;
    }
    
    return TileType.floor;
  }

  /// Checks if a position blocks movement
  bool isPositionBlocked(Position position) {
    final tileType = getTileTypeAt(position);
    if (tileType.blocksMovement) return true;
    
    // Check if any character is at this position
    final charactersAtPosition = _gameState.getCharactersAt(position);
    return charactersAtPosition.isNotEmpty;
  }

  /// Disposes of the game manager
  @override
  void dispose() {
    _gameState.dispose();
    super.dispose();
  }
}