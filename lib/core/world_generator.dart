import 'dart:math' as math;
import 'position.dart';
import 'tile_map.dart';
import 'tile_type.dart';

/// Represents a room in the roguelike world
class Room {
  final int x;
  final int z;
  final int width;
  final int height;

  Room(this.x, this.z, this.width, this.height);

  Position get center => Position(x + width ~/ 2, z + height ~/ 2);

  bool contains(Position position) {
    return position.x >= x &&
        position.x < x + width &&
        position.z >= z &&
        position.z < z + height;
  }

  bool overlaps(Room other) {
    return x < other.x + other.width &&
        x + width > other.x &&
        z < other.z + other.height &&
        z + height > other.z;
  }
}

/// Generates procedural worlds with maze-like pathways and guaranteed pathfinding
class WorldGenerator {
  final math.Random _random;
  final bool _isTestMode;

  /// Creates a new WorldGenerator with optional seed for reproducible generation
  WorldGenerator({int? seed, bool isTestMode = false})
    : _random = math.Random(seed),
      _isTestMode = isTestMode;

  /// Generates a complete roguelike world with rooms and corridors
  /// Returns a TileMap with guaranteed path from spawn to boss location
  TileMap generateWorld() {
    final tileMap = TileMap();

    // Use fixed spawn and boss locations
    final spawnLocation = const Position(10, 390);
    final bossLocation = const Position(190, 10);

    // Generate roguelike room and corridor structure
    final rooms = _generateRoomsAndCorridors(tileMap);

    // Set fixed spawn and boss locations
    tileMap.setTileAt(spawnLocation, TileType.floor);
    tileMap.setPlayerSpawn(spawnLocation);
    tileMap.setTileAt(bossLocation, TileType.floor);
    tileMap.setBossLocation(bossLocation);

    // Always create guaranteed path first - before obstacles
    _createGuaranteedPath(tileMap, spawnLocation, bossLocation);

    // Add some obstacles and candy items
    _addObstacles(tileMap, rooms);
    _addCandyItems(tileMap);

    // Final path validation - ensure path still exists after obstacles
    if (!_validatePath(tileMap, spawnLocation, bossLocation)) {
      // If path was broken by obstacles, recreate it
      _createGuaranteedPath(tileMap, spawnLocation, bossLocation);
    }

    return tileMap;
  }

  /// Generates roguelike rooms and corridors utilizing the full 200x400 world space
  List<Room> _generateRoomsAndCorridors(TileMap tileMap) {
    // In test mode, create a simpler world with fewer rooms
    if (_isTestMode) {
      return _generateSimpleRoomWorld(tileMap);
    }

    // Start with all interior tiles as walls (perimeter is already walls)
    for (int z = 1; z < TileMap.worldHeight - 1; z++) {
      for (int x = 1; x < TileMap.worldWidth - 1; x++) {
        tileMap.setTileAt(Position(x, z), TileType.wall);
      }
    }

    final rooms = <Room>[];
    final maxRooms = 50;
    final minRoomSize = 8;
    final maxRoomSize = 20;
    final roomPadding = 2;

    final spawnRoom = Room(5, 385, 15, 15); // Room around spawn
    final bossRoom = Room(185, 5, 15, 15); // Room around boss
    rooms.addAll([spawnRoom, bossRoom]);

    // Carve rooms - ensure they have floor tiles inside
    _carveRoom(tileMap, spawnRoom);
    _carveRoom(tileMap, bossRoom);

    int attempts = 0;
    final maxAttempts = 2000;

    // Generate additional non-overlapping rooms across the large world
    while (rooms.length < maxRooms && attempts < maxAttempts) {
      attempts++;

      final width = minRoomSize + _random.nextInt(maxRoomSize - minRoomSize);
      final height = minRoomSize + _random.nextInt(maxRoomSize - minRoomSize);

      // Use the full 200x400 space for room placement
      final x =
          roomPadding +
          _random.nextInt(TileMap.worldWidth - width - roomPadding * 2);
      final z =
          roomPadding +
          _random.nextInt(TileMap.worldHeight - height - roomPadding * 2);

      final newRoom = Room(x, z, width, height);

      bool overlaps = false;
      for (final existingRoom in rooms) {
        if (newRoom.overlaps(existingRoom)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        rooms.add(newRoom);
        _carveRoom(tileMap, newRoom);
      }
    }

    // Connect rooms with corridors
    _connectRoomsWithCorridors(tileMap, rooms);

    return rooms;
  }

  /// Carves out a room by setting its interior to floor tiles
  void _carveRoom(TileMap tileMap, Room room) {
    // Skip rooms that are too small to have an interior
    if (room.width <= 2 || room.height <= 2) return;

    for (int z = room.z + 1; z < room.z + room.height - 1; z++) {
      for (int x = room.x + 1; x < room.x + room.width - 1; x++) {
        final position = Position(x, z);
        if (tileMap.isValidPosition(position) &&
            !tileMap.isPerimeterPosition(position)) {
          tileMap.setTileAt(position, TileType.floor);
        }
      }
    }

    // Ensure spawn and boss locations are definitely floor tiles
    const spawnLocation = Position(10, 390);
    const bossLocation = Position(190, 10);
    if (tileMap.isValidPosition(spawnLocation) &&
        !tileMap.isPerimeterPosition(spawnLocation)) {
      tileMap.setTileAt(spawnLocation, TileType.floor);
    }
    if (tileMap.isValidPosition(bossLocation) &&
        !tileMap.isPerimeterPosition(bossLocation)) {
      tileMap.setTileAt(bossLocation, TileType.floor);
    }
  }

  /// Connects rooms with L-shaped corridors using nearest neighbor approach
  void _connectRoomsWithCorridors(TileMap tileMap, List<Room> rooms) {
    if (rooms.isEmpty) return;

    // Connect each room to its nearest unconnected neighbor
    final connected = <Room>{rooms.first};
    final unconnected = Set<Room>.from(rooms.skip(1));

    while (unconnected.isNotEmpty) {
      Room? nearestRoom;
      Room? nearestConnected;
      double shortestDistance = double.infinity;

      // Find the shortest connection between connected and unconnected rooms
      for (final connectedRoom in connected) {
        for (final unconnectedRoom in unconnected) {
          final distance = connectedRoom.center
              .distanceTo(unconnectedRoom.center)
              .toDouble();
          if (distance < shortestDistance) {
            shortestDistance = distance;
            nearestRoom = unconnectedRoom;
            nearestConnected = connectedRoom;
          }
        }
      }

      if (nearestRoom != null && nearestConnected != null) {
        _createCorridor(tileMap, nearestConnected.center, nearestRoom.center);
        connected.add(nearestRoom);
        unconnected.remove(nearestRoom);
      } else {
        break; // Safety break
      }
    }

    // Add a few extra connections for redundancy (shorter ones)
    for (int i = 0; i < rooms.length && i < 5; i++) {
      final room = rooms[i];
      Room? nearestRoom;
      double shortestDistance = double.infinity;

      for (int j = 0; j < rooms.length; j++) {
        if (i == j) continue;
        final otherRoom = rooms[j];
        final distance = room.center.distanceTo(otherRoom.center).toDouble();
        if (distance < shortestDistance && distance < 30) {
          // Very short connections only
          shortestDistance = distance;
          nearestRoom = otherRoom;
        }
      }

      if (nearestRoom != null) {
        _createCorridor(tileMap, room.center, nearestRoom.center);
      }
    }
  }

  /// Creates an L-shaped corridor between two points with 1-tile width
  void _createCorridor(TileMap tileMap, Position start, Position end) {
    final corridorWidth = 1; // 1-tile wide corridors for strategic movement

    // Decide whether to go horizontal first or vertical first randomly
    final horizontalFirst = _random.nextBool();

    if (horizontalFirst) {
      // Horizontal then vertical
      _carveHorizontalCorridor(tileMap, start.x, end.x, start.z, corridorWidth);
      _carveVerticalCorridor(tileMap, end.x, start.z, end.z, corridorWidth);
    } else {
      // Vertical then horizontal
      _carveVerticalCorridor(tileMap, start.x, start.z, end.z, corridorWidth);
      _carveHorizontalCorridor(tileMap, start.x, end.x, end.z, corridorWidth);
    }
  }

  /// Carves a horizontal corridor with 1-tile width
  void _carveHorizontalCorridor(
    TileMap tileMap,
    int x1,
    int x2,
    int z,
    int width,
  ) {
    final minX = math.min(x1, x2);
    final maxX = math.max(x1, x2);

    for (int x = minX; x <= maxX; x++) {
      // For 1-tile width, only carve the center line
      final position = Position(x, z);
      if (tileMap.isValidPosition(position) &&
          !tileMap.isPerimeterPosition(position)) {
        tileMap.setTileAt(position, TileType.floor);
      }
    }
  }

  /// Carves a vertical corridor with 1-tile width
  void _carveVerticalCorridor(
    TileMap tileMap,
    int x,
    int z1,
    int z2,
    int width,
  ) {
    final minZ = math.min(z1, z2);
    final maxZ = math.max(z1, z2);

    for (int z = minZ; z <= maxZ; z++) {
      // For 1-tile width, only carve the center line
      final position = Position(x, z);
      if (tileMap.isValidPosition(position) &&
          !tileMap.isPerimeterPosition(position)) {
        tileMap.setTileAt(position, TileType.floor);
      }
    }
  }

  /// Generates a simple room-based test world
  List<Room> _generateSimpleRoomWorld(TileMap tileMap) {
    final rooms = <Room>[];

    // Create rooms around the fixed spawn and boss locations (well within boundaries)
    final room1 = Room(
      5,
      380,
      15,
      18,
    ); // Room around spawn (10, 390) - z from 380-397
    final room2 = Room(
      180,
      5,
      18,
      15,
    ); // Room around boss (190, 10) - x from 180-197

    // Start with all walls
    for (int z = 1; z < TileMap.worldHeight - 1; z++) {
      for (int x = 1; x < TileMap.worldWidth - 1; x++) {
        tileMap.setTileAt(Position(x, z), TileType.wall);
      }
    }

    rooms.addAll([room1, room2]);

    // Carve out rooms AFTER setting walls
    for (final room in rooms) {
      _carveRoom(tileMap, room);
    }

    // For test mode, create a simple direct floor path between fixed positions
    const start = Position(10, 390);
    const end = Position(190, 10);

    // Create horizontal path
    final minX = math.min(start.x, end.x);
    final maxX = math.max(start.x, end.x);
    for (int x = minX; x <= maxX; x++) {
      tileMap.setTileAt(Position(x, start.z), TileType.floor);
    }

    // Create vertical path
    final minZ = math.min(start.z, end.z);
    final maxZ = math.max(start.z, end.z);
    for (int z = minZ; z <= maxZ; z++) {
      tileMap.setTileAt(Position(end.x, z), TileType.floor);
    }

    return rooms;
  }

  /// Validates that a path exists between two positions using optimized BFS
  bool _validatePath(TileMap tileMap, Position start, Position end) {
    if (start == end) return true;

    // Use integer keys for faster Set operations
    final visited = <int>{};
    final queue = <Position>[start];
    final startKey = start.x * 1000 + start.z;
    visited.add(startKey);

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      if (current == end) {
        return true;
      }

      for (final neighbor in tileMap.getWalkableAdjacentPositions(current)) {
        final neighborKey = neighbor.x * 1000 + neighbor.z;
        if (!visited.contains(neighborKey)) {
          visited.add(neighborKey);
          queue.add(neighbor);
        }
      }
    }

    return false;
  }

  /// Creates a guaranteed path between two positions using A* pathfinding
  void _createGuaranteedPath(TileMap tileMap, Position start, Position end) {
    List<Position> path = _findPath(tileMap, start, end);

    // If A* fails, create a simple L-shaped path
    if (path.isEmpty) {
      path = _createSimplePath(start, end);
    }

    // Clear the path by setting all positions to floor
    for (final position in path) {
      if (tileMap.isValidPosition(position) &&
          !tileMap.isPerimeterPosition(position)) {
        tileMap.setTileAt(position, TileType.floor);
      }
    }
  }

  /// Creates a simple L-shaped path between two positions
  List<Position> _createSimplePath(Position start, Position end) {
    final path = <Position>[start];

    // First, move horizontally
    int currentX = start.x;
    final int targetX = end.x;
    final int deltaX = targetX > currentX ? 1 : -1;

    while (currentX != targetX) {
      currentX += deltaX;
      path.add(Position(currentX, start.z));
    }

    // Then, move vertically
    int currentZ = start.z;
    final int targetZ = end.z;
    final int deltaZ = targetZ > currentZ ? 1 : -1;

    while (currentZ != targetZ) {
      currentZ += deltaZ;
      path.add(Position(targetX, currentZ));
    }

    return path;
  }

  /// Finds a path between two positions using A* algorithm
  List<Position> _findPath(TileMap tileMap, Position start, Position end) {
    final openSet = <Position>[start];
    final cameFrom = <Position, Position>{};
    final gScore = <Position, int>{start: 0};
    final fScore = <Position, int>{start: start.distanceTo(end)};
    int iterations = 0;
    final maxIterations = 5000; // Limit A* iterations to prevent infinite loops

    while (openSet.isNotEmpty && iterations < maxIterations) {
      iterations++;

      // Find position with lowest fScore
      Position current = openSet.first;
      for (final position in openSet) {
        if ((fScore[position] ?? double.maxFinite.toInt()) <
            (fScore[current] ?? double.maxFinite.toInt())) {
          current = position;
        }
      }

      if (current == end) {
        // Reconstruct path
        final path = <Position>[current];
        while (cameFrom.containsKey(current)) {
          current = cameFrom[current]!;
          path.insert(0, current);
        }
        return path;
      }

      openSet.remove(current);

      // Check all neighbors (including walls for path creation)
      final neighbors = _getAllNeighbors(current);
      for (final neighbor in neighbors) {
        if (!tileMap.isValidPosition(neighbor) ||
            tileMap.isPerimeterPosition(neighbor)) {
          continue;
        }

        final tentativeGScore =
            (gScore[current] ?? double.maxFinite.toInt()) + 1;

        if (tentativeGScore < (gScore[neighbor] ?? double.maxFinite.toInt())) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] = tentativeGScore + neighbor.distanceTo(end);

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }

    // No path found or timeout, return direct line
    return _createDirectPath(start, end);
  }

  /// Gets all adjacent neighbors (including diagonal)
  List<Position> _getAllNeighbors(Position position) {
    return [
      Position(position.x, position.z - 1), // North
      Position(position.x + 1, position.z), // East
      Position(position.x, position.z + 1), // South
      Position(position.x - 1, position.z), // West
    ];
  }

  /// Creates an L-shaped path between two positions (no diagonal movement)
  List<Position> _createDirectPath(Position start, Position end) {
    final path = <Position>[start];

    // First, move horizontally to align X coordinate
    int currentX = start.x;
    final int targetX = end.x;
    final int deltaX = targetX > currentX ? 1 : -1;

    while (currentX != targetX) {
      currentX += deltaX;
      path.add(Position(currentX, start.z));
    }

    // Then, move vertically to reach the end position
    int currentZ = start.z;
    final int targetZ = end.z;
    final int deltaZ = targetZ > currentZ ? 1 : -1;

    while (currentZ != targetZ) {
      currentZ += deltaZ;
      path.add(Position(targetX, currentZ));
    }

    return path;
  }

  /// Adds obstacles to rooms using optimized batch placement
  void _addObstacles(TileMap tileMap, List<Room> rooms) {
    if (_isTestMode) {
      _addObstaclesSimple(tileMap);
      return;
    }

    // Use optimized batch placement approach
    _addObstaclesOptimized(tileMap, rooms);
  }

  /// Simplified obstacle placement for test mode
  void _addObstaclesSimple(TileMap tileMap) {
    final obstacleCount = 15;
    final candidatePositions = <Position>[];

    // Collect all valid floor positions
    for (int z = 20; z < TileMap.worldHeight - 20; z++) {
      for (int x = 20; x < TileMap.worldWidth - 20; x++) {
        final position = Position(x, z);
        if (tileMap.getTileAt(position) == TileType.floor &&
            position != tileMap.playerSpawn &&
            position != tileMap.bossLocation) {
          candidatePositions.add(position);
        }
      }
    }

    // Batch place obstacles
    candidatePositions.shuffle(_random);
    final placementCount = (obstacleCount).clamp(0, candidatePositions.length);

    for (int i = 0; i < placementCount; i++) {
      tileMap.setTileAt(candidatePositions[i], TileType.obstacle);
    }

    // Validate path after placing obstacles (same as optimized version)
    if (tileMap.playerSpawn != null && tileMap.bossLocation != null) {
      if (!_validatePath(
        tileMap,
        tileMap.playerSpawn!,
        tileMap.bossLocation!,
      )) {
        // If path is broken, create guaranteed path
        _createGuaranteedPath(
          tileMap,
          tileMap.playerSpawn!,
          tileMap.bossLocation!,
        );
      }
    }
  }

  /// Optimized obstacle placement using batch approach with safety checks
  void _addObstaclesOptimized(TileMap tileMap, List<Room> rooms) {
    final candidatePositions = <Position>[];

    // Step 1: Collect all valid obstacle positions from rooms
    for (final room in rooms) {
      // Place obstacles only in room interiors, not on edges or near corridors
      for (int z = room.z + 2; z < room.z + room.height - 2; z++) {
        for (int x = room.x + 2; x < room.x + room.width - 2; x++) {
          final position = Position(x, z);
          if (tileMap.getTileAt(position) == TileType.floor &&
              position != tileMap.playerSpawn &&
              position != tileMap.bossLocation &&
              _isSafeObstaclePosition(tileMap, position)) {
            candidatePositions.add(position);
          }
        }
      }
    }

    if (candidatePositions.isEmpty) return;

    // Step 2: Conservative batch placement (use only 1/4 of candidates)
    candidatePositions.shuffle(_random);
    final targetCount = (candidatePositions.length ~/ 4).clamp(0, 80);

    for (int i = 0; i < targetCount; i++) {
      final position = candidatePositions[i];
      tileMap.setTileAt(position, TileType.obstacle);
    }

    // Step 3: Single path validation after batch placement
    if (tileMap.playerSpawn != null && tileMap.bossLocation != null) {
      if (!_validatePath(
        tileMap,
        tileMap.playerSpawn!,
        tileMap.bossLocation!,
      )) {
        // If path is broken, create guaranteed path
        _createGuaranteedPath(
          tileMap,
          tileMap.playerSpawn!,
          tileMap.bossLocation!,
        );
      }
    }
  }

  /// Checks if a position is safe for obstacle placement (not blocking critical paths)
  bool _isSafeObstaclePosition(TileMap tileMap, Position position) {
    // Count walkable neighbors - if too few, this might be a chokepoint
    int walkableNeighbors = 0;
    for (final neighbor in [
      Position(position.x - 1, position.z),
      Position(position.x + 1, position.z),
      Position(position.x, position.z - 1),
      Position(position.x, position.z + 1),
    ]) {
      if (tileMap.isValidPosition(neighbor) &&
          tileMap.getTileAt(neighbor) == TileType.floor) {
        walkableNeighbors++;
      }
    }

    // Only place obstacle if position has enough walkable neighbors
    return walkableNeighbors >= 3;
  }

  /// Adds candy items throughout the rooms and corridors
  void _addCandyItems(TileMap tileMap) {
    if (_isTestMode) {
      // Place candy in known floor positions for tests
      final candyPositions = [
        Position(9, 389), // Near spawn
        Position(11, 391), // Near spawn
        Position(189, 9), // Near boss
        Position(191, 11), // Near boss
        Position(50, 390), // On path
        Position(100, 390), // On path
        Position(150, 390), // On path
        Position(190, 100), // On vertical path
      ];

      for (final position in candyPositions) {
        if (tileMap.getTileAt(position) == TileType.floor &&
            position != tileMap.playerSpawn &&
            position != tileMap.bossLocation) {
          tileMap.setTileAt(position, TileType.candy);
        }
      }
      return;
    }

    // Place candy throughout floor areas (rooms and corridors)
    final candyCount = 150; // Increased for 50 rooms
    int placed = 0;
    int attempts = 0;
    final maxAttempts = candyCount * 20;

    while (placed < candyCount && attempts < maxAttempts) {
      attempts++;

      final x = 1 + _random.nextInt(TileMap.worldWidth - 2);
      final z = 1 + _random.nextInt(TileMap.worldHeight - 2);
      final position = Position(x, z);

      // Only place candy on floor tiles that aren't spawn or boss locations
      if (tileMap.getTileAt(position) == TileType.floor &&
          position != tileMap.playerSpawn &&
          position != tileMap.bossLocation) {
        tileMap.setTileAt(position, TileType.candy);
        placed++;
      }
    }
  }

  /// Generates a world with specific parameters for testing
  TileMap generateTestWorld({
    required Position spawnLocation,
    required Position bossLocation,
    bool ensurePath = true,
  }) {
    final tileMap = TileMap();

    // Create a simple path for testing
    tileMap.setTileAt(spawnLocation, TileType.floor);
    tileMap.setTileAt(bossLocation, TileType.floor);
    tileMap.setPlayerSpawn(spawnLocation);
    tileMap.setBossLocation(bossLocation);

    if (ensurePath) {
      _createGuaranteedPath(tileMap, spawnLocation, bossLocation);
    }

    return tileMap;
  }
}
