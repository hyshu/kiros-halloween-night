import 'dart:math';
import 'candy_item.dart';
import 'position.dart';
import 'tile_map.dart';
import 'tile_type.dart';

/// Manages the spawning of candy items throughout the world map
class CandySpawner {
  /// Random number generator for candy placement
  final Random _random;

  /// Counter for generating unique candy IDs
  int _candyIdCounter = 0;

  /// Probability of spawning candy on a floor tile (0.0 to 1.0)
  final double spawnProbability;

  /// Minimum distance between candy items
  final int minDistanceBetweenCandy;

  /// Maximum number of candy items to spawn
  final int maxCandyCount;

  CandySpawner({
    Random? random,
    this.spawnProbability = 0.02, // 2% chance per floor tile
    this.minDistanceBetweenCandy = 3,
    this.maxCandyCount = 200,
  }) : _random = random ?? Random();

  /// Spawns candy items randomly across the map during generation
  /// Returns a list of spawned candy items with their positions
  List<CandyItem> spawnCandyOnMap(TileMap tileMap) {
    final spawnedCandy = <CandyItem>[];
    final occupiedPositions = <Position>[];

    // Get all floor tiles that could potentially have candy
    final floorTiles = _getFloorTiles(tileMap);

    // Shuffle the floor tiles for random placement
    floorTiles.shuffle(_random);

    for (final position in floorTiles) {
      // Check if we've reached the maximum candy count
      if (spawnedCandy.length >= maxCandyCount) {
        break;
      }

      // Check spawn probability
      if (_random.nextDouble() > spawnProbability) {
        continue;
      }

      // Check minimum distance from other candy
      if (_isTooCloseToOtherCandy(position, occupiedPositions)) {
        continue;
      }

      // Spawn candy at this position
      final candy = _createRandomCandy(position);
      spawnedCandy.add(candy);
      occupiedPositions.add(position);

      // Update the tile map to mark this position as having candy
      tileMap.setTileAt(position, TileType.candy);
    }

    return spawnedCandy;
  }

  /// Spawns candy items at specific positions
  /// Useful for placing candy at predetermined locations
  List<CandyItem> spawnCandyAtPositions(List<Position> positions) {
    final spawnedCandy = <CandyItem>[];

    for (final position in positions) {
      final candy = _createRandomCandy(position);
      spawnedCandy.add(candy);
    }

    return spawnedCandy;
  }

  /// Creates a single random candy item at the specified position
  CandyItem createRandomCandyAt(Position position) {
    return _createRandomCandy(position);
  }

  /// Gets all floor tiles from the tile map
  List<Position> _getFloorTiles(TileMap tileMap) {
    final floorTiles = <Position>[];

    for (int x = 0; x < TileMap.worldWidth; x++) {
      for (int z = 0; z < TileMap.worldHeight; z++) {
        final position = Position(x, z);
        if (tileMap.getTileAt(position) == TileType.floor) {
          floorTiles.add(position);
        }
      }
    }

    return floorTiles;
  }

  /// Checks if a position is too close to other candy items
  bool _isTooCloseToOtherCandy(
    Position position,
    List<Position> occupiedPositions,
  ) {
    for (final occupied in occupiedPositions) {
      final distance = _calculateDistance(position, occupied);
      if (distance < minDistanceBetweenCandy) {
        return true;
      }
    }
    return false;
  }

  /// Calculates Manhattan distance between two positions
  int _calculateDistance(Position a, Position b) {
    return (a.x - b.x).abs() + (a.z - b.z).abs();
  }

  /// Creates a random candy item at the specified position
  CandyItem _createRandomCandy(Position position) {
    final candyTypes = CandyType.values;
    final randomType = candyTypes[_random.nextInt(candyTypes.length)];
    final candyId = 'candy_${_candyIdCounter++}';

    return CandyItem.create(randomType, candyId, position: position);
  }

  /// Spawns candy with weighted probabilities for different types
  /// More common candy types have higher weights
  CandyItem createWeightedRandomCandyAt(Position position) {
    final weights = <CandyType, int>{
      CandyType.candyBar: 20, // Common health boost
      CandyType.donut: 15, // Common health boost
      CandyType.cookie: 10, // Speed boost
      CandyType.muffin: 15, // Large health boost
      CandyType.popsicle: 12, // Small health boost
      CandyType.chocolate: 8, // Max health increase (rare)
      CandyType.cupcake: 8, // Ally strength (rare)
      CandyType.lollipop: 6, // Luck boost (rare)
      CandyType.iceCream: 4, // Special ability (very rare)
      CandyType.gingerbread: 2, // Special ability (very rare)
    };

    final totalWeight = weights.values.reduce((a, b) => a + b);
    final randomValue = _random.nextInt(totalWeight);

    int currentWeight = 0;
    for (final entry in weights.entries) {
      currentWeight += entry.value;
      if (randomValue < currentWeight) {
        final candyId = 'candy_${_candyIdCounter++}';
        return CandyItem.create(entry.key, candyId, position: position);
      }
    }

    // Fallback (should never reach here)
    final candyId = 'candy_${_candyIdCounter++}';
    return CandyItem.create(CandyType.candyBar, candyId, position: position);
  }

  /// Spawns candy using weighted probabilities
  List<CandyItem> spawnWeightedCandyOnMap(TileMap tileMap) {
    final spawnedCandy = <CandyItem>[];
    final occupiedPositions = <Position>[];

    // Get all floor tiles that could potentially have candy
    final floorTiles = _getFloorTiles(tileMap);

    // Shuffle the floor tiles for random placement
    floorTiles.shuffle(_random);

    for (final position in floorTiles) {
      // Check if we've reached the maximum candy count
      if (spawnedCandy.length >= maxCandyCount) {
        break;
      }

      // Check spawn probability
      if (_random.nextDouble() > spawnProbability) {
        continue;
      }

      // Check minimum distance from other candy
      if (_isTooCloseToOtherCandy(position, occupiedPositions)) {
        continue;
      }

      // Spawn weighted candy at this position
      final candy = createWeightedRandomCandyAt(position);
      spawnedCandy.add(candy);
      occupiedPositions.add(position);

      // Update the tile map to mark this position as having candy
      tileMap.setTileAt(position, TileType.candy);
    }

    return spawnedCandy;
  }

  /// Gets statistics about candy spawning
  Map<String, dynamic> getSpawnStatistics(List<CandyItem> spawnedCandy) {
    final typeCount = <String, int>{};
    final effectCount = <String, int>{};

    for (final candy in spawnedCandy) {
      // Count by candy name
      typeCount[candy.name] = (typeCount[candy.name] ?? 0) + 1;

      // Count by effect type
      final effectName = candy.effect.name;
      effectCount[effectName] = (effectCount[effectName] ?? 0) + 1;
    }

    return {
      'totalCount': spawnedCandy.length,
      'typeDistribution': typeCount,
      'effectDistribution': effectCount,
      'spawnProbability': spawnProbability,
      'minDistance': minDistanceBetweenCandy,
      'maxCount': maxCandyCount,
    };
  }

  /// Resets the candy ID counter (useful for testing)
  void resetIdCounter() {
    _candyIdCounter = 0;
  }
}
