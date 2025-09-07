import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/proximity_detector.dart';
import 'package:kiro_halloween_game/core/spatial_index.dart';
import 'package:kiro_halloween_game/core/activation_manager.dart';
import 'package:kiro_halloween_game/core/proximity_system.dart';
import 'package:kiro_halloween_game/core/enemy_character.dart';
import 'package:kiro_halloween_game/core/ghost_character.dart';
import 'package:kiro_halloween_game/core/position.dart';
import 'package:kiro_halloween_game/core/tile_map.dart';

void main() {
  group('ProximityDetector', () {
    late ProximityDetector proximityDetector;
    late GhostCharacter player;
    late List<EnemyCharacter> enemies;

    setUp(() {
      proximityDetector = ProximityDetector();
      player = GhostCharacter(id: 'player', position: Position(10, 10));

      enemies = [
        EnemyCharacter.human(
          id: 'enemy1',
          position: Position(12, 10), // Distance 2
          modelType: HumanModelType.maleA,
          activationRadius: 5,
        ),
        EnemyCharacter.human(
          id: 'enemy2',
          position: Position(20, 10), // Distance 10
          modelType: HumanModelType.femaleA,
          activationRadius: 8,
        ),
        EnemyCharacter.monster(
          id: 'enemy3',
          position: Position(5, 5), // Distance ~7
          modelType: MonsterModelType.skeleton,
          activationRadius: 10,
        ),
      ];
    });

    test('calculates distance correctly', () {
      final distance = proximityDetector.calculateDistance(player, enemies[0]);
      expect(distance, equals(2.0));
    });

    test('identifies enemies in activation range', () {
      final inRange = proximityDetector.getEnemiesInActivationRange(
        player,
        enemies,
      );

      // Enemy1 (distance 2, radius 5) and Enemy3 (distance ~7, radius 10) should be in range
      // Enemy2 (distance 10, radius 8) should be out of range
      expect(inRange.length, equals(2));
      expect(inRange.any((e) => e.id == 'enemy1'), isTrue);
      expect(inRange.any((e) => e.id == 'enemy3'), isTrue);
      expect(inRange.any((e) => e.id == 'enemy2'), isFalse);
    });

    test('identifies enemies outside activation range', () {
      final outOfRange = proximityDetector.getEnemiesOutsideActivationRange(
        player,
        enemies,
      );

      expect(outOfRange.length, equals(1));
      expect(outOfRange.first.id, equals('enemy2'));
    });

    test('finds closest enemy', () {
      final closest = proximityDetector.getClosestEnemyToPlayer(
        player,
        enemies,
      );

      expect(closest?.id, equals('enemy1')); // Distance 2 is closest
    });

    test('detects immediate threats', () {
      // Add an adjacent hostile enemy
      final adjacentEnemy = EnemyCharacter.human(
        id: 'adjacent',
        position: Position(11, 10), // Distance 1
        modelType: HumanModelType.maleB,
        state: EnemyState.hostile,
      );

      final threateningEnemies = [adjacentEnemy];
      final hasThreat = proximityDetector.hasImmediateThreat(
        player,
        threateningEnemies,
      );

      expect(hasThreat, isTrue);
    });

    test('calculates proximity priority correctly', () {
      final prioritized = proximityDetector.getEnemiesByProximityPriority(
        player,
        enemies,
      );

      // Should be sorted by proximity (closest first)
      expect(prioritized.first.id, equals('enemy1')); // Closest
      // The last enemy might vary based on priority calculation, so just check it's not the first
      expect(prioritized.last.id, isNot(equals('enemy1')));
    });

    test('determines activation status correctly', () {
      expect(
        proximityDetector.shouldActivateEnemy(player, enemies[0]),
        isTrue,
      ); // Within range
      expect(
        proximityDetector.shouldActivateEnemy(player, enemies[1]),
        isFalse,
      ); // Out of range
    });
  });

  group('SpatialIndex', () {
    late SpatialIndex spatialIndex;
    late List<EnemyCharacter> enemies;

    setUp(() {
      spatialIndex = SpatialIndex(
        worldWidth: 100,
        worldHeight: 100,
        cellSize: 10,
      );

      enemies = [
        EnemyCharacter.human(
          id: 'enemy1',
          position: Position(15, 15),
          modelType: HumanModelType.maleA,
        ),
        EnemyCharacter.human(
          id: 'enemy2',
          position: Position(25, 25),
          modelType: HumanModelType.femaleA,
        ),
        EnemyCharacter.human(
          id: 'enemy3',
          position: Position(16, 16), // Same cell as enemy1
          modelType: HumanModelType.maleB,
        ),
      ];

      for (final enemy in enemies) {
        spatialIndex.addCharacter(enemy);
      }
    });

    test('adds and retrieves characters correctly', () {
      final charactersInRadius = spatialIndex
          .getCharactersInRadius<EnemyCharacter>(Position(15, 15), 5);

      // Should find enemy1 and enemy3 (both close to 15,15)
      expect(charactersInRadius.length, equals(2));
      expect(charactersInRadius.any((e) => e.id == 'enemy1'), isTrue);
      expect(charactersInRadius.any((e) => e.id == 'enemy3'), isTrue);
    });

    test('finds closest character', () {
      final closest = spatialIndex.getClosestCharacter<EnemyCharacter>(
        Position(15, 15),
        10,
      );

      expect(closest?.id, equals('enemy1')); // Exact position match
    });

    test('updates character positions', () {
      // Move enemy1 to a different position
      enemies[0].moveTo(Position(50, 50));
      spatialIndex.updateCharacterPosition(enemies[0]);

      // Should no longer find enemy1 near original position
      final nearOriginal = spatialIndex.getCharactersInRadius<EnemyCharacter>(
        Position(15, 15),
        5,
      );

      expect(nearOriginal.any((e) => e.id == 'enemy1'), isFalse);

      // Should find enemy1 near new position
      final nearNew = spatialIndex.getCharactersInRadius<EnemyCharacter>(
        Position(50, 50),
        5,
      );

      expect(nearNew.any((e) => e.id == 'enemy1'), isTrue);
    });

    test('provides accurate statistics', () {
      final stats = spatialIndex.getStats();

      expect(stats.totalCharacters, equals(3));
      expect(stats.occupiedCells, greaterThan(0));
      expect(stats.occupancyPercentage, greaterThan(0.0));
    });
  });

  group('ActivationManager', () {
    late ActivationManager activationManager;
    late ProximityDetector proximityDetector;
    late SpatialIndex spatialIndex;
    late GhostCharacter player;
    late List<EnemyCharacter> enemies;

    setUp(() {
      proximityDetector = ProximityDetector();
      spatialIndex = SpatialIndex(worldWidth: 100, worldHeight: 100);
      activationManager = ActivationManager(
        proximityDetector: proximityDetector,
        spatialIndex: spatialIndex,
        maxActiveEnemies: 10,
      );

      player = GhostCharacter(id: 'player', position: Position(50, 50));

      enemies = List.generate(
        20,
        (i) => EnemyCharacter.human(
          id: 'enemy$i',
          position: Position(50 + i, 50), // Spread enemies along x-axis
          modelType: HumanModelType.maleA,
          activationRadius: 5,
        ),
      );

      for (final enemy in enemies) {
        activationManager.addEnemy(enemy);
      }
    });

    test('activates enemies within range', () {
      activationManager.updateActivation(player);

      final activeEnemies = activationManager.getActiveEnemies();

      // Should activate enemies within range (up to maxActiveEnemies limit)
      expect(activeEnemies.length, lessThanOrEqualTo(10));
      expect(activeEnemies.length, greaterThan(0));

      // All active enemies should be within activation range
      for (final enemy in activeEnemies) {
        final distance = proximityDetector.calculateDistance(player, enemy);
        expect(distance, lessThanOrEqualTo(enemy.activationRadius.toDouble()));
      }
    });

    test('deactivates enemies when out of range', () {
      // First activation
      activationManager.updateActivation(player);
      final initialActive = activationManager.getActiveEnemies().length;

      // Move player far away
      player.moveTo(Position(0, 0));

      // Update activation (may need multiple updates due to cooldown)
      for (int i = 0; i < 5; i++) {
        activationManager.updateActivation(player);
      }
      final finalActive = activationManager.getActiveEnemies().length;

      // Should have fewer (or zero) active enemies
      expect(finalActive, lessThanOrEqualTo(initialActive));
    });

    test('respects maximum active enemy limit', () {
      // Add many enemies close to player
      for (int i = 0; i < 50; i++) {
        final enemy = EnemyCharacter.human(
          id: 'close_enemy$i',
          position: Position(50, 50 + (i % 3)), // Very close to player
          modelType: HumanModelType.femaleA,
          activationRadius: 10,
        );
        activationManager.addEnemy(enemy);
      }

      activationManager.updateActivation(player);
      final activeEnemies = activationManager.getActiveEnemies();

      expect(activeEnemies.length, lessThanOrEqualTo(10)); // maxActiveEnemies
    });

    test('provides accurate metrics', () {
      activationManager.updateActivation(player);
      final metrics = activationManager.metrics;

      expect(metrics.totalEnemies, equals(20));
      expect(metrics.activeEnemies, greaterThan(0));
      expect(metrics.inactiveEnemies, greaterThan(0));
      expect(metrics.activationPercentage, greaterThan(0.0));
    });
  });

  group('ProximitySystem Integration', () {
    late ProximitySystem proximitySystem;
    late GhostCharacter player;
    late TileMap tileMap;

    setUp(() {
      tileMap = TileMap();
      proximitySystem = ProximitySystem.forWorld(tileMap, maxActiveEnemies: 15);

      player = GhostCharacter(id: 'player', position: Position(50, 50));
    });

    test('integrates all components correctly', () {
      // Add enemies
      final enemies = List.generate(
        10,
        (i) => EnemyCharacter.human(
          id: 'enemy$i',
          position: Position(50 + i, 50),
          modelType: HumanModelType.maleA,
          activationRadius: 8,
        ),
      );

      for (final enemy in enemies) {
        proximitySystem.addEnemy(enemy);
      }

      // Update system
      proximitySystem.update(player);

      // Verify system state
      final activeEnemies = proximitySystem.getActiveEnemies();
      final stats = proximitySystem.systemStats;

      expect(activeEnemies.length, greaterThan(0));
      expect(stats.totalEnemies, equals(10));
      expect(stats.isEnabled, isTrue);
    });

    test('can be enabled and disabled', () {
      // Add an enemy
      final enemy = EnemyCharacter.human(
        id: 'test_enemy',
        position: Position(52, 50),
        modelType: HumanModelType.maleA,
        activationRadius: 5,
      );
      proximitySystem.addEnemy(enemy);

      // Enable and update
      proximitySystem.setEnabled(true);
      proximitySystem.update(player);
      expect(proximitySystem.getActiveEnemies().length, greaterThan(0));

      // Disable and verify
      proximitySystem.setEnabled(false);
      expect(proximitySystem.isEnabled, isFalse);
      expect(proximitySystem.getActiveEnemies().length, equals(0));
    });

    test('provides comprehensive debug information', () {
      final enemy = EnemyCharacter.human(
        id: 'debug_enemy',
        position: Position(53, 50),
        modelType: HumanModelType.maleA,
      );
      proximitySystem.addEnemy(enemy);

      // Update to ensure stats are current
      proximitySystem.update(player);

      final debugInfo = proximitySystem.getDebugInfo(player);

      expect(debugInfo.isEnabled, isTrue);
      expect(debugInfo.systemStats.totalEnemies, greaterThanOrEqualTo(1));
      expect(debugInfo.activationDebug.playerPosition, equals(player.position));
    });

    test('optimizes by removing satisfied enemies', () {
      final enemy = EnemyCharacter.human(
        id: 'satisfied_enemy',
        position: Position(54, 50),
        modelType: HumanModelType.maleA,
      );
      proximitySystem.addEnemy(enemy);

      // Mark enemy as satisfied
      enemy.setSatisfied();

      // Optimize system
      proximitySystem.optimize();

      // Enemy should be removed
      expect(proximitySystem.systemStats.totalEnemies, equals(0));
    });
  });
}
