import 'dart:math';

import 'enemy_character.dart';
import 'ghost_character.dart';
import 'position.dart';
import 'proximity_detector.dart';
import 'spatial_index.dart';

/// Manages the activation and deactivation of enemies based on proximity to the player
class ActivationManager {
  /// The proximity detector for distance calculations
  final ProximityDetector _proximityDetector;
  
  /// The spatial index for efficient proximity queries
  final SpatialIndex _spatialIndex;
  
  /// Maximum number of enemies that can be active simultaneously
  final int maxActiveEnemies;
  
  /// Minimum time (in game ticks) between activation updates
  final int updateCooldown;
  
  /// Current cooldown counter
  int _currentCooldown = 0;
  
  /// List of all enemies in the game
  final List<EnemyCharacter> _allEnemies = [];
  
  /// Set of currently active enemy IDs for quick lookup
  final Set<String> _activeEnemyIds = {};
  
  /// Performance metrics for monitoring
  ActivationMetrics _metrics = const ActivationMetrics();

  ActivationManager({
    required ProximityDetector proximityDetector,
    required SpatialIndex spatialIndex,
    this.maxActiveEnemies = 50, // Reasonable limit for performance
    this.updateCooldown = 2, // Update every 2 game ticks
  }) : _proximityDetector = proximityDetector,
       _spatialIndex = spatialIndex;

  /// Adds an enemy to be managed by the activation system
  void addEnemy(EnemyCharacter enemy) {
    if (!_allEnemies.any((e) => e.id == enemy.id)) {
      _allEnemies.add(enemy);
      _spatialIndex.addCharacter(enemy);
      
      // Start enemies as inactive
      enemy.deactivate();
    }
  }

  /// Removes an enemy from the activation system
  void removeEnemy(String enemyId) {
    _allEnemies.removeWhere((e) => e.id == enemyId);
    _activeEnemyIds.remove(enemyId);
    _spatialIndex.removeCharacter(enemyId);
  }

  /// Updates the activation status of all enemies based on player proximity
  void updateActivation(GhostCharacter player) {
    // Apply cooldown to prevent too frequent updates
    if (_currentCooldown > 0) {
      _currentCooldown--;
      return;
    }
    _currentCooldown = updateCooldown;

    final startTime = DateTime.now();
    
    // Update spatial index positions for moved enemies
    _updateSpatialPositions();
    
    // Get enemies that should be activated
    final enemiesToActivate = _getEnemiesForActivation(player);
    
    // Get enemies that should be deactivated
    final enemiesToDeactivate = _getEnemiesForDeactivation(player);
    
    // Apply activation changes
    _applyActivationChanges(enemiesToActivate, enemiesToDeactivate);
    
    // Update metrics
    final processingTime = DateTime.now().difference(startTime);
    _updateMetrics(processingTime);
  }

  /// Updates spatial index positions for enemies that have moved
  void _updateSpatialPositions() {
    for (final enemy in _allEnemies) {
      _spatialIndex.updateCharacterPosition(enemy);
    }
  }

  /// Gets enemies that should be activated based on proximity
  List<EnemyCharacter> _getEnemiesForActivation(GhostCharacter player) {
    // Use spatial index to get nearby enemies efficiently
    final nearbyEnemies = _spatialIndex.getEnemiesInRadius(
      player.position, 
      ProximityDetector.maxProximityDistance,
    );
    
    final candidatesForActivation = <EnemyCharacter>[];
    
    for (final enemy in nearbyEnemies) {
      // Skip already active enemies
      if (enemy.isProximityActive) continue;
      
      // Check if enemy should be activated
      if (_proximityDetector.shouldActivateEnemy(player, enemy)) {
        candidatesForActivation.add(enemy);
      }
    }
    
    // Sort by priority (closest and most threatening first)
    final prioritizedCandidates = _proximityDetector.getEnemiesByProximityPriority(
      player, 
      candidatesForActivation,
    );
    
    // Limit the number of new activations to maintain performance
    final availableSlots = maxActiveEnemies - _activeEnemyIds.length;
    final maxNewActivations = min(availableSlots, 10); // Max 10 new activations per update
    
    return prioritizedCandidates.take(maxNewActivations).toList();
  }

  /// Gets enemies that should be deactivated based on distance
  List<EnemyCharacter> _getEnemiesForDeactivation(GhostCharacter player) {
    final enemiesToDeactivate = <EnemyCharacter>[];
    
    for (final enemy in _allEnemies) {
      // Skip already inactive enemies
      if (!enemy.isProximityActive) continue;
      
      // Check if enemy should be deactivated
      if (_proximityDetector.shouldDeactivateEnemy(player, enemy)) {
        enemiesToDeactivate.add(enemy);
      }
    }
    
    return enemiesToDeactivate;
  }

  /// Applies activation and deactivation changes
  void _applyActivationChanges(
    List<EnemyCharacter> toActivate, 
    List<EnemyCharacter> toDeactivate,
  ) {
    // Deactivate enemies first to free up slots
    for (final enemy in toDeactivate) {
      enemy.deactivate();
      _activeEnemyIds.remove(enemy.id);
    }
    
    // Activate new enemies
    for (final enemy in toActivate) {
      enemy.activate();
      _activeEnemyIds.add(enemy.id);
    }
  }

  /// Updates performance metrics
  void _updateMetrics(Duration processingTime) {
    _metrics = ActivationMetrics(
      totalEnemies: _allEnemies.length,
      activeEnemies: _activeEnemyIds.length,
      inactiveEnemies: _allEnemies.length - _activeEnemyIds.length,
      lastUpdateDuration: processingTime,
      activationPercentage: _allEnemies.isNotEmpty 
          ? (_activeEnemyIds.length / _allEnemies.length) * 100.0 
          : 0.0,
    );
  }

  /// Forces activation of a specific enemy (useful for special events)
  void forceActivateEnemy(String enemyId) {
    final enemy = _allEnemies.firstWhere(
      (e) => e.id == enemyId,
      orElse: () => throw ArgumentError('Enemy not found: $enemyId'),
    );
    
    if (!enemy.isProximityActive && _activeEnemyIds.length < maxActiveEnemies) {
      enemy.activate();
      _activeEnemyIds.add(enemy.id);
    }
  }

  /// Forces deactivation of a specific enemy
  void forceDeactivateEnemy(String enemyId) {
    final enemy = _allEnemies.firstWhere(
      (e) => e.id == enemyId,
      orElse: () => throw ArgumentError('Enemy not found: $enemyId'),
    );
    
    if (enemy.isProximityActive) {
      enemy.deactivate();
      _activeEnemyIds.remove(enemy.id);
    }
  }

  /// Gets all currently active enemies
  List<EnemyCharacter> getActiveEnemies() {
    return _allEnemies.where((e) => e.isProximityActive).toList();
  }

  /// Gets all currently inactive enemies
  List<EnemyCharacter> getInactiveEnemies() {
    return _allEnemies.where((e) => !e.isProximityActive).toList();
  }

  /// Gets enemies within a specific radius of the player
  List<EnemyCharacter> getEnemiesInRadius(GhostCharacter player, int radius) {
    return _spatialIndex.getEnemiesInRadius(player.position, radius);
  }

  /// Gets the closest active enemy to the player
  EnemyCharacter? getClosestActiveEnemy(GhostCharacter player) {
    final activeEnemies = getActiveEnemies();
    return _proximityDetector.getClosestEnemyToPlayer(player, activeEnemies);
  }

  /// Checks if there are any immediate threats (hostile enemies adjacent to player)
  bool hasImmediateThreats(GhostCharacter player) {
    final activeEnemies = getActiveEnemies();
    return _proximityDetector.hasImmediateThreat(player, activeEnemies);
  }

  /// Gets detailed proximity information for the current state
  ProximityInfo getProximityInfo(GhostCharacter player) {
    return _proximityDetector.getProximityInfo(player, _allEnemies);
  }

  /// Gets current activation metrics
  ActivationMetrics get metrics => _metrics;

  /// Gets spatial index statistics
  SpatialIndexStats getSpatialStats() {
    return _spatialIndex.getStats();
  }

  /// Clears all enemies from the activation system
  void clear() {
    _allEnemies.clear();
    _activeEnemyIds.clear();
    _spatialIndex.clear();
    _metrics = const ActivationMetrics();
  }

  /// Optimizes the activation system by cleaning up satisfied enemies
  void optimize() {
    // Remove satisfied enemies that are no longer needed
    final satisfiedEnemies = _allEnemies
        .where((e) => e.isSatisfied)
        .map((e) => e.id)
        .toList();
    
    for (final enemyId in satisfiedEnemies) {
      removeEnemy(enemyId);
    }
  }

  /// Gets debug information for a specific position
  ActivationDebugInfo getDebugInfo(GhostCharacter player) {
    final spatialDebug = _spatialIndex.getDebugInfo(player.position);
    final proximityInfo = getProximityInfo(player);
    final closestEnemy = getClosestActiveEnemy(player);
    
    return ActivationDebugInfo(
      playerPosition: player.position,
      spatialInfo: spatialDebug,
      proximityInfo: proximityInfo,
      closestActiveEnemyDistance: closestEnemy != null 
          ? _proximityDetector.calculateDistance(player, closestEnemy)
          : null,
      activationMetrics: _metrics,
    );
  }
}

/// Performance metrics for the activation system
class ActivationMetrics {
  /// Total number of enemies in the system
  final int totalEnemies;
  
  /// Number of currently active enemies
  final int activeEnemies;
  
  /// Number of currently inactive enemies
  final int inactiveEnemies;
  
  /// Time taken for the last activation update
  final Duration? lastUpdateDuration;
  
  /// Percentage of enemies that are currently active
  final double activationPercentage;

  const ActivationMetrics({
    this.totalEnemies = 0,
    this.activeEnemies = 0,
    this.inactiveEnemies = 0,
    this.lastUpdateDuration,
    this.activationPercentage = 0.0,
  });

  /// Gets the average update time in milliseconds
  double? get averageUpdateTimeMs {
    final duration = lastUpdateDuration;
    return duration != null ? duration.inMicroseconds.toDouble() / 1000.0 : null;
  }

  @override
  String toString() {
    return 'ActivationMetrics(total: $totalEnemies, active: $activeEnemies, '
           'inactive: $inactiveEnemies, activation: ${activationPercentage.toStringAsFixed(1)}%, '
           'updateTime: ${averageUpdateTimeMs?.toStringAsFixed(2)}ms)';
  }
}

/// Debug information for the activation system
class ActivationDebugInfo {
  final Position playerPosition;
  final SpatialDebugInfo spatialInfo;
  final ProximityInfo proximityInfo;
  final double? closestActiveEnemyDistance;
  final ActivationMetrics activationMetrics;

  const ActivationDebugInfo({
    required this.playerPosition,
    required this.spatialInfo,
    required this.proximityInfo,
    this.closestActiveEnemyDistance,
    required this.activationMetrics,
  });

  @override
  String toString() {
    return 'ActivationDebugInfo(player: $playerPosition, '
           'closest: ${closestActiveEnemyDistance?.toStringAsFixed(1)}, '
           'metrics: $activationMetrics)';
  }
}