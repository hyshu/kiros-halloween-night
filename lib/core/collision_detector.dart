import 'character.dart';
import 'enemy_character.dart';
import 'position.dart';
import 'tile_map.dart';
import 'tile_type.dart';

/// Handles collision detection for all characters in the game
class CollisionDetector {
  /// The tile map to check collisions against
  final TileMap tileMap;

  /// List of all characters in the game for character-to-character collision
  final List<Character> characters;

  CollisionDetector({required this.tileMap, required this.characters});

  /// Checks if a character can move to the specified position
  bool canMoveTo(Character character, Position newPosition) {
    // Check bounds
    if (!tileMap.isValidPosition(newPosition)) {
      return false;
    }

    // Check tile walkability
    if (!tileMap.isWalkable(newPosition)) {
      return false;
    }

    // Check character-to-character collision
    if (hasCharacterCollision(character, newPosition)) {
      return false;
    }

    return true;
  }

  /// Checks if there's a character collision at the specified position
  bool hasCharacterCollision(Character movingCharacter, Position position) {
    for (final character in characters) {
      // Skip the moving character itself
      if (character.id == movingCharacter.id) continue;

      // Skip inactive characters
      if (!character.isActive) continue;

      // Check if another character is at this position
      if (character.position == position) {
        return true;
      }
    }
    return false;
  }

  /// Gets all characters at the specified position
  List<Character> getCharactersAt(Position position) {
    return characters
        .where(
          (character) => character.isActive && character.position == position,
        )
        .toList();
  }

  /// Gets all characters within a certain radius of a position
  List<Character> getCharactersInRadius(Position center, int radius) {
    return characters
        .where(
          (character) =>
              character.isActive &&
              character.position.distanceTo(center) <= radius,
        )
        .toList();
  }

  /// Gets all enemies within a certain radius of a position
  List<EnemyCharacter> getEnemiesInRadius(Position center, int radius) {
    return characters
        .whereType<EnemyCharacter>()
        .where(
          (enemy) =>
              enemy.isActive && enemy.position.distanceTo(center) <= radius,
        )
        .toList();
  }

  /// Gets all hostile enemies within a certain radius of a position
  List<EnemyCharacter> getHostileEnemiesInRadius(Position center, int radius) {
    return getEnemiesInRadius(
      center,
      radius,
    ).where((enemy) => enemy.isHostile).toList();
  }

  /// Gets all ally enemies within a certain radius of a position
  List<EnemyCharacter> getAllyEnemiesInRadius(Position center, int radius) {
    return getEnemiesInRadius(
      center,
      radius,
    ).where((enemy) => enemy.isAlly).toList();
  }

  /// Checks if there's a clear line of sight between two positions
  bool hasLineOfSight(Position from, Position to) {
    // Simple line of sight check using Bresenham-like algorithm
    final dx = (to.x - from.x).abs();
    final dz = (to.z - from.z).abs();

    if (dx == 0 && dz == 0) return true; // Same position

    final stepX = from.x < to.x ? 1 : -1;
    final stepZ = from.z < to.z ? 1 : -1;

    var currentX = from.x;
    var currentZ = from.z;
    var error = dx - dz;

    while (currentX != to.x || currentZ != to.z) {
      final currentPos = Position(currentX, currentZ);

      // Skip the starting position
      if (currentPos != from) {
        // Check if this position blocks line of sight
        if (tileMap.blocksMovement(currentPos)) {
          return false;
        }
      }

      final error2 = error * 2;

      if (error2 > -dz) {
        error -= dz;
        currentX += stepX;
      }

      if (error2 < dx) {
        error += dx;
        currentZ += stepZ;
      }
    }

    return true;
  }

  /// Gets the movement result for attempting to move a character
  MovementResult getMovementResult(Character character, Position newPosition) {
    // Check bounds first
    if (!tileMap.isValidPosition(newPosition)) {
      return MovementResult.outOfBounds;
    }

    // Check tile type
    final tileType = tileMap.getTileAt(newPosition);
    switch (tileType) {
      case TileType.wall:
        return MovementResult.blockedByWall;
      case TileType.obstacle:
        return MovementResult.blockedByObstacle;
      case TileType.floor:
      case TileType.candy:
        break; // These are walkable
    }

    // Check character collision
    if (hasCharacterCollision(character, newPosition)) {
      return MovementResult.blockedByCharacter;
    }

    return MovementResult.success;
  }

  /// Validates a movement and returns detailed information
  MovementValidation validateMovement(
    Character character,
    Position newPosition,
  ) {
    final result = getMovementResult(character, newPosition);
    final charactersAtPosition = getCharactersAt(newPosition);

    return MovementValidation(
      result: result,
      isValid: result == MovementResult.success,
      blockedBy: result != MovementResult.success ? result : null,
      charactersAtDestination: charactersAtPosition,
      tileType: tileMap.isValidPosition(newPosition)
          ? tileMap.getTileAt(newPosition)
          : null,
    );
  }

  /// Gets all adjacent positions that are walkable for a character
  List<Position> getWalkableAdjacentPositions(Position position) {
    final adjacent = <Position>[];
    final directions = [
      Position(0, -1), // North
      Position(1, 0), // East
      Position(0, 1), // South
      Position(-1, 0), // West
    ];

    for (final direction in directions) {
      final newPosition = Position(
        position.x + direction.x,
        position.z + direction.z,
      );

      if (tileMap.isWalkable(newPosition)) {
        adjacent.add(newPosition);
      }
    }

    return adjacent;
  }

  /// Updates the character list (should be called when characters are added/removed)
  void updateCharacters(List<Character> newCharacters) {
    characters.clear();
    characters.addAll(newCharacters);
  }

  /// Adds a character to the collision detection system
  void addCharacter(Character character) {
    if (!characters.any((c) => c.id == character.id)) {
      characters.add(character);
    }
  }

  /// Removes a character from the collision detection system
  void removeCharacter(String characterId) {
    characters.removeWhere((c) => c.id == characterId);
  }
}

/// Represents the result of a movement attempt
enum MovementResult {
  success,
  blockedByWall,
  blockedByObstacle,
  blockedByCharacter,
  outOfBounds;

  String get displayName {
    switch (this) {
      case MovementResult.success:
        return 'Success';
      case MovementResult.blockedByWall:
        return 'Blocked by Wall';
      case MovementResult.blockedByObstacle:
        return 'Blocked by Obstacle';
      case MovementResult.blockedByCharacter:
        return 'Blocked by Character';
      case MovementResult.outOfBounds:
        return 'Out of Bounds';
    }
  }

  bool get isBlocked => this != MovementResult.success;
}

/// Detailed information about a movement validation
class MovementValidation {
  /// The result of the movement attempt
  final MovementResult result;

  /// Whether the movement is valid
  final bool isValid;

  /// What blocked the movement (null if successful)
  final MovementResult? blockedBy;

  /// Characters at the destination position
  final List<Character> charactersAtDestination;

  /// The tile type at the destination (null if out of bounds)
  final TileType? tileType;

  const MovementValidation({
    required this.result,
    required this.isValid,
    this.blockedBy,
    required this.charactersAtDestination,
    this.tileType,
  });

  @override
  String toString() {
    return 'MovementValidation(result: ${result.displayName}, '
        'valid: $isValid, characters: ${charactersAtDestination.length})';
  }
}
