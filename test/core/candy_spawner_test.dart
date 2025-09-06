import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import '../../lib/core/candy_spawner.dart';
import '../../lib/core/candy_item.dart';
import '../../lib/core/tile_map.dart';
import '../../lib/core/tile_type.dart';
import '../../lib/core/position.dart';

void main() {
  group('CandySpawner', () {
    late CandySpawner spawner;
    late TileMap tileMap;

    setUp(() {
      spawner = CandySpawner(
        random: Random(42), // Fixed seed for reproducible tests
        spawnProbability: 0.1, // Higher probability for testing
        minDistanceBetweenCandy: 2,
        maxCandyCount: 50,
      );
      
      // Create a small test map
      tileMap = TileMap();
      
      // Create some floor tiles for testing
      for (int x = 5; x < 15; x++) {
        for (int z = 5; z < 15; z++) {
          tileMap.setTileAt(Position(x, z), TileType.floor);
        }
      }
    });

    test('should spawn candy on floor tiles', () {
      final spawnedCandy = spawner.spawnCandyOnMap(tileMap);
      
      expect(spawnedCandy.isNotEmpty, isTrue);
      
      // All spawned candy should be on floor tiles (now converted to candy tiles)
      for (final candy in spawnedCandy) {
        expect(candy.position, isNotNull);
        expect(tileMap.getTileAt(candy.position!), equals(TileType.candy));
      }
    });

    test('should not exceed maximum candy count', () {
      final spawner = CandySpawner(
        random: Random(42),
        spawnProbability: 1.0, // 100% probability
        maxCandyCount: 10,
      );
      
      final spawnedCandy = spawner.spawnCandyOnMap(tileMap);
      
      expect(spawnedCandy.length, lessThanOrEqualTo(10));
    });

    test('should respect minimum distance between candy', () {
      final spawnedCandy = spawner.spawnCandyOnMap(tileMap);
      
      // Check that no two candy items are too close
      for (int i = 0; i < spawnedCandy.length; i++) {
        for (int j = i + 1; j < spawnedCandy.length; j++) {
          final pos1 = spawnedCandy[i].position!;
          final pos2 = spawnedCandy[j].position!;
          final distance = (pos1.x - pos2.x).abs() + (pos1.z - pos2.z).abs();
          
          expect(distance, greaterThanOrEqualTo(spawner.minDistanceBetweenCandy));
        }
      }
    });

    test('should create candy with unique IDs', () {
      final spawnedCandy = spawner.spawnCandyOnMap(tileMap);
      
      final ids = spawnedCandy.map((c) => c.id).toSet();
      expect(ids.length, equals(spawnedCandy.length)); // All IDs should be unique
    });

    test('should spawn candy at specific positions', () {
      final positions = [
        Position(10, 10),
        Position(12, 12),
        Position(8, 8),
      ];
      
      final spawnedCandy = spawner.spawnCandyAtPositions(positions);
      
      expect(spawnedCandy.length, equals(3));
      
      for (int i = 0; i < spawnedCandy.length; i++) {
        expect(spawnedCandy[i].position, equals(positions[i]));
      }
    });

    test('should create random candy at position', () {
      final position = Position(10, 10);
      final candy = spawner.createRandomCandyAt(position);
      
      expect(candy.position, equals(position));
      expect(candy.id, isNotEmpty);
      expect(candy.name, isNotEmpty);
      expect(candy.modelPath, startsWith('assets/foods/'));
    });

    test('should create weighted random candy', () {
      final position = Position(10, 10);
      final candyList = <CandyItem>[];
      
      // Create multiple candy items to test distribution
      for (int i = 0; i < 100; i++) {
        spawner.resetIdCounter(); // Reset for consistent IDs
        final candy = spawner.createWeightedRandomCandyAt(position);
        candyList.add(candy);
      }
      
      // Should have variety in candy types
      final uniqueTypes = candyList.map((c) => c.name).toSet();
      expect(uniqueTypes.length, greaterThan(1));
      
      // Common types should appear more frequently
      final candyBarCount = candyList.where((c) => c.name == 'Candy Bar').length;
      final gingerBreadCount = candyList.where((c) => c.name == 'Gingerbread').length;
      
      // Candy bars should be more common than gingerbread
      expect(candyBarCount, greaterThan(gingerBreadCount));
    });

    test('should spawn weighted candy on map', () {
      final spawnedCandy = spawner.spawnWeightedCandyOnMap(tileMap);
      
      expect(spawnedCandy.isNotEmpty, isTrue);
      
      // Should have variety in candy types
      final uniqueTypes = spawnedCandy.map((c) => c.name).toSet();
      expect(uniqueTypes.length, greaterThan(1));
    });

    test('should provide spawn statistics', () {
      final spawnedCandy = spawner.spawnCandyOnMap(tileMap);
      final stats = spawner.getSpawnStatistics(spawnedCandy);
      
      expect(stats['totalCount'], equals(spawnedCandy.length));
      expect(stats['typeDistribution'], isA<Map<String, int>>());
      expect(stats['effectDistribution'], isA<Map<String, int>>());
      expect(stats['spawnProbability'], equals(spawner.spawnProbability));
      expect(stats['minDistance'], equals(spawner.minDistanceBetweenCandy));
      expect(stats['maxCount'], equals(spawner.maxCandyCount));
    });

    test('should reset ID counter', () {
      final candy1 = spawner.createRandomCandyAt(Position(5, 5));
      spawner.resetIdCounter();
      final candy2 = spawner.createRandomCandyAt(Position(6, 6));
      
      // After reset, should start from 0 again
      expect(candy2.id, equals('candy_0'));
    });

    test('should handle empty map gracefully', () {
      final emptyMap = TileMap();
      // Convert all tiles to walls to make it truly empty
      for (int x = 0; x < TileMap.worldWidth; x++) {
        for (int z = 0; z < TileMap.worldHeight; z++) {
          emptyMap.setTileAt(Position(x, z), TileType.wall);
        }
      }
      final spawnedCandy = spawner.spawnCandyOnMap(emptyMap);
      
      expect(spawnedCandy.isEmpty, isTrue);
    });

    test('should handle map with no valid spawn locations', () {
      // Create a map with only walls and obstacles
      for (int x = 0; x < TileMap.worldWidth; x++) {
        for (int z = 0; z < TileMap.worldHeight; z++) {
          if (x == 0 || x == TileMap.worldWidth - 1 || 
              z == 0 || z == TileMap.worldHeight - 1) {
            tileMap.setTileAt(Position(x, z), TileType.wall);
          } else {
            tileMap.setTileAt(Position(x, z), TileType.obstacle);
          }
        }
      }
      
      final spawnedCandy = spawner.spawnCandyOnMap(tileMap);
      expect(spawnedCandy.isEmpty, isTrue);
    });

    test('should create all candy types', () {
      final candyTypes = <String>{};
      
      // Create many candy items to ensure we get all types
      for (int i = 0; i < 1000; i++) {
        final candy = spawner.createRandomCandyAt(Position(0, 0));
        candyTypes.add(candy.name);
      }
      
      // Should have created multiple different types
      expect(candyTypes.length, greaterThan(5));
    });

    test('should maintain spawn probability', () {
      // Create a small test map with only a few floor tiles
      final smallMap = TileMap();
      // Set all tiles to walls first
      for (int x = 0; x < TileMap.worldWidth; x++) {
        for (int z = 0; z < TileMap.worldHeight; z++) {
          smallMap.setTileAt(Position(x, z), TileType.wall);
        }
      }
      // Create a small 5x5 floor area
      for (int x = 10; x < 15; x++) {
        for (int z = 10; z < 15; z++) {
          smallMap.setTileAt(Position(x, z), TileType.floor);
        }
      }
      
      final lowProbabilitySpawner = CandySpawner(
        random: Random(42),
        spawnProbability: 0.01, // Very low probability
        maxCandyCount: 1000,
        minDistanceBetweenCandy: 1, // Allow closer spacing for this test
      );
      
      final spawnedCandy = lowProbabilitySpawner.spawnCandyOnMap(smallMap);
      
      // With low probability and small area, should spawn very few items
      expect(spawnedCandy.length, lessThan(10));
    });
  });
}