import 'activation_manager.dart';
import 'character.dart';
import 'enemy_character.dart';
import 'ghost_character.dart';
import 'proximity_detector.dart';
import 'spatial_index.dart';
import 'tile_map.dart';

/// Comprehensive proximity-based activation system for enemy management
class ProximitySystem {
  /// The proximity detector for distance calculations
  final ProximityDetector _proximityDetector;
  
  /// The spatial index for efficient queries
  final SpatialIndex _spatialIndex;
  
  /// The activation manager for enemy state management
  final ActivationManager _activationManager;
  
  /// Whether the system is currently enabled
  bool _isEnabled = true;
  
  /// Performance monitoring
  ProximitySystemStats _stats = const ProximitySystemStats();

  ProximitySystem({
    required int worldWidth,
    required int worldHeight,
    int maxActiveEnemies = 50,
    int spatialCellSize = 16,
    int activationUpdateCooldown = 2,
  }) : _proximityDetector = ProximityDetector(),
       _spatialIndex = SpatialIndex(
         worldWidth: worldWidth,
         worldHeight: worldHeight,
         cellSize: spatialCellSize,
       ),
       _activationManager = ActivationManager(
         proximityDetector: ProximityDetector(),
         spatialIndex: SpatialIndex(
           worldWidth: worldWidth,
           worldHeight: worldHeight,
           cellSize: spatialCellSize,
         ),
         maxActiveEnemies: maxActiveEnemies,
         updateCooldown: activationUpdateCooldown,
       );

  /// Initializes the proximity system with the given world parameters
  factory ProximitySystem.forWorld(TileMap tileMap, {
    int maxActiveEnemies = 50,
    int spatialCellSize = 16,
    int activationUpdateCooldown = 2,
  }) {
    return ProximitySystem(
      worldWidth: TileMap.worldWidth,
      worldHeight: TileMap.worldHeight,
      maxActiveEnemies: maxActiveEnemies,
      spatialCellSize: spatialCellSize,
      activationUpdateCooldown: activationUpdateCooldown,
    );
  }

  /// Adds an enemy to the proximity system
  void addEnemy(EnemyCharacter enemy) {
    _activationManager.addEnemy(enemy);
    _updateStats();
  }

  /// Removes an enemy from the proximity system
  void removeEnemy(String enemyId) {
    _activationManager.removeEnemy(enemyId);
    _updateStats();
  }

  /// Updates the proximity system for the current game tick
  void update(GhostCharacter player) {
    if (!_isEnabled) return;

    final startTime = DateTime.now();
    
    // Update activation states based on proximity
    _activationManager.updateActivation(player);
    
    // Update performance stats
    final updateDuration = DateTime.now().difference(startTime);
    _updateStats(updateDuration);
  }

  /// Gets all enemies within activation range of the player
  List<EnemyCharacter> getEnemiesInActivationRange(GhostCharacter player) {
    return _proximityDetector.getEnemiesInActivationRange(
      player, 
      _activationManager.getActiveEnemies(),
    );
  }

  /// Gets all enemies within a specific radius of the player
  List<EnemyCharacter> getEnemiesInRadius(GhostCharacter player, int radius) {
    return _activationManager.getEnemiesInRadius(player, radius);
  }

  /// Gets all hostile enemies within combat range
  List<EnemyCharacter> getHostileEnemiesInCombatRange(
    GhostCharacter player, {
    int combatRange = 2,
  }) {
    return _proximityDetector.getHostileEnemiesInCombatRange(
      player,
      _activationManager.getActiveEnemies(),
      combatRange: combatRange,
    );
  }

  /// Gets all ally enemies within following range
  List<EnemyCharacter> getAllyEnemiesInFollowingRange(
    GhostCharacter player, {
    int followingRange = 5,
  }) {
    return _proximityDetector.getAllyEnemiesInFollowingRange(
      player,
      _activationManager.getActiveEnemies(),
      followingRange: followingRange,
    );
  }

  /// Gets the closest active enemy to the player
  EnemyCharacter? getClosestActiveEnemy(GhostCharacter player) {
    return _activationManager.getClosestActiveEnemy(player);
  }

  /// Checks if there are any immediate threats near the player
  bool hasImmediateThreats(GhostCharacter player) {
    return _activationManager.hasImmediateThreats(player);
  }

  /// Gets all currently active enemies
  List<EnemyCharacter> getActiveEnemies() {
    return _activationManager.getActiveEnemies();
  }

  /// Gets all currently inactive enemies
  List<EnemyCharacter> getInactiveEnemies() {
    return _activationManager.getInactiveEnemies();
  }

  /// Forces activation of a specific enemy
  void forceActivateEnemy(String enemyId) {
    _activationManager.forceActivateEnemy(enemyId);
  }

  /// Forces deactivation of a specific enemy
  void forceDeactivateEnemy(String enemyId) {
    _activationManager.forceDeactivateEnemy(enemyId);
  }

  /// Enables or disables the proximity system
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    
    if (!enabled) {
      // Deactivate all enemies when system is disabled
      final activeEnemies = _activationManager.getActiveEnemies();
      for (final enemy in activeEnemies) {
        enemy.deactivate();
      }
    }
  }

  /// Gets whether the proximity system is enabled
  bool get isEnabled => _isEnabled;

  /// Optimizes the system by cleaning up unnecessary data
  void optimize() {
    _activationManager.optimize();
    _updateStats();
  }

  /// Clears all enemies from the system
  void clear() {
    _activationManager.clear();
    _updateStats();
  }

  /// Gets comprehensive proximity information
  ProximityInfo getProximityInfo(GhostCharacter player) {
    return _activationManager.getProximityInfo(player);
  }

  /// Gets activation metrics
  ActivationMetrics get activationMetrics => _activationManager.metrics;

  /// Gets spatial index statistics
  SpatialIndexStats get spatialStats => _activationManager.getSpatialStats();

  /// Gets overall system statistics
  ProximitySystemStats get systemStats => _stats;

  /// Gets debug information for the current state
  ProximitySystemDebugInfo getDebugInfo(GhostCharacter player) {
    final activationDebug = _activationManager.getDebugInfo(player);
    
    return ProximitySystemDebugInfo(
      isEnabled: _isEnabled,
      activationDebug: activationDebug,
      systemStats: _stats,
    );
  }

  /// Updates system statistics
  void _updateStats([Duration? lastUpdateDuration]) {
    final activationMetrics = _activationManager.metrics;
    final spatialStats = _activationManager.getSpatialStats();
    
    _stats = ProximitySystemStats(
      isEnabled: _isEnabled,
      totalEnemies: activationMetrics.totalEnemies,
      activeEnemies: activationMetrics.activeEnemies,
      inactiveEnemies: activationMetrics.inactiveEnemies,
      activationPercentage: activationMetrics.activationPercentage,
      spatialCellsOccupied: spatialStats.occupiedCells,
      spatialOccupancyPercentage: spatialStats.occupancyPercentage,
      lastUpdateDuration: lastUpdateDuration,
    );
  }

  /// Processes AI updates for all active enemies
  void processActiveEnemyAI(GhostCharacter player, TileMap tileMap) {
    if (!_isEnabled) return;

    final activeEnemies = _activationManager.getActiveEnemies();
    
    for (final enemy in activeEnemies) {
      // Only process AI for proximity-active enemies
      if (enemy.isProximityActive) {
        enemy.updateAI(player, tileMap);
      }
    }
  }

  /// Gets enemies sorted by proximity priority for processing
  List<EnemyCharacter> getEnemiesByProximityPriority(GhostCharacter player) {
    final activeEnemies = _activationManager.getActiveEnemies();
    return _proximityDetector.getEnemiesByProximityPriority(player, activeEnemies);
  }

  /// Calculates the distance between the player and an enemy
  double calculateDistanceToPlayer(GhostCharacter player, EnemyCharacter enemy) {
    return _proximityDetector.calculateDistance(player, enemy);
  }

  /// Checks if two characters are within proximity range
  bool areCharactersInProximity(
    Character character1, 
    Character character2, 
    int radius,
  ) {
    return _proximityDetector.areCharactersInProximity(character1, character2, radius);
  }
}

/// Statistics for the overall proximity system
class ProximitySystemStats {
  /// Whether the system is currently enabled
  final bool isEnabled;
  
  /// Total number of enemies in the system
  final int totalEnemies;
  
  /// Number of currently active enemies
  final int activeEnemies;
  
  /// Number of currently inactive enemies
  final int inactiveEnemies;
  
  /// Percentage of enemies that are currently active
  final double activationPercentage;
  
  /// Number of spatial cells that contain characters
  final int spatialCellsOccupied;
  
  /// Percentage of spatial cells that are occupied
  final double spatialOccupancyPercentage;
  
  /// Duration of the last system update
  final Duration? lastUpdateDuration;

  const ProximitySystemStats({
    this.isEnabled = true,
    this.totalEnemies = 0,
    this.activeEnemies = 0,
    this.inactiveEnemies = 0,
    this.activationPercentage = 0.0,
    this.spatialCellsOccupied = 0,
    this.spatialOccupancyPercentage = 0.0,
    this.lastUpdateDuration,
  });

  /// Gets the average update time in milliseconds
  double? get averageUpdateTimeMs {
    final duration = lastUpdateDuration;
    return duration != null ? duration.inMicroseconds.toDouble() / 1000.0 : null;
  }

  /// Gets the efficiency ratio (active enemies / total enemies)
  double get efficiencyRatio {
    if (totalEnemies == 0) return 1.0;
    return activeEnemies / totalEnemies;
  }

  @override
  String toString() {
    return 'ProximitySystemStats(enabled: $isEnabled, total: $totalEnemies, '
           'active: $activeEnemies, activation: ${activationPercentage.toStringAsFixed(1)}%, '
           'spatial: ${spatialOccupancyPercentage.toStringAsFixed(1)}%, '
           'updateTime: ${averageUpdateTimeMs?.toStringAsFixed(2)}ms)';
  }
}

/// Debug information for the proximity system
class ProximitySystemDebugInfo {
  final bool isEnabled;
  final ActivationDebugInfo activationDebug;
  final ProximitySystemStats systemStats;

  const ProximitySystemDebugInfo({
    required this.isEnabled,
    required this.activationDebug,
    required this.systemStats,
  });

  @override
  String toString() {
    return 'ProximitySystemDebugInfo(enabled: $isEnabled, $systemStats)';
  }
}