import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/world_generator.dart';
import 'package:kiro_halloween_game/core/enemy_manager.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('Enemy Integration Tests', () {
    test('should spawn enemies in generated world', () async {
      // Generate a test world
      final worldGenerator = WorldGenerator(seed: 123, isTestMode: true);
      final tileMap = worldGenerator.generateWorld();

      // Initialize enemy manager
      final enemyManager = EnemyManager();
      enemyManager.initialize(tileMap);

      // Spawn enemies using spawner directly (without loading 3D models)
      enemyManager.spawnEnemiesForTesting(
        spawnDensity: 1.0, // Higher density for testing
        playerSpawn: tileMap.playerSpawn,
      );

      // Verify enemies were spawned
      expect(enemyManager.enemyCount, greaterThan(0));
      expect(enemyManager.enemies.isNotEmpty, true);

      // Verify enemies are positioned on walkable tiles
      for (final enemy in enemyManager.enemies.values) {
        expect(
          tileMap.isWalkable(enemy.position),
          true,
          reason:
              'Enemy ${enemy.id} at ${enemy.position} should be on walkable tile',
        );
      }

      // Verify enemies have proper spacing
      final enemyPositions = enemyManager.enemies.values
          .map((e) => e.position)
          .toList();
      for (int i = 0; i < enemyPositions.length; i++) {
        for (int j = i + 1; j < enemyPositions.length; j++) {
          final distance = enemyPositions[i].distanceTo(enemyPositions[j]);
          expect(
            distance,
            greaterThanOrEqualTo(3),
            reason: 'Enemies should maintain minimum distance of 3 tiles',
          );
        }
      }
    });

    test('should activate enemies based on player proximity', () async {
      // Generate a test world
      final worldGenerator = WorldGenerator(seed: 456, isTestMode: true);
      final tileMap = worldGenerator.generateWorld();

      // Initialize enemy manager
      final enemyManager = EnemyManager();
      enemyManager.initialize(tileMap);

      // Spawn enemies for testing
      enemyManager.spawnEnemiesForTesting(
        spawnDensity: 0.5,
        playerSpawn: tileMap.playerSpawn,
      );

      // Initially, no enemies should be active (player not positioned)
      expect(enemyManager.activeEnemyCount, equals(0));

      // Position player and update enemy activation
      final playerPosition = tileMap.playerSpawn ?? const Position(10, 10);
      enemyManager.updateEnemyActivation(playerPosition);

      // Some enemies should now be active based on proximity
      final activeEnemies = enemyManager.activeEnemies;
      for (final enemy in activeEnemies) {
        final distance = playerPosition.distanceTo(enemy.position);
        expect(
          distance,
          lessThanOrEqualTo(enemy.activationRadius),
          reason: 'Active enemy ${enemy.id} should be within activation radius',
        );
      }
    });

    test('should provide enemy statistics', () async {
      // Generate a test world
      final worldGenerator = WorldGenerator(seed: 789, isTestMode: true);
      final tileMap = worldGenerator.generateWorld();

      // Initialize enemy manager
      final enemyManager = EnemyManager();
      enemyManager.initialize(tileMap);

      // Spawn enemies for testing
      enemyManager.spawnEnemiesForTesting(spawnDensity: 0.8);

      // Get statistics
      final stats = enemyManager.getEnemyStats();

      expect(stats['total_enemies'], equals(enemyManager.enemyCount));
      expect(stats['active_enemies'], equals(enemyManager.activeEnemyCount));
      expect(stats['enemy_types'], isA<Map<String, int>>());
      expect(stats['ai_types'], isA<Map<String, int>>());

      // Verify statistics consistency
      final totalByType = (stats['enemy_types'] as Map<String, int>).values
          .fold(0, (sum, count) => sum + count);
      expect(totalByType, equals(enemyManager.enemyCount));
    });
  });
}
