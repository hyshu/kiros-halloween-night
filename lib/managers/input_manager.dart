import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/character.dart';
import '../core/collision_detector.dart';
import '../core/ghost_character.dart';
import '../core/tile_map.dart';
import '../scene/grid_scene_manager.dart';

/// Manages keyboard input for the game
class InputManager {
  final GhostCharacter _ghostCharacter;
  final TileMap? _tileMap;
  final GridSceneManager? _sceneManager;
  CollisionDetector? _collisionDetector;

  /// Callback for when the character moves successfully
  final Future<void> Function()? onCharacterMoved;

  /// Callback for when inventory toggle is requested
  final VoidCallback? onInventoryToggle;

  /// Callback for when gift toggle is requested
  final VoidCallback? onGiftToggle;

  InputManager({
    required GhostCharacter ghostCharacter,
    TileMap? tileMap,
    GridSceneManager? sceneManager,
    this.onCharacterMoved,
    this.onInventoryToggle,
    this.onGiftToggle,
  }) : _ghostCharacter = ghostCharacter,
       _tileMap = tileMap,
       _sceneManager = sceneManager {
    // Initialize collision detector if we have a tile map and scene manager
    if (_tileMap != null && _sceneManager != null) {
      _initializeCollisionDetector();
    }
  }

  /// Handles a key press event
  /// Returns true if the key was handled
  Future<bool> handleKeyPress(LogicalKeyboardKey key) async {
    // Check if input should be blocked due to active animations
    if (_shouldBlockInput(key)) {
      debugPrint('InputManager: Blocking input due to active animations');
      return false; // Input blocked during animations
    }

    final enemyManager = _sceneManager?.enemyManager;
    final wasHandled = _ghostCharacter.handleInput(
      key,
      _tileMap,
      enemyManager: enemyManager,
      collisionDetector: _collisionDetector,
      onInventoryToggle: onInventoryToggle,
      onGiftToggle: onGiftToggle,
    );

    if (wasHandled && !_ghostCharacter.isIdle) {
      // Character moved successfully
      await onCharacterMoved?.call();
    } else if (wasHandled && _ghostCharacter.isIdle) {
      // Character attacked but didn't move, still trigger turn
      await onCharacterMoved?.call();
    }

    return wasHandled;
  }

  /// Creates a KeyboardListener widget that handles input
  Widget createKeyboardListener({
    required Widget child,
    bool autofocus = true,
  }) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: autofocus,
      onKeyEvent: (KeyEvent event) async {
        if (event is KeyDownEvent) {
          final handled = await handleKeyPress(event.logicalKey);
          if (handled) {
            // Prevent default behavior for handled keys
            return;
          }
        }
      },
      child: child,
    );
  }

  /// Updates the tile map reference (useful when world changes)
  void updateTileMap(TileMap? newTileMap) {
    // This would require making _tileMap mutable, but for now
    // we'll create a new InputManager when the tile map changes
  }

  /// Checks if input should be blocked due to active animations
  bool _shouldBlockInput(LogicalKeyboardKey key) {
    // Check AnimationPhaseManager for blocking animations
    final gameLoopManager = _sceneManager?.gameLoopManager;
    if (gameLoopManager != null) {
      final animationManager = gameLoopManager.animationManager;
      if (animationManager.isAnimating &&
          animationManager.currentPhase.blocksInput) {
        debugPrint(
          'InputManager: Blocking input due to AnimationPhaseManager '
          '(phase: ${animationManager.currentPhase})',
        );
        return true; // Block input during animation phases
      }
    }

    // Allow movement keys during character movement animations
    if (_isMovementKey(key)) {
      // Don't block movement keys - let them cancel current animations
      return false;
    }

    // Check character-level movement animations for non-movement keys
    final characterAnimationSystem = _ghostCharacter.animationSystem;
    if (characterAnimationSystem != null &&
        characterAnimationSystem.hasActiveAnimations) {
      debugPrint(
        'InputManager: Blocking non-movement input due to character movement animations',
      );
      return true; // Block non-movement input during character movement animations
    }

    // Check if character is already processing input
    if (_ghostCharacter.isProcessingInput) {
      debugPrint(
        'InputManager: Blocking input due to character processing input',
      );
      return true; // Block input if character is already processing input
    }

    return false; // Input is allowed
  }

  /// Checks if the given key is a movement key
  bool _isMovementKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyD;
  }

  /// Initializes the collision detector with all current characters
  void _initializeCollisionDetector() {
    if (_tileMap == null || _sceneManager == null) return;

    final allCharacters = <Character>[];

    // Add the player character
    allCharacters.add(_ghostCharacter);

    // Add enemies from enemy manager
    final enemyManager = _sceneManager.enemyManager;
    if (enemyManager != null) {
      allCharacters.addAll(enemyManager.activeEnemies);
    }

    // Note: Add allies when ally manager is available
    // final allyManager = _sceneManager!.allyManager;
    // if (allyManager != null) {
    //   allCharacters.addAll(allyManager.allies);
    // }

    _collisionDetector = CollisionDetector(
      tileMap: _tileMap,
      characters: allCharacters,
    );
  }

  /// Updates the collision detector when characters change
  void updateCollisionDetector() {
    if (_collisionDetector != null) {
      _initializeCollisionDetector(); // Reinitialize with current characters
    }
  }
}
