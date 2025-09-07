import 'dart:math';

import 'character.dart';
import 'enemy_character.dart';
import 'position.dart';

/// Spatial indexing system for efficient proximity queries in large worlds
class SpatialIndex {
  /// Size of each spatial grid cell (in tiles)
  final int cellSize;

  /// Width of the world in cells
  final int worldWidthInCells;

  /// Height of the world in cells
  final int worldHeightInCells;

  /// Grid of spatial cells containing character lists
  late final List<List<SpatialCell>> _grid;

  /// Map of character IDs to their current cell coordinates
  final Map<String, CellCoordinate> _characterCellMap = {};

  SpatialIndex({
    required int worldWidth,
    required int worldHeight,
    this.cellSize = 16, // 16x16 tile cells for good balance
  }) : worldWidthInCells = (worldWidth / cellSize).ceil(),
       worldHeightInCells = (worldHeight / cellSize).ceil() {
    _initializeGrid();
  }

  /// Initializes the spatial grid
  void _initializeGrid() {
    _grid = List.generate(
      worldHeightInCells,
      (z) => List.generate(worldWidthInCells, (x) => SpatialCell(x: x, z: z)),
    );
  }

  /// Converts world position to cell coordinate
  CellCoordinate _positionToCell(Position position) {
    final cellX = (position.x / cellSize).floor().clamp(
      0,
      worldWidthInCells - 1,
    );
    final cellZ = (position.z / cellSize).floor().clamp(
      0,
      worldHeightInCells - 1,
    );
    return CellCoordinate(cellX, cellZ);
  }

  /// Gets the spatial cell at the given cell coordinate
  SpatialCell? _getCell(CellCoordinate coord) {
    if (coord.x < 0 ||
        coord.x >= worldWidthInCells ||
        coord.z < 0 ||
        coord.z >= worldHeightInCells) {
      return null;
    }
    return _grid[coord.z][coord.x];
  }

  /// Adds a character to the spatial index
  void addCharacter(Character character) {
    final cellCoord = _positionToCell(character.position);
    final cell = _getCell(cellCoord);

    if (cell != null) {
      // Remove from old cell if it exists
      removeCharacter(character.id);

      // Add to new cell
      cell.addCharacter(character);
      _characterCellMap[character.id] = cellCoord;
    }
  }

  /// Removes a character from the spatial index
  void removeCharacter(String characterId) {
    final oldCellCoord = _characterCellMap[characterId];
    if (oldCellCoord != null) {
      final oldCell = _getCell(oldCellCoord);
      oldCell?.removeCharacter(characterId);
      _characterCellMap.remove(characterId);
    }
  }

  /// Updates a character's position in the spatial index
  void updateCharacterPosition(Character character) {
    final newCellCoord = _positionToCell(character.position);
    final oldCellCoord = _characterCellMap[character.id];

    // Only update if the character moved to a different cell
    if (oldCellCoord == null || oldCellCoord != newCellCoord) {
      addCharacter(character); // This will handle removal from old cell
    }
  }

  /// Gets all characters within a radius of a position
  List<T> getCharactersInRadius<T extends Character>(
    Position center,
    int radius, {
    Type? characterType,
  }) {
    final result = <T>[];
    final cellRadius =
        (radius / cellSize).ceil() + 1; // Add buffer for edge cases
    final centerCell = _positionToCell(center);

    // Check all cells within the radius
    for (int dz = -cellRadius; dz <= cellRadius; dz++) {
      for (int dx = -cellRadius; dx <= cellRadius; dx++) {
        final cellCoord = CellCoordinate(centerCell.x + dx, centerCell.z + dz);

        final cell = _getCell(cellCoord);
        if (cell != null) {
          // Get characters from this cell and filter by distance
          final cellCharacters = cell.getCharacters<T>(
            characterType: characterType,
          );

          for (final character in cellCharacters) {
            final distance = center.distanceTo(character.position);
            if (distance <= radius) {
              result.add(character);
            }
          }
        }
      }
    }

    return result;
  }

  /// Gets all enemies within a radius of a position
  List<EnemyCharacter> getEnemiesInRadius(Position center, int radius) {
    return getCharactersInRadius<EnemyCharacter>(
      center,
      radius,
      characterType: EnemyCharacter,
    );
  }

  /// Gets all characters in the same cell as a position
  List<T> getCharactersInCell<T extends Character>(
    Position position, {
    Type? characterType,
  }) {
    final cellCoord = _positionToCell(position);
    final cell = _getCell(cellCoord);

    if (cell != null) {
      return cell.getCharacters<T>(characterType: characterType);
    }

    return [];
  }

  /// Gets all characters in adjacent cells (including the center cell)
  List<T> getCharactersInAdjacentCells<T extends Character>(
    Position center, {
    Type? characterType,
  }) {
    final result = <T>[];
    final centerCell = _positionToCell(center);

    // Check 3x3 grid of cells
    for (int dz = -1; dz <= 1; dz++) {
      for (int dx = -1; dx <= 1; dx++) {
        final cellCoord = CellCoordinate(centerCell.x + dx, centerCell.z + dz);

        final cell = _getCell(cellCoord);
        if (cell != null) {
          result.addAll(cell.getCharacters<T>(characterType: characterType));
        }
      }
    }

    return result;
  }

  /// Gets the closest character to a position within a maximum radius
  T? getClosestCharacter<T extends Character>(
    Position position,
    int maxRadius, {
    Type? characterType,
  }) {
    final candidates = getCharactersInRadius<T>(
      position,
      maxRadius,
      characterType: characterType,
    );

    if (candidates.isEmpty) return null;

    T? closest;
    double closestDistance = double.infinity;

    for (final character in candidates) {
      final distance = position.distanceTo(character.position).toDouble();
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = character;
      }
    }

    return closest;
  }

  /// Clears all characters from the spatial index
  void clear() {
    for (final row in _grid) {
      for (final cell in row) {
        cell.clear();
      }
    }
    _characterCellMap.clear();
  }

  /// Gets statistics about the spatial index for debugging
  SpatialIndexStats getStats() {
    int totalCharacters = 0;
    int occupiedCells = 0;
    int maxCharactersInCell = 0;
    final cellOccupancy = <int, int>{};

    for (final row in _grid) {
      for (final cell in row) {
        final characterCount = cell.characterCount;
        totalCharacters += characterCount;

        if (characterCount > 0) {
          occupiedCells++;
          maxCharactersInCell = max(maxCharactersInCell, characterCount);
        }

        cellOccupancy[characterCount] =
            (cellOccupancy[characterCount] ?? 0) + 1;
      }
    }

    final totalCells = worldWidthInCells * worldHeightInCells;
    final occupancyPercentage = (occupiedCells / totalCells) * 100.0;
    final averageCharactersPerOccupiedCell = occupiedCells > 0
        ? totalCharacters / occupiedCells
        : 0.0;

    return SpatialIndexStats(
      totalCells: totalCells,
      occupiedCells: occupiedCells,
      totalCharacters: totalCharacters,
      maxCharactersInCell: maxCharactersInCell,
      occupancyPercentage: occupancyPercentage,
      averageCharactersPerOccupiedCell: averageCharactersPerOccupiedCell,
      cellOccupancyDistribution: Map.from(cellOccupancy),
    );
  }

  /// Gets debug information about a specific position
  SpatialDebugInfo getDebugInfo(Position position) {
    final cellCoord = _positionToCell(position);
    final cell = _getCell(cellCoord);

    return SpatialDebugInfo(
      position: position,
      cellCoordinate: cellCoord,
      charactersInCell: cell?.characterCount ?? 0,
      charactersInAdjacentCells: getCharactersInAdjacentCells(position).length,
    );
  }
}

/// Represents a single cell in the spatial grid
class SpatialCell {
  /// X coordinate of this cell in the grid
  final int x;

  /// Z coordinate of this cell in the grid
  final int z;

  /// Characters currently in this cell
  final Map<String, Character> _characters = {};

  SpatialCell({required this.x, required this.z});

  /// Adds a character to this cell
  void addCharacter(Character character) {
    _characters[character.id] = character;
  }

  /// Removes a character from this cell
  void removeCharacter(String characterId) {
    _characters.remove(characterId);
  }

  /// Gets all characters in this cell, optionally filtered by type
  List<T> getCharacters<T extends Character>({Type? characterType}) {
    final characters = _characters.values.toList();

    if (characterType != null) {
      return characters.whereType<T>().toList();
    }

    return characters.cast<T>();
  }

  /// Gets the number of characters in this cell
  int get characterCount => _characters.length;

  /// Checks if this cell is empty
  bool get isEmpty => _characters.isEmpty;

  /// Clears all characters from this cell
  void clear() {
    _characters.clear();
  }

  @override
  String toString() {
    return 'SpatialCell($x, $z) [${_characters.length} characters]';
  }
}

/// Represents coordinates in the spatial grid
class CellCoordinate {
  final int x;
  final int z;

  const CellCoordinate(this.x, this.z);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CellCoordinate && other.x == x && other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, z);

  @override
  String toString() => 'CellCoordinate($x, $z)';
}

/// Statistics about the spatial index
class SpatialIndexStats {
  final int totalCells;
  final int occupiedCells;
  final int totalCharacters;
  final int maxCharactersInCell;
  final double occupancyPercentage;
  final double averageCharactersPerOccupiedCell;
  final Map<int, int> cellOccupancyDistribution;

  const SpatialIndexStats({
    required this.totalCells,
    required this.occupiedCells,
    required this.totalCharacters,
    required this.maxCharactersInCell,
    required this.occupancyPercentage,
    required this.averageCharactersPerOccupiedCell,
    required this.cellOccupancyDistribution,
  });

  @override
  String toString() {
    return 'SpatialIndexStats(cells: $totalCells, occupied: $occupiedCells, '
        'characters: $totalCharacters, occupancy: ${occupancyPercentage.toStringAsFixed(1)}%)';
  }
}

/// Debug information for a specific position
class SpatialDebugInfo {
  final Position position;
  final CellCoordinate cellCoordinate;
  final int charactersInCell;
  final int charactersInAdjacentCells;

  const SpatialDebugInfo({
    required this.position,
    required this.cellCoordinate,
    required this.charactersInCell,
    required this.charactersInAdjacentCells,
  });

  @override
  String toString() {
    return 'SpatialDebugInfo(pos: $position, cell: $cellCoordinate, '
        'inCell: $charactersInCell, adjacent: $charactersInAdjacentCells)';
  }
}
