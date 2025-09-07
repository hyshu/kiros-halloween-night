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
  final VoidCallback? onCharacterMoved;

  InputManager({
    required GhostCharacter ghostCharacter,
    TileMap? tileMap,
    GridSceneManager? sceneManager,
    this.onCharacterMoved,
  }) : _ghostCharacter = ghostCharacter,
       _tileMap = tileMap,
       _sceneManager = sceneManager;

  /// Handles a key press event
  /// Returns true if the key was handled
  bool handleKeyPress(LogicalKeyboardKey key) {
    final enemyManager = _sceneManager?.enemyManager;
    final wasHandled = _ghostCharacter.handleInput(
      key,
      _tileMap,
      enemyManager: enemyManager,
    );

    if (wasHandled && !_ghostCharacter.isIdle) {
      // Character moved successfully
      onCharacterMoved?.call();
    } else if (wasHandled && _ghostCharacter.isIdle) {
      // Character attacked but didn't move, still trigger turn
      onCharacterMoved?.call();
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
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          final handled = handleKeyPress(event.logicalKey);
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
