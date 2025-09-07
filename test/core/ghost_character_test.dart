import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kiro_halloween_game/core/ghost_character.dart';
import 'package:kiro_halloween_game/core/position.dart';
import 'package:kiro_halloween_game/core/tile_map.dart';
import 'package:kiro_halloween_game/core/tile_type.dart';

void main() {
  group('GhostCharacter', () {
    late GhostCharacter ghostCharacter;
    late TileMap tileMap;

    setUp(() {
      ghostCharacter = GhostCharacter(
        id: 'test_ghost',
        position: const Position(5, 5),
        health: 100,
        maxHealth: 100,
      );

      // Create a simple test tile map
      tileMap = TileMap();
      tileMap.setPlayerSpawn(const Position(5, 5));

      // Add some walls for testing collision
      tileMap.setTileAt(const Position(5, 4), TileType.wall); // North wall
      tileMap.setTileAt(const Position(6, 5), TileType.wall); // East wall
    });

    test('should initialize with correct properties', () {
      expect(ghostCharacter.id, equals('test_ghost'));
      expect(ghostCharacter.position, equals(const Position(5, 5)));
      expect(ghostCharacter.health, equals(100));
      expect(ghostCharacter.maxHealth, equals(100));
      expect(
        ghostCharacter.modelPath,
        equals('assets/graveyard/character-ghost.obj'),
      );
      expect(ghostCharacter.isActive, isTrue);
      expect(ghostCharacter.canMove, isTrue);
      expect(ghostCharacter.isIdle, isTrue);
      expect(ghostCharacter.abilities, isEmpty);
    });

    test('should handle arrow key input correctly', () {
      // Test moving south (should succeed)
      final result = ghostCharacter.handleInput(
        LogicalKeyboardKey.arrowDown,
        tileMap,
      );
      expect(result, isTrue);
      expect(ghostCharacter.position, equals(const Position(5, 6)));
      expect(ghostCharacter.lastMovementDirection, equals(Direction.south));
      expect(ghostCharacter.isIdle, isFalse);
    });

    test('should handle WASD key input correctly', () {
      // Test moving west with 'A' key
      final result = ghostCharacter.handleInput(
        LogicalKeyboardKey.keyA,
        tileMap,
      );
      expect(result, isTrue);
      expect(ghostCharacter.position, equals(const Position(4, 5)));
      expect(ghostCharacter.lastMovementDirection, equals(Direction.west));
    });

    test('should prevent movement through walls', () {
      // Try to move north into a wall
      final result = ghostCharacter.handleInput(
        LogicalKeyboardKey.arrowUp,
        tileMap,
      );
      expect(result, isTrue); // Input was handled
      expect(
        ghostCharacter.position,
        equals(const Position(5, 5)),
      ); // But position didn't change
      expect(
        ghostCharacter.isIdle,
        isTrue,
      ); // Character should be idle after failed move
    });

    test('should prevent movement through obstacles', () {
      // Add an obstacle to the west
      tileMap.setTileAt(const Position(4, 5), TileType.obstacle);

      final result = ghostCharacter.handleInput(
        LogicalKeyboardKey.arrowLeft,
        tileMap,
      );
      expect(result, isTrue); // Input was handled
      expect(
        ghostCharacter.position,
        equals(const Position(5, 5)),
      ); // But position didn't change
      expect(ghostCharacter.isIdle, isTrue);
    });

    test('should prevent movement outside bounds', () {
      // Move to edge of map (but not perimeter since that's walls)
      ghostCharacter.position = const Position(1, 1);

      // Try to move west (into perimeter wall)
      final result = ghostCharacter.handleInput(
        LogicalKeyboardKey.arrowLeft,
        tileMap,
      );
      expect(result, isTrue); // Input was handled
      expect(
        ghostCharacter.position,
        equals(const Position(1, 1)),
      ); // Position unchanged
      expect(ghostCharacter.isIdle, isTrue);
    });

    test('should allow movement onto candy tiles', () {
      // Place candy tile to the south
      tileMap.setTileAt(const Position(5, 6), TileType.candy);

      final result = ghostCharacter.handleInput(
        LogicalKeyboardKey.arrowDown,
        tileMap,
      );
      expect(result, isTrue);
      expect(ghostCharacter.position, equals(const Position(5, 6)));
      expect(ghostCharacter.isIdle, isFalse);
    });

    test('should ignore unhandled keys', () {
      final result = ghostCharacter.handleInput(
        LogicalKeyboardKey.space,
        tileMap,
      );
      expect(result, isFalse);
      expect(
        ghostCharacter.position,
        equals(const Position(5, 5)),
      ); // No movement
    });

    test('should manage abilities correctly', () {
      // Add an ability
      ghostCharacter.addAbility('speedBoost', 2);
      expect(ghostCharacter.hasAbility('speedBoost'), isTrue);
      expect(ghostCharacter.getAbility<int>('speedBoost'), equals(2));

      // Remove the ability
      ghostCharacter.removeAbility('speedBoost');
      expect(ghostCharacter.hasAbility('speedBoost'), isFalse);
      expect(ghostCharacter.getAbility<int>('speedBoost'), isNull);
    });

    test('should apply health boost ability', () {
      // Reduce health first
      ghostCharacter.takeDamage(30);
      expect(ghostCharacter.health, equals(70));

      // Add health boost ability
      ghostCharacter.addAbility('healthBoost', 20);
      expect(ghostCharacter.health, equals(90)); // Should be healed
    });

    test('should handle direction enum correctly', () {
      expect(Direction.north.opposite, equals(Direction.south));
      expect(Direction.south.opposite, equals(Direction.north));
      expect(Direction.east.opposite, equals(Direction.west));
      expect(Direction.west.opposite, equals(Direction.east));

      expect(Direction.north.displayName, equals('North'));
      expect(Direction.south.displayName, equals('South'));
      expect(Direction.east.displayName, equals('East'));
      expect(Direction.west.displayName, equals('West'));
    });

    test('should prevent input processing when canMove is false', () {
      // Disable movement
      ghostCharacter.canMove = false;

      // Input should be ignored when canMove is false
      final result = ghostCharacter.handleInput(
        LogicalKeyboardKey.arrowUp,
        tileMap,
      );
      expect(result, isFalse); // Should be ignored
    });

    test('should set idle state correctly', () {
      // Move character first
      ghostCharacter.attemptMove(Direction.south, tileMap);
      expect(ghostCharacter.isIdle, isFalse);
      expect(ghostCharacter.lastMovementDirection, equals(Direction.south));

      // Set to idle
      ghostCharacter.setIdle();
      expect(ghostCharacter.isIdle, isTrue);
      expect(ghostCharacter.lastMovementDirection, isNull);
    });

    test('should provide correct string representation', () {
      ghostCharacter.addAbility('speedBoost', 2);
      ghostCharacter.addAbility('healthBoost', 10);

      final str = ghostCharacter.toString();
      expect(str, contains('GhostCharacter(test_ghost)'));
      expect(str, contains('Position(5, 5)'));
      expect(str, contains('Health: 100/100'));
      expect(str, contains('speedBoost'));
      expect(str, contains('healthBoost'));
    });
  });
}
