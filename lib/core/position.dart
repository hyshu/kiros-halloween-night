/// Represents a position in the game world grid
class Position {
  final int x;
  final int z;

  const Position(this.x, this.z);

  /// Creates a position at the origin (0, 0)
  const Position.origin() : x = 0, z = 0;

  /// Creates a new position by adding the given offsets
  Position add(int dx, int dz) => Position(x + dx, z + dz);

  /// Creates a new position by subtracting the given offsets
  Position subtract(int dx, int dz) => Position(x - dx, z - dz);

  /// Returns the Manhattan distance to another position
  int distanceTo(Position other) {
    return (x - other.x).abs() + (z - other.z).abs();
  }

  /// Returns true if this position is adjacent to another position
  bool isAdjacentTo(Position other) {
    return distanceTo(other) == 1;
  }

  /// Returns true if this position is within the given bounds
  bool isWithinBounds(int width, int height) {
    return x >= 0 && x < width && z >= 0 && z < height;
  }

  /// Returns the world coordinates for 3D rendering
  /// Each grid cell is 2.0 units apart in world space
  (double x, double y, double z) toWorldCoordinates() {
    return (x * 2.0, 0.0, z * 2.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.x == x && other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, z);

  @override
  String toString() => 'Position($x, $z)';
}
