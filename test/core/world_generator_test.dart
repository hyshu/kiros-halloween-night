import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/world_generator.dart';
import '../../lib/core/tile_map.dart';
import '../../lib/core/tile_type.dart';
import '../../lib/core/position.dart';

void main() {
  group('WorldGenerator', () {
    late WorldGenerator generator;

    setUp(() {
      generator = WorldGenerator(seed: 12345, isTestMode: true); // Use test mode for faster tests
    });

    group('generateWorld', () {
      test('should generate a valid world with spawn and boss locations', () {
        final world = generator.generateWorld();

        expect(world, isNotNull);
        expect(world.playerSpawn, isNotNull);
        expect(world.bossLocation, isNotNull);
        expect(world.validatePerimeterWalls(), isTrue);
      });

      test('should ensure spawn and boss locations are on floor tiles', () {
        final world = generator.generateWorld();

        expect(world.getTileAt(world.playerSpawn!), TileType.floor);
        expect(world.getTileAt(world.bossLocation!), TileType.floor);
      });

      test('should place boss location far from spawn', () {
        final world = generator.generateWorld();
        final spawn = world.playerSpawn!;
        final boss = world.bossLocation!;

        // Boss should be reasonably far from spawn
        final distance = spawn.distanceTo(boss);
        expect(distance, greaterThan(10));
      });

      test('should maintain perimeter walls', () {
        final world = generator.generateWorld();

        // Check all perimeter positions are walls
        final perimeterPositions = world.getPerimeterPositions();
        for (final position in perimeterPositions) {
          expect(world.getTileAt(position), TileType.wall,
              reason: 'Perimeter position $position should be a wall');
        }
      });

      test('should contain various tile types', () {
        final world = generator.generateWorld();

        // Check for room-based structure with better sampling
        final samplePositions = <Position>[
          // Sample room interiors
          Position(60, 60), Position(210, 160), Position(360, 310), Position(110, 410),
          // Sample walls around rooms
          Position(50, 50), Position(200, 150), Position(350, 300), Position(100, 400),
          // Sample corridor areas  
          Position(125, 100), Position(250, 200), Position(200, 350),
        ];

        final tileTypes = <TileType>{};
        for (final pos in samplePositions) {
          if (world.isValidPosition(pos)) {
            tileTypes.add(world.getTileAt(pos));
          }
        }

        expect(tileTypes, contains(TileType.floor), reason: 'World should contain floor tiles');
        expect(tileTypes, contains(TileType.wall), reason: 'World should contain wall tiles');
        
        // Check for obstacles and candy in generated world
        final obstacles = world.getPositionsOfType(TileType.obstacle);
        final candies = world.getPositionsOfType(TileType.candy);
        expect(obstacles.isNotEmpty, isTrue, reason: 'World should contain obstacles');
        expect(candies.isNotEmpty, isTrue, reason: 'World should contain candy');
      });
    });

    group('path validation', () {
      test('should ensure path exists from spawn to boss', () {
        final world = generator.generateWorld();
        final spawn = world.playerSpawn!;
        final boss = world.bossLocation!;

        expect(_hasPath(world, spawn, boss), isTrue,
            reason: 'There should be a navigable path from spawn to boss');
      });

      test('should handle path validation correctly', () {
        // Create a test world with known path
        final spawn = Position(5, 5);
        final boss = Position(10, 10);
        final world = generator.generateTestWorld(
          spawnLocation: spawn,
          bossLocation: boss,
          ensurePath: true,
        );

        expect(_hasPath(world, spawn, boss), isTrue);
      });

      test('should detect when no path exists', () {
        // Create a world where boss is isolated
        final world = TileMap();
        final spawn = Position(5, 5);
        final boss = Position(10, 10);

        // Set spawn area
        world.setTileAt(spawn, TileType.floor);
        world.setPlayerSpawn(spawn);

        // Isolate boss with walls
        world.setTileAt(boss, TileType.floor);
        world.setBossLocation(boss);
        
        // Surround boss with walls (except perimeter which is already walls)
        for (int dz = -1; dz <= 1; dz++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dz == 0) continue; // Skip boss position
            final wallPos = Position(boss.x + dx, boss.z + dz);
            if (world.isValidPosition(wallPos) && !world.isPerimeterPosition(wallPos)) {
              world.setTileAt(wallPos, TileType.wall);
            }
          }
        }

        expect(_hasPath(world, spawn, boss), isFalse);
      });
    });

    group('room generation', () {
      test('should create room-based structure', () {
        final world = generator.generateWorld();

        // Check that world has room-based structure (rooms connected by corridors)
        final samplePositions = [
          Position(60, 60),   // Inside first test room
          Position(210, 160), // Inside second test room  
          Position(360, 310), // Inside third test room
          Position(110, 410), // Inside fourth test room
        ];

        final tileTypes = <TileType>{};
        for (final pos in samplePositions) {
          if (world.isValidPosition(pos)) {
            tileTypes.add(world.getTileAt(pos));
          }
        }
        
        expect(tileTypes, contains(TileType.floor), 
            reason: 'World should contain floor tiles in rooms');
        
        // Verify that the world generation completed successfully
        expect(world.playerSpawn, isNotNull);
        expect(world.bossLocation, isNotNull);
      });

      test('should not modify perimeter walls during generation', () {
        final world = generator.generateWorld();
        
        // All perimeter positions should remain walls
        final perimeterPositions = world.getPerimeterPositions();
        for (final position in perimeterPositions) {
          expect(world.getTileAt(position), TileType.wall);
        }
      });
    });

    group('obstacle placement', () {
      test('should not place obstacles that break the main path', () {
        final world = generator.generateWorld();
        final spawn = world.playerSpawn!;
        final boss = world.bossLocation!;

        // Path should still exist after obstacle placement
        expect(_hasPath(world, spawn, boss), isTrue);
      });

      test('should not place obstacles on spawn or boss locations', () {
        final world = generator.generateWorld();
        final spawn = world.playerSpawn!;
        final boss = world.bossLocation!;

        expect(world.getTileAt(spawn), isNot(TileType.obstacle));
        expect(world.getTileAt(boss), isNot(TileType.obstacle));
      });
    });

    group('candy placement', () {
      test('should place candy items throughout the world', () {
        final world = generator.generateWorld();

        final candyPositions = world.getPositionsOfType(TileType.candy);
        expect(candyPositions, isNotEmpty, reason: 'World should contain candy items');
      });

      test('should not place candy on spawn or boss locations', () {
        final world = generator.generateWorld();
        final spawn = world.playerSpawn!;
        final boss = world.bossLocation!;

        expect(world.getTileAt(spawn), isNot(TileType.candy));
        expect(world.getTileAt(boss), isNot(TileType.candy));
      });

      test('should place candy only on floor tiles', () {
        final world = generator.generateWorld();
        final candyPositions = world.getPositionsOfType(TileType.candy);

        for (final position in candyPositions) {
          // Candy tiles are walkable
          expect(world.isWalkable(position), isTrue);
        }
      });
    });

    group('generateTestWorld', () {
      test('should create world with specified spawn and boss locations', () {
        final spawn = Position(10, 10);
        final boss = Position(50, 50);
        
        final world = generator.generateTestWorld(
          spawnLocation: spawn,
          bossLocation: boss,
        );

        expect(world.playerSpawn, equals(spawn));
        expect(world.bossLocation, equals(boss));
        expect(world.getTileAt(spawn), TileType.floor);
        expect(world.getTileAt(boss), TileType.floor);
      });

      test('should ensure path when ensurePath is true', () {
        final spawn = Position(10, 10);
        final boss = Position(100, 100);
        
        final world = generator.generateTestWorld(
          spawnLocation: spawn,
          bossLocation: boss,
          ensurePath: true,
        );

        expect(_hasPath(world, spawn, boss), isTrue);
      });

      test('should maintain perimeter walls in test world', () {
        final spawn = Position(10, 10);
        final boss = Position(50, 50);
        
        final world = generator.generateTestWorld(
          spawnLocation: spawn,
          bossLocation: boss,
        );

        expect(world.validatePerimeterWalls(), isTrue);
      });
    });

    group('reproducibility', () {
      test('should generate identical worlds with same seed', () {
        final generator1 = WorldGenerator(seed: 42, isTestMode: true);
        final generator2 = WorldGenerator(seed: 42, isTestMode: true);

        final world1 = generator1.generateWorld();
        final world2 = generator2.generateWorld();

        expect(world1.playerSpawn, equals(world2.playerSpawn));
        expect(world1.bossLocation, equals(world2.bossLocation));

        // Check that tile layouts are identical (sample check for performance)
        final samplePositions = [
          Position(10, 10),
          Position(50, 50),
          Position(100, 100),
          Position(250, 500),
          Position(400, 800),
        ];
        
        for (final pos in samplePositions) {
          if (world1.isValidPosition(pos) && world2.isValidPosition(pos)) {
            expect(world1.getTileAt(pos), equals(world2.getTileAt(pos)),
                reason: 'Tile at $pos should be identical in both worlds');
          }
        }
      });

      test('should generate different worlds with different seeds', () {
        final generator1 = WorldGenerator(seed: 42, isTestMode: true);
        final generator2 = WorldGenerator(seed: 123, isTestMode: true);

        final world1 = generator1.generateWorld();
        final world2 = generator2.generateWorld();

        // At least spawn or boss should be different
        final spawnDifferent = world1.playerSpawn != world2.playerSpawn;
        final bossDifferent = world1.bossLocation != world2.bossLocation;
        
        expect(spawnDifferent || bossDifferent, isTrue,
            reason: 'Different seeds should produce different worlds');
      });
    });
  });
}

/// Helper function to check if a path exists between two positions using BFS
bool _hasPath(TileMap tileMap, Position start, Position end) {
  if (start == end) return true;
  
  final visited = <Position>{};
  final queue = <Position>[start];
  visited.add(start);
  
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    
    if (current == end) {
      return true;
    }
    
    for (final neighbor in tileMap.getWalkableAdjacentPositions(current)) {
      if (!visited.contains(neighbor)) {
        visited.add(neighbor);
        queue.add(neighbor);
      }
    }
  }
  
  return false;
}