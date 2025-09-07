import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/ghost_character.dart';
import '../core/tile_map.dart';

/// Manages keyboard input for the game
class InputManager {
  final GhostCharacter _ghostCharacter;
  final TileMap? _tileMap;

  /// Callback for when the character moves successfully
  final VoidCallback? onCharacterMoved;

  InputManager({
    required GhostCharacter ghostCharacter,
    TileMap? tileMap,
    this.onCharacterMoved,
  }) : _ghostCharacter = ghostCharacter,
       _tileMap = tileMap;

  /// Handles a key press event
  /// Returns true if the key was handled
  bool handleKeyPress(LogicalKeyboardKey key) {
    final wasHandled = _ghostCharacter.handleInput(key, _tileMap);

    if (wasHandled && !_ghostCharacter.isIdle) {
      // Character moved successfully
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
