import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/ghost_character.dart';
import '../core/tile_map.dart';
import '../scene/grid_scene_manager.dart';

/// Manages keyboard input for the game
class InputManager {
  final GhostCharacter _ghostCharacter;
  final TileMap? _tileMap;
  final GridSceneManager? _sceneManager;

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
       _sceneManager = sceneManager;

  /// Handles a key press event
  /// Returns true if the key was handled
  Future<bool> handleKeyPress(LogicalKeyboardKey key) async {
    final enemyManager = _sceneManager?.enemyManager;
    final wasHandled = _ghostCharacter.handleInput(
      key,
      _tileMap,
      enemyManager: enemyManager,
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
}
