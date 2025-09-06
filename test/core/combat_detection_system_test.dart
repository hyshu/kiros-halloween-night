import 'package:test/test.dart';
import '../../lib/core/combat_detection_system.dart';
import '../../lib/core/ally_character.dart';
import '../../lib/core/enemy_character.dart';
import '../../lib/core/position.dart';

void main() {
  group('CombatDetectionSystem', () {
    late CombatDetectionSystem detectionSystem;
    late AllyCharacter ally;
    late EnemyCharacter hostileEnemy;

    setUp(() {
      detectionSystem = CombatDetectionSystem();
      
      final originalEnemy = EnemyCharacter(
        id: 'original',
        position: Position(0, 0),
        modelPath: 'test.obj',
      );
      
      ally = AllyCharacter(
        originalEnemy: originalEnemy,
      );
      ally.position = Position(5, 5);
      
      hostileEnemy = EnemyCharacter(
        id: 'hostile',
        position: Position(6, 5), // Adjacent to ally
        modelPath: 'test.obj',
        state: EnemyState.hostile,
      );
      hostileEnemy.activate();
    });

    group('Combat Detection', () {
      test('should detect direct combat encounters', () {
        final encounters = detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        expect(encounters, hasLength(1));
        expect(encounters.first.ally, equals(ally));
        expect(encounters.first.enemy, equals(hostileEnemy));
        expect(encounters.first.encounterType, equals(CombatEncounterType.direct));
        expect(encounters.first.distance, equals(1));
      });

      test('should detect potential combat encounters', () {
        // Move enemy to detection range but not combat range
        hostileEnemy.position = Position(8, 5); // Distance 3
        
        detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        final potentialEncounters = detectionSystem.getPotentialEncounters();
        
        expect(potentialEncounters, hasLength(1));
        expect(potentialEncounters.first.ally, equals(ally));
        expect(potentialEncounters.first.enemy, equals(hostileEnemy));
        expect(potentialEncounters.first.distance, equals(3));
      });

      test('should not detect encounters with inactive enemies', () {
        hostileEnemy.deactivate();
        
        final encounters = detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        expect(encounters, isEmpty);
      });

      test('should not detect encounters with non-hostile enemies', () {
        hostileEnemy.state = EnemyState.satisfied;
        
        final encounters = detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        expect(encounters, isEmpty);
      });

      test('should not detect encounters with dead characters', () {
        ally.health = 0;
        
        final encounters = detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        expect(encounters, isEmpty);
      });

      test('should not detect encounters with satisfied allies', () {
        ally.state = AllyState.satisfied;
        
        final encounters = detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        expect(encounters, isEmpty);
      });

      test('should not detect encounters beyond detection range', () {
        hostileEnemy.position = Position(15, 15); // Far away
        
        final encounters = detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        final potentialEncounters = detectionSystem.getPotentialEncounters();
        
        expect(encounters, isEmpty);
        expect(potentialEncounters, isEmpty);
      });
    });

    group('Combat Status Queries', () {
      test('should correctly identify allies in combat', () {
        detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        expect(detectionSystem.isAllyInCombat(ally), isTrue);
      });

      test('should correctly identify enemies in combat', () {
        detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        expect(detectionSystem.isEnemyInCombat(hostileEnemy), isTrue);
      });

      test('should get all enemies in combat', () {
        detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        final enemiesInCombat = detectionSystem.getEnemiesInCombat();
        
        expect(enemiesInCombat, hasLength(1));
        expect(enemiesInCombat, contains(hostileEnemy));
      });

      test('should get all allies in combat', () {
        detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        final alliesInCombat = detectionSystem.getAlliesInCombat();
        
        expect(alliesInCombat, hasLength(1));
        expect(alliesInCombat, contains(ally));
      });
    });

    group('Enemy Finding', () {
      test('should find closest enemy to ally', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(8, 5), // Distance 3
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy1.activate();
        
        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(6, 5), // Distance 1 (closer)
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy2.activate();
        
        final closestEnemy = detectionSystem.findClosestEnemyToAlly(ally, [enemy1, enemy2]);
        
        expect(closestEnemy, equals(enemy2));
      });

      test('should return null when no valid enemies', () {
        final closestEnemy = detectionSystem.findClosestEnemyToAlly(ally, []);
        
        expect(closestEnemy, isNull);
      });

      test('should find enemies in range', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(7, 5), // Distance 2
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy1.activate();
        
        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(10, 5), // Distance 5
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy2.activate();
        
        final enemiesInRange = detectionSystem.findEnemiesInRange(ally, [enemy1, enemy2], 3);
        
        expect(enemiesInRange, hasLength(1));
        expect(enemiesInRange, contains(enemy1));
        expect(enemiesInRange, isNot(contains(enemy2)));
      });
    });

    group('Combat Prediction', () {
      test('should predict immediate combat engagement', () {
        // Already in combat range
        final willEngage = detectionSystem.predictCombatEngagement(ally, hostileEnemy, 1);
        
        expect(willEngage, isTrue);
      });

      test('should predict future combat engagement', () {
        // Within detection range, should engage within a few turns
        hostileEnemy.position = Position(8, 5); // Distance 3
        
        final willEngage = detectionSystem.predictCombatEngagement(ally, hostileEnemy, 5);
        
        expect(willEngage, isTrue);
      });

      test('should not predict engagement for distant enemies', () {
        hostileEnemy.position = Position(15, 15); // Very far
        
        final willEngage = detectionSystem.predictCombatEngagement(ally, hostileEnemy, 3);
        
        expect(willEngage, isFalse);
      });
    });

    group('Statistics', () {
      test('should provide accurate combat detection statistics', () {
        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(8, 5), // Potential combat range
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy2.activate();
        
        detectionSystem.detectCombatEncounters([ally], [hostileEnemy, enemy2]);
        
        final stats = detectionSystem.getStats();
        
        expect(stats.directCombatEncounters, equals(1));
        expect(stats.potentialCombatEncounters, equals(1));
        expect(stats.uniqueAlliesInCombat, equals(1));
        expect(stats.uniqueEnemiesInCombat, equals(1));
        expect(stats.totalEncounters, equals(1));
        expect(stats.hasActiveCombat, isTrue);
        expect(stats.hasPotentialCombat, isTrue);
      });

      test('should handle empty encounters correctly', () {
        detectionSystem.detectCombatEncounters([], []);
        
        final stats = detectionSystem.getStats();
        
        expect(stats.directCombatEncounters, equals(0));
        expect(stats.potentialCombatEncounters, equals(0));
        expect(stats.hasActiveCombat, isFalse);
        expect(stats.hasPotentialCombat, isFalse);
      });
    });

    group('Cleanup', () {
      test('should clear detected encounters', () {
        detectionSystem.detectCombatEncounters([ally], [hostileEnemy]);
        
        expect(detectionSystem.isAllyInCombat(ally), isTrue);
        
        detectionSystem.clearDetectedEncounters();
        
        expect(detectionSystem.isAllyInCombat(ally), isFalse);
      });
    });
  });

  group('CombatEncounter', () {
    test('should correctly identify involved characters', () {
      final originalEnemy = EnemyCharacter(
        id: 'original',
        position: Position(0, 0),
        modelPath: 'test.obj',
      );
      
      final ally = AllyCharacter(originalEnemy: originalEnemy);
      final enemy = EnemyCharacter(
        id: 'enemy',
        position: Position(1, 1),
        modelPath: 'test.obj',
      );
      
      final encounter = CombatEncounter(
        ally: ally,
        enemy: enemy,
        distance: 1,
        encounterType: CombatEncounterType.direct,
        detectedAt: DateTime.now(),
      );
      
      expect(encounter.involves(ally, enemy), isTrue);
      
      final otherEnemy = EnemyCharacter(
        id: 'other',
        position: Position(2, 2),
        modelPath: 'test.obj',
      );
      expect(encounter.involves(ally, otherEnemy), isFalse);
    });

    test('should track encounter duration', () {
      final originalEnemy = EnemyCharacter(
        id: 'original',
        position: Position(0, 0),
        modelPath: 'test.obj',
      );
      
      final ally = AllyCharacter(originalEnemy: originalEnemy);
      final enemy = EnemyCharacter(
        id: 'enemy',
        position: Position(1, 1),
        modelPath: 'test.obj',
      );
      
      final encounter = CombatEncounter(
        ally: ally,
        enemy: enemy,
        distance: 1,
        encounterType: CombatEncounterType.direct,
        detectedAt: DateTime.now().subtract(Duration(seconds: 5)),
      );
      
      expect(encounter.duration.inSeconds, greaterThanOrEqualTo(4));
    });

    test('should validate encounter correctly', () {
      final originalEnemy = EnemyCharacter(
        id: 'original',
        position: Position(0, 0),
        modelPath: 'test.obj',
      );
      
      final ally = AllyCharacter(originalEnemy: originalEnemy);
      final enemy = EnemyCharacter(
        id: 'enemy',
        position: Position(1, 1),
        modelPath: 'test.obj',
        state: EnemyState.hostile,
      );
      
      final encounter = CombatEncounter(
        ally: ally,
        enemy: enemy,
        distance: 1,
        encounterType: CombatEncounterType.direct,
        detectedAt: DateTime.now(),
      );
      
      expect(encounter.isValid, isTrue);
      
      // Make enemy non-hostile
      enemy.state = EnemyState.satisfied;
      expect(encounter.isValid, isFalse);
    });
  });

  group('PotentialCombatEncounter', () {
    test('should estimate turns to combat correctly', () {
      final originalEnemy = EnemyCharacter(
        id: 'original',
        position: Position(0, 0),
        modelPath: 'test.obj',
      );
      
      final ally = AllyCharacter(originalEnemy: originalEnemy);
      final enemy = EnemyCharacter(
        id: 'enemy',
        position: Position(4, 0),
        modelPath: 'test.obj',
      );
      
      final potentialEncounter = PotentialCombatEncounter(
        ally: ally,
        enemy: enemy,
        distance: 4,
        detectedAt: DateTime.now(),
      );
      
      // Distance 4, combat range 1, so 3 turns to combat
      expect(potentialEncounter.estimatedTurnsToCombat, equals(3));
    });

    test('should handle zero or negative turns correctly', () {
      final originalEnemy = EnemyCharacter(
        id: 'original',
        position: Position(0, 0),
        modelPath: 'test.obj',
      );
      
      final ally = AllyCharacter(originalEnemy: originalEnemy);
      final enemy = EnemyCharacter(
        id: 'enemy',
        position: Position(1, 0),
        modelPath: 'test.obj',
      );
      
      final potentialEncounter = PotentialCombatEncounter(
        ally: ally,
        enemy: enemy,
        distance: 1,
        detectedAt: DateTime.now(),
      );
      
      // Already in combat range
      expect(potentialEncounter.estimatedTurnsToCombat, equals(0));
    });
  });
}