import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart';

import 'character.dart';
import 'position.dart';
import 'tile_map.dart';
import 'tile_type.dart';

/// Represents the player-controlled ghost character Kiro
class GhostCharacter extends Character {
  /// List of allied characters following Kiro
  final List<Character> allies = [];
  
  /// Abilities granted by collected candy
  final Map<String, dynamic> abilities = {};
  
  /// Movement input state
  bool _isProcessingInput = false;
  
  /// Last movement direction for animation purposes
  Direction? lastMovementDirection;

  GhostCharacter({
    required String id,
    required Position position,
    int health = 100,
    int maxHealth = 100,
  }) : super(
          id: id,
          position: position,
          modelPath: 'assets/graveyard/character-ghost.obj',
          health: health,
          maxHealth: maxHealth,
          isActive: true,
          canMove: true,
          isIdle: true,
        );

  /// Handles keyboard input for movement
  /// Returns true if the key was recognized (regardless of movement success)
  bool handleInput(LogicalKeyboardKey key, TileMap? tileMap) {
    if (_isProcessingInput || !canMove) return false;
    
    Direction? direction;
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        direction = Direction.north;
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        direction = Direction.south;
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        direction = Direction.west;
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        direction = Direction.east;
        break;
      default:
        return false; // Key not handled
    }
    
    // Key was recognized, attempt movement
    attemptMove(direction, tileMap);
    return true; // Key was handled, regardless of movement success
  }
  
  /// Attempts to move in the specified direction
  /// Returns true if the move was successful
  bool attemptMove(Direction direction, TileMap? tileMap) {
    if (_isProcessingInput || !canMove) return false;
    
    _isProcessingInput = true;
    
    try {
      final newPosition = _getNewPosition(direction);
      
      // Validate movement with tile map if available
      if (tileMap != null) {
        if (!_canMoveTo(newPosition, tileMap)) {
          setIdle();
          return false;
        }
      }
      
      // Perform the movement
      final success = moveTo(newPosition);
      if (success) {
        lastMovementDirection = direction;
        setActive(); // Character is moving, not idle
        _moveAllies(direction, tileMap);
      } else {
        setIdle();
      }
      
      return success;
    } finally {
      _isProcessingInput = false;
    }
  }
  
  /// Gets the new position based on direction
  Position _getNewPosition(Direction direction) {
    switch (direction) {
      case Direction.north:
        return position.add(0, -1);
      case Direction.south:
        return position.add(0, 1);
      case Direction.west:
        return position.add(-1, 0);
      case Direction.east:
        return position.add(1, 0);
    }
  }
  
  /// Checks if movement to the new position is valid
  bool _canMoveTo(Position newPosition, TileMap tileMap) {
    // Check bounds
    if (!tileMap.isValidPosition(newPosition)) {
      return false;
    }
    
    // Check tile type - can't move through walls or obstacles
    final tileType = tileMap.getTileAt(newPosition);
    switch (tileType) {
      case TileType.wall:
      case TileType.obstacle:
        return false;
      case TileType.floor:
      case TileType.candy:
        return true;
    }
  }
  
  /// Moves all allied characters to follow Kiro
  void _moveAllies(Direction direction, TileMap? tileMap) {
    // For now, allies will be implemented in a future task
    // This is a placeholder for the ally following system
  }
  
  /// Adds an ability from collected candy
  void addAbility(String abilityName, dynamic value) {
    abilities[abilityName] = value;
    
    // Apply ability effects
    switch (abilityName) {
      case 'healthBoost':
        if (value is int) {
          heal(value);
        }
        break;
      case 'speedIncrease':
        // Speed increase would be handled in movement timing
        break;
      case 'maxHealthIncrease':
        if (value is int) {
          // This would require modifying the base Character class
          // For now, just store the ability
        }
        break;
    }
  }
  
  /// Removes an ability (when candy effect expires or is consumed)
  void removeAbility(String abilityName) {
    abilities.remove(abilityName);
  }
  
  /// Gets the current value of an ability
  T? getAbility<T>(String abilityName) {
    final value = abilities[abilityName];
    return value is T ? value : null;
  }
  
  /// Checks if the character has a specific ability
  bool hasAbility(String abilityName) {
    return abilities.containsKey(abilityName);
  }
  
  /// Sets the character to idle state with proper animation state
  @override
  void setIdle() {
    super.setIdle();
    lastMovementDirection = null;
  }
  
  /// Gets the current facing direction for animation purposes
  Direction? get facingDirection => lastMovementDirection;
  
  /// Returns true if the character is currently moving
  bool get isMoving => !isIdle && _isProcessingInput;
  
  @override
  String toString() => 'GhostCharacter($id) at $position [Health: $health/$maxHealth, Abilities: ${abilities.keys.join(', ')}]';
}

/// Represents movement directions
enum Direction {
  north,
  south,
  east,
  west;
  
  /// Returns the opposite direction
  Direction get opposite {
    switch (this) {
      case Direction.north:
        return Direction.south;
      case Direction.south:
        return Direction.north;
      case Direction.east:
        return Direction.west;
      case Direction.west:
        return Direction.east;
    }
  }
  
  /// Returns a human-readable name
  String get displayName {
    switch (this) {
      case Direction.north:
        return 'North';
      case Direction.south:
        return 'South';
      case Direction.east:
        return 'East';
      case Direction.west:
        return 'West';
    }
  }
}