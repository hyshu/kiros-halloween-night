import 'package:flutter/foundation.dart';
import 'candy_item.dart';

/// Manages the player's candy collection and inventory
class Inventory extends ChangeNotifier {
  /// List of candy items in the inventory
  final List<CandyItem> _candyItems = [];
  
  /// Maximum number of candy items that can be held
  final int maxCapacity;
  
  /// Active temporary effects from consumed candy
  final Map<String, TemporaryEffect> _activeEffects = {};

  Inventory({this.maxCapacity = 50});

  /// Gets an unmodifiable list of all candy items
  List<CandyItem> get candyItems => List.unmodifiable(_candyItems);
  
  /// Gets the current number of candy items
  int get count => _candyItems.length;
  
  /// Gets whether the inventory is full
  bool get isFull => _candyItems.length >= maxCapacity;
  
  /// Gets whether the inventory is empty
  bool get isEmpty => _candyItems.isEmpty;
  
  /// Gets the remaining capacity
  int get remainingCapacity => maxCapacity - _candyItems.length;
  
  /// Gets all active temporary effects
  Map<String, TemporaryEffect> get activeEffects => Map.unmodifiable(_activeEffects);

  /// Adds a candy item to the inventory
  /// Returns true if successful, false if inventory is full
  bool addCandy(CandyItem candy) {
    if (isFull) {
      return false;
    }
    
    _candyItems.add(candy);
    candy.collect();
    notifyListeners();
    return true;
  }

  /// Removes a candy item from the inventory
  /// Returns true if the item was found and removed
  bool removeCandy(CandyItem candy) {
    final removed = _candyItems.remove(candy);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  /// Removes a candy item by ID
  /// Returns the removed candy item, or null if not found
  CandyItem? removeCandyById(String id) {
    final index = _candyItems.indexWhere((candy) => candy.id == id);
    if (index != -1) {
      final candy = _candyItems.removeAt(index);
      notifyListeners();
      return candy;
    }
    return null;
  }

  /// Gets a candy item by ID
  CandyItem? getCandyById(String id) {
    try {
      return _candyItems.firstWhere((candy) => candy.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Gets all candy items of a specific type
  List<CandyItem> getCandyByType(CandyType type) {
    return _candyItems.where((candy) {
      // Match by model path since we don't store type directly
      final expectedPath = CandyItem.create(type, 'temp').modelPath;
      return candy.modelPath == expectedPath;
    }).toList();
  }

  /// Gets all candy items with a specific effect
  List<CandyItem> getCandyByEffect(CandyEffect effect) {
    return _candyItems.where((candy) => candy.effect == effect).toList();
  }

  /// Gets available candy items for gifting (excludes items with active effects)
  List<CandyItem> getAvailableForGifting() {
    return _candyItems.where((candy) {
      // Don't allow gifting candy that provides active temporary effects
      return !candy.isTemporaryEffect || !_hasActiveEffect(candy);
    }).toList();
  }

  /// Checks if a candy item has an active effect
  bool _hasActiveEffect(CandyItem candy) {
    return _activeEffects.values.any((effect) => effect.sourceId == candy.id);
  }

  /// Uses a candy item and applies its effects
  /// Returns true if successful, false if candy not found
  bool useCandy(String candyId) {
    final candy = getCandyById(candyId);
    if (candy == null) return false;

    // Apply the candy's effect
    _applyCandyEffect(candy);
    
    // Remove the candy from inventory after use
    removeCandy(candy);
    
    return true;
  }

  /// Applies the effect of a candy item
  void _applyCandyEffect(CandyItem candy) {
    switch (candy.effect) {
      case CandyEffect.healthBoost:
        // Health boost is applied immediately by the character
        break;
        
      case CandyEffect.maxHealthIncrease:
        // Max health increase is applied immediately by the character
        break;
        
      case CandyEffect.speedIncrease:
      case CandyEffect.allyStrength:
      case CandyEffect.specialAbility:
      case CandyEffect.statModification:
        // These effects are temporary and need to be tracked
        if (candy.isTemporaryEffect) {
          _addTemporaryEffect(candy);
        }
        break;
    }
  }

  /// Adds a temporary effect from a candy item
  void _addTemporaryEffect(CandyItem candy) {
    final effectId = '${candy.effect.name}_${candy.id}';
    final effect = TemporaryEffect(
      id: effectId,
      sourceId: candy.id,
      name: candy.name,
      effect: candy.effect,
      value: candy.value,
      abilityModifications: Map.from(candy.abilityModifications),
      remainingDuration: candy.effectDuration,
    );
    
    _activeEffects[effectId] = effect;
    notifyListeners();
  }

  /// Updates all temporary effects (call this each turn)
  void updateTemporaryEffects() {
    final expiredEffects = <String>[];
    
    for (final entry in _activeEffects.entries) {
      final effect = entry.value;
      effect.remainingDuration--;
      
      if (effect.remainingDuration <= 0) {
        expiredEffects.add(entry.key);
      }
    }
    
    // Remove expired effects
    for (final effectId in expiredEffects) {
      _activeEffects.remove(effectId);
    }
    
    if (expiredEffects.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Gets the total value of a specific ability modification from all active effects
  double getTotalAbilityModification(String abilityName) {
    double total = 0.0;
    
    for (final effect in _activeEffects.values) {
      final value = effect.abilityModifications[abilityName];
      if (value is num) {
        total += value.toDouble();
      }
    }
    
    return total;
  }

  /// Checks if any active effect provides a specific boolean ability
  bool hasActiveAbility(String abilityName) {
    return _activeEffects.values.any((effect) {
      final value = effect.abilityModifications[abilityName];
      return value is bool && value;
    });
  }

  /// Gets all candy items sorted by name
  List<CandyItem> getCandySortedByName() {
    final sorted = List<CandyItem>.from(_candyItems);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Gets all candy items sorted by effect type
  List<CandyItem> getCandySortedByEffect() {
    final sorted = List<CandyItem>.from(_candyItems);
    sorted.sort((a, b) => a.effect.name.compareTo(b.effect.name));
    return sorted;
  }

  /// Clears all candy items from the inventory
  void clear() {
    _candyItems.clear();
    _activeEffects.clear();
    notifyListeners();
  }

  /// Gets a summary of the inventory contents
  Map<String, int> getInventorySummary() {
    final summary = <String, int>{};
    
    for (final candy in _candyItems) {
      summary[candy.name] = (summary[candy.name] ?? 0) + 1;
    }
    
    return summary;
  }

  @override
  String toString() {
    final summary = getInventorySummary();
    final summaryStr = summary.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    return 'Inventory($count/$maxCapacity items) [$summaryStr]';
  }
}

/// Represents a temporary effect from consumed candy
class TemporaryEffect {
  /// Unique identifier for this effect
  final String id;
  
  /// ID of the candy item that created this effect
  final String sourceId;
  
  /// Display name of the effect
  final String name;
  
  /// Type of effect
  final CandyEffect effect;
  
  /// Numerical value of the effect
  final int value;
  
  /// Additional ability modifications
  final Map<String, dynamic> abilityModifications;
  
  /// Remaining duration in turns
  int remainingDuration;

  TemporaryEffect({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.effect,
    required this.value,
    required this.abilityModifications,
    required this.remainingDuration,
  });

  /// Returns true if this effect has expired
  bool get isExpired => remainingDuration <= 0;

  @override
  String toString() => '$name ($remainingDuration turns remaining)';
}