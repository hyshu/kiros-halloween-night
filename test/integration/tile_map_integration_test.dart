import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/tile_map.dart';
import 'package:kiro_halloween_game/core/tile_type.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('TileMap Integration Tests', () {
    test('should work with existing Position class methods', () {
      final tileMap = TileMap();

      // Test Position methods work with TileMap (using valid positions for 100x200 world)
      const center = Position(50, 100);
      const adjacent = Position(51, 100);

      expect(center.isAdjacentTo(adjacent), isTrue);
      expect(center.distanceTo(adjacent), equals(1));
      expect(tileMap.isValidPosition(center), isTrue);
      expect(tileMap.isValidPosition(adjacent), isTrue);

      // Test world coordinates conversion
      final (worldX, worldY, worldZ) = center.toWorldCoordinates();
      expect(worldX, equals(50.0 * Position.tileSpacing));
      expect(worldY, equals(0.0));
      expect(worldZ, equals(100.0 * Position.tileSpacing));
    });

    test('should work with existing TileType enum methods', () {
      final tileMap = TileMap();
      const position = Position(50, 100);

      // Test TileType methods work with TileMap
      tileMap.setTileAt(position, TileType.floor);
      expect(tileMap.getTileAt(position).isWalkable, isTrue);
      expect(tileMap.getTileAt(position).blocksMovement, isFalse);
      expect(tileMap.getTileAt(position).isCollectible, isFalse);
      expect(tileMap.getTileAt(position).displayName, equals('Floor'));

      tileMap.setTileAt(position, TileType.wall);
      expect(tileMap.getTileAt(position).isWalkable, isFalse);
      expect(tileMap.getTileAt(position).blocksMovement, isTrue);
      expect(tileMap.getTileAt(position).isCollectible, isFalse);
      expect(tileMap.getTileAt(position).displayName, equals('Wall'));

      tileMap.setTileAt(position, TileType.obstacle);
      expect(tileMap.getTileAt(position).isWalkable, isFalse);
      expect(tileMap.getTileAt(position).blocksMovement, isTrue);
      expect(tileMap.getTileAt(position).isCollectible, isFalse);
      expect(tileMap.getTileAt(position).displayName, equals('Obstacle'));

      tileMap.setTileAt(position, TileType.candy);
      expect(tileMap.getTileAt(position).isWalkable, isTrue);
      expect(tileMap.getTileAt(position).blocksMovement, isFalse);
      expect(tileMap.getTileAt(position).isCollectible, isTrue);
      expect(tileMap.getTileAt(position).displayName, equals('Candy'));
    });

    test('should handle large world dimensions correctly', () {
      final tileMap = TileMap();

      // Test corners of the world (100x200)
      expect(tileMap.isValidPosition(const Position(0, 0)), isTrue);
      expect(tileMap.isValidPosition(const Position(99, 199)), isTrue);
      expect(tileMap.isValidPosition(const Position(100, 200)), isFalse);

      // Test that we can set tiles across the world
      const farPosition = Position(90, 180);
      tileMap.setTileAt(farPosition, TileType.candy);
      expect(tileMap.getTileAt(farPosition), equals(TileType.candy));

      // Test pathfinding across large distances
      const start = Position(20, 20);
      const end = Position(180, 380);
      expect(
        start.distanceTo(end),
        equals(520),
      ); // Manhattan distance: (180-20) + (380-20)
    });

    test('should maintain boundary integrity across all operations', () {
      final tileMap = TileMap();

      // Verify all perimeter positions are walls
      final perimeterPositions = tileMap.getPerimeterPositions();
      for (final position in perimeterPositions) {
        expect(tileMap.getTileAt(position), equals(TileType.wall));
        expect(tileMap.isWalkable(position), isFalse);
      }

      // Verify we cannot break the perimeter
      const topEdge = Position(50, 0);
      const bottomEdge = Position(50, 199);
      const leftEdge = Position(0, 100);
      const rightEdge = Position(99, 100);

      expect(
        () => tileMap.setTileAt(topEdge, TileType.floor),
        throwsArgumentError,
      );
      expect(
        () => tileMap.setTileAt(bottomEdge, TileType.floor),
        throwsArgumentError,
      );
      expect(
        () => tileMap.setTileAt(leftEdge, TileType.floor),
        throwsArgumentError,
      );
      expect(
        () => tileMap.setTileAt(rightEdge, TileType.floor),
        throwsArgumentError,
      );

      // Verify perimeter validation still passes
      expect(tileMap.validatePerimeterWalls(), isTrue);
    });

    test('should support boss and spawn location management', () {
      final tileMap = TileMap();

      // Test setting boss location (within 100x200 bounds)
      const bossLocation = Position(75, 175);
      tileMap.setBossLocation(bossLocation);
      expect(tileMap.bossLocation, equals(bossLocation));

      // Test setting spawn location
      const spawnLocation = Position(50, 50);
      tileMap.setPlayerSpawn(spawnLocation);
      expect(tileMap.playerSpawn, equals(spawnLocation));

      // Test that boss and spawn can be on different tile types
      tileMap.setTileAt(bossLocation, TileType.floor);
      tileMap.setTileAt(spawnLocation, TileType.floor);

      expect(tileMap.isWalkable(bossLocation), isTrue);
      expect(tileMap.isWalkable(spawnLocation), isTrue);
    });
  });
}
