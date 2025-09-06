import 'position.dart';
import 'tile_type.dart';

/// Manages the 200x400 tile grid world with boundary validation
class TileMap {
  /// World width in tiles
  static const int worldWidth = 200;
  
  /// World height in tiles  
  static const int worldHeight = 400;
  
  /// The 2D grid of tiles
  final List<List<TileType>> _tiles;
  
  /// Boss location in the world
  Position? _bossLocation;
  
  /// Player spawn location
  Position? _playerSpawn;

  /// Creates a new TileMap with all tiles initialized to floor
  TileMap() : _tiles = List.generate(
    worldHeight,
    (z) => List.generate(worldWidth, (x) => TileType.floor),
  ) {
    _initializePerimeterWalls();
  }

  /// Creates a TileMap from existing tile data
  TileMap.fromTiles(List<List<TileType>> tiles) : _tiles = tiles {
    if (tiles.length != worldHeight) {
      throw ArgumentError('Tile data must have exactly $worldHeight rows');
    }
    for (int z = 0; z < worldHeight; z++) {
      if (tiles[z].length != worldWidth) {
        throw ArgumentError('Row $z must have exactly $worldWidth columns');
      }
    }
    _validatePerimeterWalls();
  }

  /// Gets the tile type at the specified position
  TileType getTileAt(Position position) {
    if (!isValidPosition(position)) {
      return TileType.wall; // Out of bounds is treated as wall
    }
    return _tiles[position.z][position.x];
  }

  /// Sets the tile type at the specified position
  void setTileAt(Position position, TileType tileType) {
    if (!isValidPosition(position)) {
      throw ArgumentError('Position $position is out of bounds');
    }
    
    // Prevent modification of perimeter walls
    if (_isPerimeterPosition(position) && tileType != TileType.wall) {
      throw ArgumentError('Cannot modify perimeter wall at $position');
    }
    
    _tiles[position.z][position.x] = tileType;
  }

  /// Returns true if the position is within the world bounds
  bool isValidPosition(Position position) {
    return position.x >= 0 && 
           position.x < worldWidth && 
           position.z >= 0 && 
           position.z < worldHeight;
  }

  /// Returns true if the position is walkable (not blocked by walls or obstacles)
  bool isWalkable(Position position) {
    if (!isValidPosition(position)) {
      return false;
    }
    return getTileAt(position).isWalkable;
  }

  /// Returns true if the position blocks movement
  bool blocksMovement(Position position) {
    return !isWalkable(position);
  }

  /// Returns true if the position contains a collectible item
  bool hasCollectible(Position position) {
    if (!isValidPosition(position)) {
      return false;
    }
    return getTileAt(position).isCollectible;
  }

  /// Gets all positions of a specific tile type
  List<Position> getPositionsOfType(TileType tileType) {
    final positions = <Position>[];
    for (int z = 0; z < worldHeight; z++) {
      for (int x = 0; x < worldWidth; x++) {
        if (_tiles[z][x] == tileType) {
          positions.add(Position(x, z));
        }
      }
    }
    return positions;
  }

  /// Gets all walkable positions adjacent to the given position
  List<Position> getWalkableAdjacentPositions(Position position) {
    final adjacent = <Position>[];
    final directions = [
      Position(0, -1), // North
      Position(1, 0),  // East
      Position(0, 1),  // South
      Position(-1, 0), // West
    ];

    for (final direction in directions) {
      final newPosition = Position(
        position.x + direction.x,
        position.z + direction.z,
      );
      if (isWalkable(newPosition)) {
        adjacent.add(newPosition);
      }
    }
    return adjacent;
  }

  /// Gets the boss location (null if not set)
  Position? get bossLocation => _bossLocation;

  /// Sets the boss location
  void setBossLocation(Position position) {
    if (!isValidPosition(position)) {
      throw ArgumentError('Boss location must be within world bounds');
    }
    _bossLocation = position;
  }

  /// Gets the player spawn location (null if not set)
  Position? get playerSpawn => _playerSpawn;

  /// Sets the player spawn location
  void setPlayerSpawn(Position position) {
    if (!isValidPosition(position)) {
      throw ArgumentError('Player spawn must be within world bounds');
    }
    _playerSpawn = position;
  }

  /// Gets the world dimensions
  (int width, int height) get dimensions => (worldWidth, worldHeight);

  /// Gets a copy of the tile grid (for read-only access)
  List<List<TileType>> get tiles => _tiles.map((row) => List<TileType>.from(row)).toList();

  /// Validates that the entire perimeter consists of walls with no gaps
  bool validatePerimeterWalls() {
    try {
      _validatePerimeterWalls();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns true if the given position is on the world perimeter
  bool isPerimeterPosition(Position position) {
    return _isPerimeterPosition(position);
  }

  /// Gets all perimeter positions
  List<Position> getPerimeterPositions() {
    final positions = <Position>[];
    
    // Top and bottom edges
    for (int x = 0; x < worldWidth; x++) {
      positions.add(Position(x, 0)); // Top edge
      positions.add(Position(x, worldHeight - 1)); // Bottom edge
    }
    
    // Left and right edges (excluding corners already added)
    for (int z = 1; z < worldHeight - 1; z++) {
      positions.add(Position(0, z)); // Left edge
      positions.add(Position(worldWidth - 1, z)); // Right edge
    }
    
    return positions;
  }

  /// Initializes the perimeter walls to ensure no escape gaps
  void _initializePerimeterWalls() {
    // Set top and bottom edges to walls
    for (int x = 0; x < worldWidth; x++) {
      _tiles[0][x] = TileType.wall; // Top edge
      _tiles[worldHeight - 1][x] = TileType.wall; // Bottom edge
    }
    
    // Set left and right edges to walls
    for (int z = 0; z < worldHeight; z++) {
      _tiles[z][0] = TileType.wall; // Left edge
      _tiles[z][worldWidth - 1] = TileType.wall; // Right edge
    }
  }

  /// Validates that all perimeter positions are walls
  void _validatePerimeterWalls() {
    final perimeterPositions = getPerimeterPositions();
    
    for (final position in perimeterPositions) {
      if (getTileAt(position) != TileType.wall) {
        throw StateError(
          'Perimeter validation failed: position $position is not a wall '
          '(found ${getTileAt(position).displayName})'
        );
      }
    }
  }

  /// Returns true if the position is on the world perimeter
  bool _isPerimeterPosition(Position position) {
    return position.x == 0 || 
           position.x == worldWidth - 1 || 
           position.z == 0 || 
           position.z == worldHeight - 1;
  }

  @override
  String toString() {
    return 'TileMap(${worldWidth}x$worldHeight, '
           'boss: $bossLocation, spawn: $playerSpawn)';
  }
}