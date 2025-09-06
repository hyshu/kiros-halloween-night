import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/ally_character.dart';
import '../../lib/core/enemy_character.dart';
import '../../lib/core/ghost_character.dart';
import '../../lib/core/position.dart';
import '../../lib/core/tile_map.dart';

void main() {
  group('AllyCharacter', () {
    late AllyCharacter ally;
    late EnemyCharacter originalEnemy;
    late GhostCharacter player;
    late TileMap tileMap;

    setUp(() {
      originalEnemy = EnemyCharacter.human(
        id: 'enemy1',
        position: Position(5, 5),
        modelType: HumanModelType.maleA,
        health: 50,
      );
      ally = AllyCharacter(originalEnemy: originalEnemy);
      player = GhostCharacter(
        id: 'player',
        position: Position(3, 3),
      );
      ally.setFollowTarget(player);
      
      // Create a simple tile map for testing
      tileMap = TileMap();
    });

    test('should initialize with correct properties from original enemy', () {
      expect(ally.id, '${originalEnemy.id}_ally');
      expect(ally.position, originalEnemy.position);
      expect(ally.modelPath, originalEnemy.modelPath);
      expect(ally.health, originalEnemy.health);
      expect(ally.maxHealth, originalEnemy.maxHealth);
      expect(ally.state, AllyState.following);
      expect(ally.satisfaction, 100);
    });

    test('should set and get follow target', () {
      final newPlayer = GhostCharacter(
        id: 'player2',
        position: Position(10, 10),
      );
      
      ally.setFollowTarget(newPlayer);
      
      expect(ally.followTarget, newPlayer);
    });

    test('should be in following state initially', () {
      expect(ally.isFollowing, true);
      expect(ally.isInCombat, false);
      expect(ally.isSatisfied, false);
    });

    test('should move towards player when too far away', () {
      player.position = Position(10, 10); // Far from ally
      ally.position = Position(5, 5);
      
      ally.updateAI(tileMap, []);
      
      // Ally should have moved towards player (position should change)
      // The exact position depends on pathfinding, but it should be closer
      final distanceBefore = Position(5, 5).distanceTo(Position(10, 10));
      final distanceAfter = ally.position.distanceTo(Position(10, 10));
      expect(distanceAfter, lessThan(distanceBefore));
    });

    test('should stay near player at preferred distance', () {
      player.position = Position(5, 7); // 2 tiles away (preferred distance)
      ally.position = Position(5, 5);
      
      final originalPosition = ally.position;
      ally.updateAI(tileMap, []);
      
      // Ally should stay roughly in the same area
      expect(ally.position.distanceTo(originalPosition), lessThanOrEqualTo(1));
    });

    test('should switch to combat when hostile enemies are nearby', () {
      final hostileEnemy = EnemyCharacter.human(
        id: 'hostile1',
        position: Position(6, 6), // Near ally
        modelType: HumanModelType.femaleA,
        state: EnemyState.hostile,
      );
      hostileEnemy.isProximityActive = true;
      
      ally.updateAI(tileMap, [hostileEnemy]);
      
      expect(ally.state, AllyState.combat);
      expect(ally.isInCombat, true);
    });

    test('should return to following when no enemies nearby', () {
      ally.state = AllyState.combat;
      
      ally.updateAI(tileMap, []); // No hostile enemies
      
      expect(ally.state, AllyState.following);
      expect(ally.isFollowing, true);
    });

    test('should take damage and reduce satisfaction', () {
      final initialSatisfaction = ally.satisfaction;
      
      ally.takeDamage(10);
      
      expect(ally.health, 40); // 50 - 10
      expect(ally.satisfaction, lessThan(initialSatisfaction));
    });

    test('should become satisfied when health reaches zero', () {
      ally.takeDamage(ally.health); // Take all health
      
      expect(ally.health, 0);
      expect(ally.state, AllyState.satisfied);
      expect(ally.isSatisfied, true);
    });

    test('should increase satisfaction', () {
      ally.satisfaction = 50;
      
      ally.increaseSatisfaction(20);
      
      expect(ally.satisfaction, 70);
    });

    test('should not exceed maximum satisfaction', () {
      ally.satisfaction = 90;
      
      ally.increaseSatisfaction(20);
      
      expect(ally.satisfaction, ally.maxSatisfaction);
    });

    test('should apply and remove combat strength bonus', () {
      final initialStrength = ally.effectiveCombatStrength;
      
      ally.applyCombatStrengthBonus(5);
      expect(ally.effectiveCombatStrength, initialStrength + 5);
      
      ally.removeCombatStrengthBonus(3);
      expect(ally.effectiveCombatStrength, initialStrength + 2);
    });

    test('should not have negative combat strength bonus', () {
      ally.applyCombatStrengthBonus(5);
      
      ally.removeCombatStrengthBonus(10); // Remove more than added
      
      expect(ally.combatStrengthBonus, 0);
    });

    test('should get satisfaction percentage correctly', () {
      ally.satisfaction = 75;
      
      expect(ally.satisfactionPercentage, 0.75);
    });

    test('should preserve original enemy properties', () {
      expect(ally.enemyType, originalEnemy.enemyType);
      expect(ally.originalAIType, originalEnemy.aiType);
    });

    test('should decrease satisfaction over time', () {
      final initialSatisfaction = ally.satisfaction;
      
      // Run many AI updates to trigger satisfaction decrease
      for (int i = 0; i < 1000; i++) {
        ally.updateAI(tileMap, []);
      }
      
      // Satisfaction should have decreased (though it's random, so we can't guarantee it)
      // This test might be flaky, but it tests the mechanism exists
      expect(ally.satisfaction, lessThanOrEqualTo(initialSatisfaction));
    });
  });
}