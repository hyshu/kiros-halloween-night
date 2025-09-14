import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/tile_map.dart';
import 'package:kiro_halloween_game/core/tile_type.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('TileMap', () {
    late TileMap tileMap;

    setUp(() {
      tileMap = TileMap();
    });

    group('Initialization', () {
      test('should create a 100x200 grid', () {
        final (width, height) = tileMap.dimensions;
        expect(width, equals(100));
        expect(height, equals(200));
      });

      test('should initialize all interior tiles as floor', () {
        // Check a few interior positions
        expect(
          tileMap.getTileAt(const Position(25, 50)),
          equals(TileType.floor),
        );
        expect(
          tileMap.getTileAt(const Position(25, 50)),
          equals(TileType.floor),
        );
        expect(
          tileMap.getTileAt(const Position(75, 150)),
          equals(TileType.floor),
        );
      });

      test('should initialize complete perimeter walls with no gaps', () {
        // Test all perimeter positions are walls
        final perimeterPositions = tileMap.getPerimeterPositions();

        for (final position in perimeterPositions) {
          expect(
            tileMap.getTileAt(position),
            equals(TileType.wall),
            reason: 'Position $position should be a wall',
          );
        }
      });

      test('should validate perimeter walls successfully', () {
        expect(tileMap.validatePerimeterWalls(), isTrue);
      });
    });

    group('Position Validation', () {
      test('should validate positions within bounds', () {
        expect(tileMap.isValidPosition(const Position(0, 0)), isTrue);
        expect(tileMap.isValidPosition(const Position(99, 199)), isTrue);
        expect(tileMap.isValidPosition(const Position(25, 50)), isTrue);
      });

      test('should reject positions outside bounds', () {
        expect(tileMap.isValidPosition(const Position(-1, 0)), isFalse);
        expect(tileMap.isValidPosition(const Position(0, -1)), isFalse);
        expect(tileMap.isValidPosition(const Position(500, 0)), isFalse);
        expect(tileMap.isValidPosition(const Position(0, 1000)), isFalse);
        expect(tileMap.isValidPosition(const Position(25, 50)), isTrue);
      });

      test('should identify perimeter positions correctly', () {
        // Corner positions
        expect(tileMap.isPerimeterPosition(const Position(0, 0)), isTrue);
        expect(tileMap.isPerimeterPosition(const Position(499, 0)), isTrue);
        expect(tileMap.isPerimeterPosition(const Position(0, 999)), isTrue);
        expect(tileMap.isPerimeterPosition(const Position(99, 199)), isTrue);

        // Edge positions
        expect(tileMap.isPerimeterPosition(const Position(250, 0)), isTrue);
        expect(tileMap.isPerimeterPosition(const Position(50, 199)), isTrue);
        expect(tileMap.isPerimeterPosition(const Position(0, 500)), isTrue);
        expect(tileMap.isPerimeterPosition(const Position(99, 100)), isTrue);

        // Interior positions
        expect(tileMap.isPerimeterPosition(const Position(1, 1)), isFalse);
        expect(tileMap.isPerimeterPosition(const Position(25, 50)), isFalse);
        expect(tileMap.isPerimeterPosition(const Position(98, 198)), isFalse);
      });
    });

    group('Tile Management', () {
      test('should get and set tile types correctly', () {
        const position = Position(50, 100);

        // Initially should be floor
        expect(tileMap.getTileAt(position), equals(TileType.floor));

        // Set to obstacle
        tileMap.setTileAt(position, TileType.obstacle);
        expect(tileMap.getTileAt(position), equals(TileType.obstacle));

        // Set to candy
        tileMap.setTileAt(position, TileType.candy);
        expect(tileMap.getTileAt(position), equals(TileType.candy));
      });

      test('should prevent modification of perimeter walls', () {
        const perimeterPosition = Position(0, 0);

        expect(
          () => tileMap.setTileAt(perimeterPosition, TileType.floor),
          throwsArgumentError,
        );

        expect(
          () => tileMap.setTileAt(perimeterPosition, TileType.obstacle),
          throwsArgumentError,
        );

        expect(
          () => tileMap.setTileAt(perimeterPosition, TileType.candy),
          throwsArgumentError,
        );
      });

      test('should allow setting perimeter walls to wall type', () {
        const perimeterPosition = Position(0, 0);

        // This should not throw
        expect(
          () => tileMap.setTileAt(perimeterPosition, TileType.wall),
          returnsNormally,
        );
      });

      test('should throw error when setting tiles out of bounds', () {
        expect(
          () => tileMap.setTileAt(const Position(-1, 0), TileType.floor),
          throwsArgumentError,
        );

        expect(
          () => tileMap.setTileAt(const Position(500, 0), TileType.floor),
          throwsArgumentError,
        );
      });

      test('should return wall for out of bounds positions', () {
        expect(tileMap.getTileAt(const Position(-1, 0)), equals(TileType.wall));
        expect(
          tileMap.getTileAt(const Position(500, 0)),
          equals(TileType.wall),
        );
        expect(tileMap.getTileAt(const Position(0, -1)), equals(TileType.wall));
        expect(
          tileMap.getTileAt(const Position(0, 1000)),
          equals(TileType.wall),
        );
      });
    });

    group('Movement and Walkability', () {
      test('should identify walkable positions correctly', () {
        const floorPosition = Position(50, 100);
        const wallPosition = Position(0, 0); // Perimeter wall

        tileMap.setTileAt(floorPosition, TileType.floor);

        expect(tileMap.isWalkable(floorPosition), isTrue);
        expect(tileMap.isWalkable(wallPosition), isFalse);
        expect(tileMap.blocksMovement(floorPosition), isFalse);
        expect(tileMap.blocksMovement(wallPosition), isTrue);
      });

      test('should identify candy as walkable', () {
        const candyPosition = Position(50, 100);
        tileMap.setTileAt(candyPosition, TileType.candy);

        expect(tileMap.isWalkable(candyPosition), isTrue);
        expect(tileMap.hasCollectible(candyPosition), isTrue);
      });

      test('should identify obstacles as non-walkable', () {
        const obstaclePosition = Position(50, 100);
        tileMap.setTileAt(obstaclePosition, TileType.obstacle);

        expect(tileMap.isWalkable(obstaclePosition), isFalse);
        expect(tileMap.blocksMovement(obstaclePosition), isTrue);
      });

      test('should get walkable adjacent positions', () {
        const centerPosition = Position(50, 100);

        // Set up a cross pattern with walls
        tileMap.setTileAt(const Position(50, 99), TileType.wall); // North
        tileMap.setTileAt(const Position(51, 100), TileType.floor); // East
        tileMap.setTileAt(const Position(50, 101), TileType.floor); // South
        tileMap.setTileAt(const Position(49, 100), TileType.obstacle); // West

        final walkableAdjacent = tileMap.getWalkableAdjacentPositions(
          centerPosition,
        );

        expect(walkableAdjacent.length, equals(2));
        expect(walkableAdjacent, contains(const Position(51, 100))); // East
        expect(walkableAdjacent, contains(const Position(50, 101))); // South
      });
    });

    group('Position Queries', () {
      test('should find positions of specific tile types', () {
        // Set some candy positions
        const candy1 = Position(25, 50);
        const candy2 = Position(75, 125);
        tileMap.setTileAt(candy1, TileType.candy);
        tileMap.setTileAt(candy2, TileType.candy);

        final candyPositions = tileMap.getPositionsOfType(TileType.candy);

        expect(candyPositions, contains(candy1));
        expect(candyPositions, contains(candy2));
      });

      test('should get all perimeter positions', () {
        final perimeterPositions = tileMap.getPerimeterPositions();

        // Should have correct count: 2*width + 2*(height-2)
        final expectedCount = 2 * 100 + 2 * (200 - 2);
        expect(perimeterPositions.length, equals(expectedCount));

        // Check corners are included
        expect(perimeterPositions, contains(const Position(0, 0)));
        expect(perimeterPositions, contains(const Position(99, 0)));
        expect(perimeterPositions, contains(const Position(0, 199)));
        expect(perimeterPositions, contains(const Position(99, 199)));
      });
    });

    group('Boss and Spawn Locations', () {
      test('should set and get boss location', () {
        const bossPos = Position(75, 150);
        tileMap.setBossLocation(bossPos);

        expect(tileMap.bossLocation, equals(bossPos));
      });

      test('should set and get player spawn location', () {
        const spawnPos = Position(25, 50);
        tileMap.setPlayerSpawn(spawnPos);

        expect(tileMap.playerSpawn, equals(spawnPos));
      });

      test('should reject out of bounds boss location', () {
        expect(
          () => tileMap.setBossLocation(const Position(-1, 0)),
          throwsArgumentError,
        );

        expect(
          () => tileMap.setBossLocation(const Position(500, 0)),
          throwsArgumentError,
        );
      });

      test('should reject out of bounds spawn location', () {
        expect(
          () => tileMap.setPlayerSpawn(const Position(-1, 0)),
          throwsArgumentError,
        );

        expect(
          () => tileMap.setPlayerSpawn(const Position(500, 0)),
          throwsArgumentError,
        );
      });
    });

    group('Boundary Validation', () {
      test('should validate complete perimeter walls', () {
        expect(tileMap.validatePerimeterWalls(), isTrue);
      });

      test('should detect broken perimeter walls', () {
        // Create a tile map with a gap in the perimeter
        final tilesWithGap = List.generate(
          200,
          (z) => List.generate(100, (x) => TileType.floor),
        );

        // Set perimeter walls but leave a gap
        for (int x = 0; x < 100; x++) {
          tilesWithGap[0][x] = TileType.wall; // Top
          tilesWithGap[199][x] = TileType.wall; // Bottom
        }
        for (int z = 0; z < 200; z++) {
          tilesWithGap[z][0] = TileType.wall; // Left
          tilesWithGap[z][99] = TileType.wall; // Right
        }

        // Create a gap
        tilesWithGap[0][50] = TileType.floor;

        expect(() => TileMap.fromTiles(tilesWithGap), throwsStateError);
      });
    });

    group('fromTiles Constructor', () {
      test('should create TileMap from valid tile data', () {
        final tiles = List.generate(
          200,
          (z) => List.generate(100, (x) => TileType.floor),
        );

        // Set perimeter walls
        for (int x = 0; x < 100; x++) {
          tiles[0][x] = TileType.wall;
          tiles[199][x] = TileType.wall;
        }
        for (int z = 0; z < 200; z++) {
          tiles[z][0] = TileType.wall;
          tiles[z][99] = TileType.wall;
        }

        final tileMapFromData = TileMap.fromTiles(tiles);
        expect(tileMapFromData.validatePerimeterWalls(), isTrue);
      });

      test('should reject invalid dimensions', () {
        final wrongHeight = List.generate(
          199, // Wrong height
          (z) => List.generate(100, (x) => TileType.floor),
        );

        expect(() => TileMap.fromTiles(wrongHeight), throwsArgumentError);

        final wrongWidth = List.generate(
          200,
          (z) => List.generate(99, (x) => TileType.floor), // Wrong width
        );

        expect(() => TileMap.fromTiles(wrongWidth), throwsArgumentError);
      });
    });
  });
}
