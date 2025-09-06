import 'package:flutter/foundation.dart';
import 'ally_character.dart';
import 'enemy_character.dart';
import 'ghost_character.dart';
import 'tile_map.dart';
import 'position.dart';
import 'enemy_spawner.dart';

/// Manages all allied characters and their coordination
class AllyManager extends ChangeNotifier {
  /// List of all active allies
  final List<AllyCharacter> _allies = [];
  
  /// Maximum number of allies that can be active at once
  final int maxAllies;
  
  /// Reference to the player character
  GhostCharacter? _player;

  AllyManager({this.maxAllies = 10});

  /// Gets an unmodifiable list of all allies
  List<AllyCharacter> get allies => List.unmodifiable(_allies);
  
  /// Gets the current number of allies
  int get count => _allies.length;
  
  /// Gets whether the maximum number of allies has been reached
  bool get isAtMaxCapacity => _allies.length >= maxAllies;
  
  /// Gets the remaining ally capacity
  int get remainingCapacity => maxAllies - _allies.length;

  /// Sets the player character reference
  void setPlayer(GhostCharacter player) {
    _player = player;
    
    // Update all existing allies to follow the new player
    for (final ally in _allies) {
      ally.setFollowTarget(player);
    }
  }

  /// Converts an enemy to an ally
  /// Returns true if successful, false if at max capacity
  bool convertEnemyToAlly(EnemyCharacter enemy) {
    if (isAtMaxCapacity) {
      return false;
    }
    
    // Create new ally from enemy
    final ally = AllyCharacter(originalEnemy: enemy);
    
    // Set follow target if player is available
    if (_player != null) {
      ally.setFollowTarget(_player!);
    }
    
    // Add to allies list
    _allies.add(ally);
    
    notifyListeners();
    return true;
  }

  /// Removes an ally (when satisfied or defeated)
  bool removeAlly(AllyCharacter ally) {
    final removed = _allies.remove(ally);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  /// Removes an ally by ID
  bool removeAllyById(String id) {
    final index = _allies.indexWhere((ally) => ally.id == id);
    if (index != -1) {
      _allies.removeAt(index);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Gets an ally by ID
  AllyCharacter? getAllyById(String id) {
    try {
      return _allies.firstWhere((ally) => ally.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Updates all allies (called each game tick)
  void updateAllies(TileMap tileMap, List<EnemyCharacter> hostileEnemies) {
    final satisfiedAllies = <AllyCharacter>[];
    
    // Update each ally
    for (final ally in _allies) {
      ally.updateAI(tileMap, hostileEnemies);
      
      // Check if ally is satisfied and should be removed
      if (ally.isSatisfied) {
        satisfiedAllies.add(ally);
      }
    }
    
    // Remove satisfied allies
    for (final ally in satisfiedAllies) {
      removeAlly(ally);
    }
  }

  /// Gets all allies within a certain distance of a position
  List<AllyCharacter> getAlliesNear(Position position, int maxDistance) {
    return _allies.where((ally) {
      return ally.position.distanceTo(position) <= maxDistance;
    }).toList();
  }

  /// Gets all allies currently in combat
  List<AllyCharacter> getAlliesInCombat() {
    return _allies.where((ally) => ally.isInCombat).toList();
  }

  /// Gets all allies currently following the player
  List<AllyCharacter> getFollowingAllies() {
    return _allies.where((ally) => ally.isFollowing).toList();
  }

  /// Applies combat strength bonus to all allies
  void applyGlobalCombatBonus(int bonus) {
    for (final ally in _allies) {
      ally.applyCombatStrengthBonus(bonus);
    }
    notifyListeners();
  }

  /// Removes combat strength bonus from all allies
  void removeGlobalCombatBonus(int bonus) {
    for (final ally in _allies) {
      ally.removeCombatStrengthBonus(bonus);
    }
    notifyListeners();
  }

  /// Increases satisfaction for all allies
  void increaseAllSatisfaction(int amount) {
    for (final ally in _allies) {
      ally.increaseSatisfaction(amount);
    }
    notifyListeners();
  }

  /// Gets the total combat strength of all allies
  int getTotalCombatStrength() {
    return _allies.fold(0, (total, ally) => total + ally.effectiveCombatStrength);
  }

  /// Gets allies grouped by their original enemy type
  Map<EnemyType, List<AllyCharacter>> getAlliesByType() {
    final grouped = <EnemyType, List<AllyCharacter>>{};
    
    for (final ally in _allies) {
      final type = ally.enemyType;
      grouped[type] = (grouped[type] ?? [])..add(ally);
    }
    
    return grouped;
  }

  /// Gets the average satisfaction level of all allies
  double getAverageSatisfaction() {
    if (_allies.isEmpty) return 0.0;
    
    final totalSatisfaction = _allies.fold(0.0, 
      (total, ally) => total + ally.satisfactionPercentage);
    
    return totalSatisfaction / _allies.length;
  }

  /// Checks if any allies are at low satisfaction (below 30%)
  bool hasLowSatisfactionAllies() {
    return _allies.any((ally) => ally.satisfactionPercentage < 0.3);
  }

  /// Gets allies with low satisfaction
  List<AllyCharacter> getLowSatisfactionAllies() {
    return _allies.where((ally) => ally.satisfactionPercentage < 0.3).toList();
  }

  /// Activates all allies (makes them active for processing)
  void activateAllAllies() {
    for (final ally in _allies) {
      ally.isActive = true;
    }
  }

  /// Deactivates all allies (for performance optimization)
  void deactivateAllAllies() {
    for (final ally in _allies) {
      ally.isActive = false;
      ally.setIdle();
    }
  }

  /// Clears all allies
  void clearAllAllies() {
    _allies.clear();
    notifyListeners();
  }

  /// Gets a summary of ally status
  Map<String, dynamic> getAllySummary() {
    final typeGroups = getAlliesByType();
    final summary = <String, dynamic>{
      'total': count,
      'maxCapacity': maxAllies,
      'inCombat': getAlliesInCombat().length,
      'following': getFollowingAllies().length,
      'averageSatisfaction': getAverageSatisfaction(),
      'totalCombatStrength': getTotalCombatStrength(),
      'byType': {},
    };
    
    for (final entry in typeGroups.entries) {
      summary['byType'][entry.key.displayName] = entry.value.length;
    }
    
    return summary;
  }

  @override
  String toString() {
    final summary = getAllySummary();
    return 'AllyManager(${summary['total']}/${summary['maxCapacity']} allies, '
           'Combat: ${summary['inCombat']}, Following: ${summary['following']}, '
           'Avg Satisfaction: ${(summary['averageSatisfaction'] * 100).toStringAsFixed(1)}%)';
  }
}