import 'package:flutter/foundation.dart';
import 'candy_item.dart';
import 'ghost_character.dart';
import 'position.dart';
import 'tile_map.dart';
import 'tile_type.dart';

/// Event data for candy collection
class CandyCollectionEvent {
  /// The candy item that was collected
  final CandyItem candy;
  
  /// The position where the candy was collected
  final Position position;
  
  /// The character who collected the candy
  final GhostCharacter character;
  
  /// Whether the collection was successful
  final bool successful;
  
  /// Reason for failure (if not successful)
  final String? failureReason;

  CandyCollectionEvent({
    required this.candy,
    required this.position,
    required this.character,
    required this.successful,
    this.failureReason,
  });

  @override
  String toString() {
    if (successful) {
      return 'Collected ${candy.name} at $position';
    } else {
      return 'Failed to collect ${candy.name} at $position: $failureReason';
    }
  }
}

/// Manages automatic candy collection when characters move onto candy tiles
class CandyCollectionSystem extends ChangeNotifier {
  /// Map of candy items by their position
  final Map<Position, CandyItem> _candyByPosition = {};
  
  /// List of all candy items in the world
  final List<CandyItem> _allCandy = [];
  
  /// Recent collection events for feedback
  final List<CandyCollectionEvent> _recentEvents = [];
  
  /// Maximum number of recent events to keep
  final int maxRecentEvents;

  CandyCollectionSystem({this.maxRecentEvents = 10});

  /// Gets all candy items in the world
  List<CandyItem> get allCandy => List.unmodifiable(_allCandy);
  
  /// Gets recent collection events
  List<CandyCollectionEvent> get recentEvents => List.unmodifiable(_recentEvents);
  
  /// Gets the number of candy items remaining in the world
  int get remainingCandyCount => _allCandy.where((c) => !c.isCollected).length;

  /// Adds candy items to the collection system
  void addCandy(List<CandyItem> candyItems) {
    for (final candy in candyItems) {
      if (candy.position != null) {
        _candyByPosition[candy.position!] = candy;
        _allCandy.add(candy);
      }
    }
    notifyListeners();
  }

  /// Adds a single candy item to the collection system
  void addSingleCandy(CandyItem candy) {
    if (candy.position != null) {
      _candyByPosition[candy.position!] = candy;
      _allCandy.add(candy);
      notifyListeners();
    }
  }

  /// Removes a candy item from the collection system
  void removeCandy(CandyItem candy) {
    if (candy.position != null) {
      _candyByPosition.remove(candy.position!);
    }
    _allCandy.remove(candy);
    notifyListeners();
  }

  /// Gets the candy item at a specific position
  CandyItem? getCandyAt(Position position) {
    final candy = _candyByPosition[position];
    return (candy != null && !candy.isCollected) ? candy : null;
  }

  /// Checks if there is collectible candy at the given position
  bool hasCandyAt(Position position) {
    return getCandyAt(position) != null;
  }

  /// Attempts to collect candy at the character's current position
  /// Returns the collection event (successful or failed)
  CandyCollectionEvent? attemptCollection(GhostCharacter character, TileMap tileMap) {
    final position = character.position;
    final candy = getCandyAt(position);
    
    if (candy == null) {
      return null; // No candy at this position
    }
    
    // Attempt to add candy to character's inventory
    final success = character.collectCandy(candy);
    
    CandyCollectionEvent event;
    if (success) {
      // Mark candy as collected
      candy.collect();
      
      // Update tile map to remove candy tile
      tileMap.setTileAt(position, TileType.floor);
      
      // Remove from position tracking
      _candyByPosition.remove(position);
      
      event = CandyCollectionEvent(
        candy: candy,
        position: position,
        character: character,
        successful: true,
      );
    } else {
      event = CandyCollectionEvent(
        candy: candy,
        position: position,
        character: character,
        successful: false,
        failureReason: 'Inventory full',
      );
    }
    
    // Add to recent events
    _addRecentEvent(event);
    
    // Notify listeners about the collection attempt
    notifyListeners();
    
    return event;
  }

  /// Processes character movement and handles automatic candy collection
  /// Should be called whenever a character moves to a new position
  CandyCollectionEvent? processMovement(GhostCharacter character, TileMap tileMap) {
    // Check if the character moved to a candy tile
    if (tileMap.getTileAt(character.position) == TileType.candy) {
      return attemptCollection(character, tileMap);
    }
    
    return null;
  }

  /// Gets all candy items of a specific type
  List<CandyItem> getCandyByType(CandyType type) {
    return _allCandy.where((candy) {
      if (candy.isCollected) return false;
      
      // Match by model path since we don't store type directly
      final expectedPath = CandyItem.create(type, 'temp').modelPath;
      return candy.modelPath == expectedPath;
    }).toList();
  }

  /// Gets all candy items with a specific effect
  List<CandyItem> getCandyByEffect(CandyEffect effect) {
    return _allCandy.where((candy) {
      return !candy.isCollected && candy.effect == effect;
    }).toList();
  }

  /// Gets candy items within a certain distance of a position
  List<CandyItem> getCandyNearPosition(Position center, int maxDistance) {
    return _allCandy.where((candy) {
      if (candy.isCollected || candy.position == null) return false;
      
      final distance = _calculateDistance(center, candy.position!);
      return distance <= maxDistance;
    }).toList();
  }

  /// Calculates Manhattan distance between two positions
  int _calculateDistance(Position a, Position b) {
    return (a.x - b.x).abs() + (a.z - b.z).abs();
  }

  /// Adds an event to the recent events list
  void _addRecentEvent(CandyCollectionEvent event) {
    _recentEvents.add(event);
    
    // Keep only the most recent events
    while (_recentEvents.length > maxRecentEvents) {
      _recentEvents.removeAt(0);
    }
  }

  /// Gets collection statistics
  Map<String, dynamic> getCollectionStatistics() {
    final totalCandy = _allCandy.length;
    final collectedCandy = _allCandy.where((c) => c.isCollected).length;
    final remainingCandy = totalCandy - collectedCandy;
    
    final collectedByType = <String, int>{};
    final collectedByEffect = <String, int>{};
    
    for (final candy in _allCandy.where((c) => c.isCollected)) {
      collectedByType[candy.name] = (collectedByType[candy.name] ?? 0) + 1;
      collectedByEffect[candy.effect.name] = (collectedByEffect[candy.effect.name] ?? 0) + 1;
    }
    
    return {
      'totalCandy': totalCandy,
      'collectedCandy': collectedCandy,
      'remainingCandy': remainingCandy,
      'collectionRate': totalCandy > 0 ? collectedCandy / totalCandy : 0.0,
      'collectedByType': collectedByType,
      'collectedByEffect': collectedByEffect,
      'recentEventsCount': _recentEvents.length,
    };
  }

  /// Clears all recent events
  void clearRecentEvents() {
    _recentEvents.clear();
    notifyListeners();
  }

  /// Resets the collection system (removes all candy)
  void reset() {
    _candyByPosition.clear();
    _allCandy.clear();
    _recentEvents.clear();
    notifyListeners();
  }

  /// Gets the most recent successful collection event
  CandyCollectionEvent? get lastSuccessfulCollection {
    for (int i = _recentEvents.length - 1; i >= 0; i--) {
      final event = _recentEvents[i];
      if (event.successful) {
        return event;
      }
    }
    return null;
  }

  /// Gets the most recent failed collection event
  CandyCollectionEvent? get lastFailedCollection {
    for (int i = _recentEvents.length - 1; i >= 0; i--) {
      final event = _recentEvents[i];
      if (!event.successful) {
        return event;
      }
    }
    return null;
  }

  /// Checks if any candy was collected recently (within last N events)
  bool hasRecentCollection({int withinLastEvents = 5}) {
    final recentCount = withinLastEvents.clamp(0, _recentEvents.length);
    final recentEvents = _recentEvents.skip(_recentEvents.length - recentCount);
    
    return recentEvents.any((event) => event.successful);
  }

  @override
  String toString() {
    final stats = getCollectionStatistics();
    return 'CandyCollectionSystem(${stats['collectedCandy']}/${stats['totalCandy']} collected)';
  }
}