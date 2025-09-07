import 'package:test/test.dart';
import 'package:kiro_halloween_game/core/combat_manager.dart';
import 'package:kiro_halloween_game/core/health_system.dart';
import 'package:kiro_halloween_game/core/ally_character.dart';
import 'package:kiro_halloween_game/core/enemy_character.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('CombatManager', () {
    late CombatManager combatManager;
    late HealthSystem healthSystem;

    setUp(() {
      healthSystem = HealthSystem();
      combatManager = CombatManager(healthSystem: healthSystem);
    });

    group('Combat Detection', () {
      test('should detect combat between adjacent ally and hostile enemy', () {
        // Create original enemy for ally conversion
        final originalEnemy = EnemyCharacter(
          id: 'original_enemy',
          position: Position(0, 0),
          modelPath: 'test.obj',
        );

        // Create hostile enemy to fight
        final hostileEnemy = EnemyCharacter(
          id: 'hostile_enemy',
          position: Position(5, 5),
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        hostileEnemy.activate(); // Make enemy proximity active

        final ally = AllyCharacter(originalEnemy: originalEnemy);
        ally.position = Position(5, 6); // Adjacent to hostile enemy

        final results = combatManager.processCombat([ally], [hostileEnemy]);

        expect(results, isNotEmpty);
        expect(combatManager.activeCombats, hasLength(1));
      });

      test('should not detect combat between distant characters', () {
        // Create original enemy for ally conversion
        final originalEnemy = EnemyCharacter(
          id: 'original_enemy',
          position: Position(0, 0),
          modelPath: 'test.obj',
        );

        // Create hostile enemy to fight (distant)
        final hostileEnemy = EnemyCharacter(
          id: 'hostile_enemy',
          position: Position(5, 5),
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        hostileEnemy.activate();

        final ally = AllyCharacter(originalEnemy: originalEnemy);
        ally.position = Position(10, 10); // Far from hostile enemy

        final results = combatManager.processCombat([ally], [hostileEnemy]);

        expect(results, isEmpty);
        expect(combatManager.activeCombats, isEmpty);
      });

      test('should not detect combat with inactive enemies', () {
        // Create original enemy for ally conversion
        final originalEnemy = EnemyCharacter(
          id: 'original_enemy',
          position: Position(0, 0),
          modelPath: 'test.obj',
        );

        // Create hostile but inactive enemy
        final inactiveEnemy = EnemyCharacter(
          id: 'inactive_enemy',
          position: Position(5, 5),
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        // Don't activate enemy

        final ally = AllyCharacter(originalEnemy: originalEnemy);
        ally.position = Position(5, 6);

        final results = combatManager.processCombat([ally], [inactiveEnemy]);

        expect(results, isEmpty);
        expect(combatManager.activeCombats, isEmpty);
      });

      test('should not detect combat with non-hostile enemies', () {
        // Create original enemy for ally conversion
        final originalEnemy = EnemyCharacter(
          id: 'original_enemy',
          position: Position(0, 0),
          modelPath: 'test.obj',
        );

        // Create satisfied (non-hostile) enemy
        final satisfiedEnemy = EnemyCharacter(
          id: 'satisfied_enemy',
          position: Position(5, 5),
          modelPath: 'test.obj',
          state: EnemyState.satisfied,
        );
        satisfiedEnemy.activate();

        final ally = AllyCharacter(originalEnemy: originalEnemy);
        ally.position = Position(5, 6);

        final results = combatManager.processCombat([ally], [satisfiedEnemy]);

        expect(results, isEmpty);
        expect(combatManager.activeCombats, isEmpty);
      });
    });

    group('Combat Resolution', () {
      test('should apply damage to both characters in combat', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 50,
          maxHealth: 50,
          state: EnemyState.hostile,
        );
        enemy.activate();

        final ally = AllyCharacter(
          originalEnemy: EnemyCharacter(
            id: 'original',
            position: Position(0, 0),
            modelPath: 'test.obj',
          ),
        );
        ally.position = Position(5, 6);
        ally.health = 50;

        final initialAllyHealth = ally.health;
        final initialEnemyHealth = enemy.health;

        final results = combatManager.processCombat([ally], [enemy]);

        expect(results, hasLength(1));
        final result = results.first;

        // Both characters should have taken some damage
        expect(result.allyDamageDealt, greaterThan(0));
        expect(result.enemyDamageDealt, greaterThan(0));
        expect(ally.health, lessThan(initialAllyHealth));
        expect(enemy.health, lessThan(initialEnemyHealth));
      });

      test('should handle character defeat correctly', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 1, // Very low health
          maxHealth: 50,
          state: EnemyState.hostile,
        );
        enemy.activate();

        final ally = AllyCharacter(
          originalEnemy: EnemyCharacter(
            id: 'original',
            position: Position(0, 0),
            modelPath: 'test.obj',
          ),
        );
        ally.position = Position(5, 6);
        ally.health = 50;

        final results = combatManager.processCombat([ally], [enemy]);

        expect(results, hasLength(1));
        final result = results.first;

        // Enemy should be defeated due to low health
        expect(result.enemyDefeated, isTrue);
        expect(enemy.isSatisfied, isTrue);
      });

      test('should track multiple combat encounters', () {
        // Create multiple allies and enemies
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy1.activate();

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(7, 7),
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy2.activate();

        final ally1 = AllyCharacter(
          originalEnemy: EnemyCharacter(
            id: 'original1',
            position: Position(0, 0),
            modelPath: 'test.obj',
          ),
        );
        ally1.position = Position(5, 6);

        final ally2 = AllyCharacter(
          originalEnemy: EnemyCharacter(
            id: 'original2',
            position: Position(0, 0),
            modelPath: 'test.obj',
          ),
        );
        ally2.position = Position(7, 8);

        final results = combatManager.processCombat(
          [ally1, ally2],
          [enemy1, enemy2],
        );

        expect(results, hasLength(2));
        expect(combatManager.activeCombats, hasLength(2));
      });
    });

    group('Combat State Management', () {
      test('should track active combats correctly', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy.activate();

        final ally = AllyCharacter(originalEnemy: enemy);
        ally.position = Position(5, 6);

        expect(combatManager.isInCombat(ally), isFalse);
        expect(combatManager.isInCombat(enemy), isFalse);

        combatManager.processCombat([ally], [enemy]);

        expect(combatManager.isInCombat(ally), isTrue);
        expect(combatManager.isInCombat(enemy), isTrue);
      });

      test('should end all combats when requested', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy.activate();

        final ally = AllyCharacter(originalEnemy: enemy);
        ally.position = Position(5, 6);

        combatManager.processCombat([ally], [enemy]);
        expect(combatManager.activeCombats, isNotEmpty);

        combatManager.endAllCombats();
        expect(combatManager.activeCombats, isEmpty);
      });
    });

    group('Damage Calculation', () {
      test('should calculate damage within expected range', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 100,
          maxHealth: 100,
          state: EnemyState.hostile,
        );
        enemy.activate();

        final ally = AllyCharacter(
          originalEnemy: EnemyCharacter(
            id: 'original',
            position: Position(0, 0),
            modelPath: 'test.obj',
          ),
        );
        ally.position = Position(5, 6);
        ally.health = 100;

        final results = combatManager.processCombat([ally], [enemy]);
        final result = results.first;

        // Damage should be within reasonable range
        expect(result.allyDamageDealt, greaterThan(0));
        expect(result.allyDamageDealt, lessThan(50)); // Shouldn't be too high
        expect(result.enemyDamageDealt, greaterThan(0));
        expect(result.enemyDamageDealt, lessThan(50));
      });

      test('should apply combat strength bonuses', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 100,
          maxHealth: 100,
          state: EnemyState.hostile,
        );
        enemy.activate();

        final ally = AllyCharacter(
          originalEnemy: EnemyCharacter(
            id: 'original',
            position: Position(0, 0),
            modelPath: 'test.obj',
          ),
        );
        ally.position = Position(5, 6);
        ally.health = 100;
        ally.applyCombatStrengthBonus(20); // Add combat strength bonus

        final results = combatManager.processCombat([ally], [enemy]);
        final result = results.first;

        // Ally with bonus should deal more damage
        expect(result.allyDamageDealt, greaterThan(5));
      });
    });
  });

  group('CombatEncounter', () {
    test('should track encounter duration', () {
      final enemy = EnemyCharacter(
        id: 'enemy1',
        position: Position(5, 5),
        modelPath: 'test.obj',
      );

      final ally = AllyCharacter(originalEnemy: enemy);

      final encounter = CombatEncounter(
        ally: ally,
        enemy: enemy,
        startTime: DateTime.now().subtract(Duration(seconds: 5)),
      );

      expect(encounter.duration.inSeconds, greaterThanOrEqualTo(4));
    });

    test('should identify involved characters correctly', () {
      final enemy = EnemyCharacter(
        id: 'enemy1',
        position: Position(5, 5),
        modelPath: 'test.obj',
      );

      final ally = AllyCharacter(originalEnemy: enemy);

      final encounter = CombatEncounter(
        ally: ally,
        enemy: enemy,
        startTime: DateTime.now(),
      );

      expect(encounter.involves(ally, enemy), isTrue);

      final otherEnemy = EnemyCharacter(
        id: 'enemy2',
        position: Position(6, 6),
        modelPath: 'test.obj',
      );
      expect(encounter.involves(ally, otherEnemy), isFalse);
    });
  });

  group('CombatResult', () {
    test('should correctly identify victory conditions', () {
      final enemy = EnemyCharacter(
        id: 'enemy1',
        position: Position(5, 5),
        modelPath: 'test.obj',
      );

      final ally = AllyCharacter(originalEnemy: enemy);

      // Ally victory
      final allyVictory = CombatResult(
        ally: ally,
        enemy: enemy,
        allyDamageDealt: 10,
        enemyDamageDealt: 5,
        allyDefeated: false,
        enemyDefeated: true,
        timestamp: DateTime.now(),
      );

      expect(allyVictory.isAllyVictory, isTrue);
      expect(allyVictory.isEnemyVictory, isFalse);
      expect(allyVictory.isMutualDefeat, isFalse);
      expect(allyVictory.isOngoing, isFalse);

      // Enemy victory
      final enemyVictory = CombatResult(
        ally: ally,
        enemy: enemy,
        allyDamageDealt: 5,
        enemyDamageDealt: 10,
        allyDefeated: true,
        enemyDefeated: false,
        timestamp: DateTime.now(),
      );

      expect(enemyVictory.isAllyVictory, isFalse);
      expect(enemyVictory.isEnemyVictory, isTrue);

      // Ongoing combat
      final ongoing = CombatResult(
        ally: ally,
        enemy: enemy,
        allyDamageDealt: 5,
        enemyDamageDealt: 5,
        allyDefeated: false,
        enemyDefeated: false,
        timestamp: DateTime.now(),
      );

      expect(ongoing.isOngoing, isTrue);
      expect(ongoing.isAllyVictory, isFalse);
      expect(ongoing.isEnemyVictory, isFalse);
    });

    test('should generate appropriate descriptions', () {
      final enemy = EnemyCharacter(
        id: 'enemy1',
        position: Position(5, 5),
        modelPath: 'test.obj',
      );

      final ally = AllyCharacter(originalEnemy: enemy);

      final result = CombatResult(
        ally: ally,
        enemy: enemy,
        allyDamageDealt: 10,
        enemyDamageDealt: 5,
        allyDefeated: false,
        enemyDefeated: true,
        timestamp: DateTime.now(),
      );

      expect(result.description, contains(ally.id));
      expect(result.description, contains(enemy.id));
      expect(result.description, contains('defeated'));
    });
  });
}
