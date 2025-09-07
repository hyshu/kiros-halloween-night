/// Represents the different types of tiles in the game world
enum TileType {
  /// Empty floor tile that can be walked on
  floor,

  /// Wall tile that blocks movement
  wall,

  /// Obstacle tile that blocks movement but may have different visuals
  obstacle,

  /// Candy item tile that can be collected
  candy;

  /// Returns true if this tile type blocks movement
  bool get blocksMovement {
    switch (this) {
      case TileType.floor:
      case TileType.candy:
        return false;
      case TileType.wall:
      case TileType.obstacle:
        return true;
    }
  }

  /// Returns true if this tile type can be walked on
  bool get isWalkable => !blocksMovement;

  /// Returns true if this tile type is a collectible item
  bool get isCollectible {
    switch (this) {
      case TileType.candy:
        return true;
      case TileType.floor:
      case TileType.wall:
      case TileType.obstacle:
        return false;
    }
  }

  /// Returns a display name for this tile type
  String get displayName {
    switch (this) {
      case TileType.floor:
        return 'Floor';
      case TileType.wall:
        return 'Wall';
      case TileType.obstacle:
        return 'Obstacle';
      case TileType.candy:
        return 'Candy';
    }
  }
}
