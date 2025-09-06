import 'package:test/test.dart';
import 'package:kiro_halloween_game/core/ally_ai.dart';
import 'package:kiro_halloween_game/core/ally_character.dart';
import 'package:kiro_halloween_game/core/enemy_character.dart';
import 'package:kiro_halloween_game/core/ghost_character.dart';
import 'package:kiro_halloween_game/core/position.dart';
import 'package:kiro_halloween_game/core/tile_map.dart';

void main() {
  group('AllyAI', () {
    late TileMap tileMap;
    late GhostCharacter player;
    late AllyCharacter ally;
    late EnemyCharacter hostileEnemy;

    setUp(() {
      // Create a simple test tile map
      tileMap = TileMap.generate(20, 20);

      // Create test characters
      player = GhostCharacter(
        id: 'player',
        position: Position(10, 10),
        modelPath: 'test.obj',
      );

      final originalEnemy = EnemyCharacter(
        id: 'original',
        position: Position(8, 8),
        modelPath: 'test.obj',
      );

      ally = AllyCharacter(originalEnemy: originalEnemy);
      ally.position = Position(8, 8);

      hostileEnemy = EnemyCharacter(
        id: 'hostile',
        position: Position(5, 5),
        modelPath: 'test.obj',
        state: EnemyState.hostile,
      );
      hostileEnemy.activate();
    });

    group('Combat Detection', () {
      test('should detect nearby hostile enemies', () {
        // Place hostile enemy near ally
        hostileEnemy.position = Position(9, 8); // Adjacent to ally

        AllyAI.updateAllyAI(ally, player, [hostileEnemy], tileMap);

        expect(ally.state, equals(AllyState.combat));
      });

      test('should not detect distant hostile enemies', () {
        // Keep hostile enemy far from ally
        hostileEnemy.position = Position(15, 15);

        AllyAI.updateAllyAI(ally, player, [hostileEnemy], tileMap);

        expect(ally.state, equals(AllyState.following));
      });

      test('should ignore inactive enemies', () {
        hostileEnemy.position = Position(9, 8);
        hostileEnemy.deactivate(); // Make enemy inactive

        AllyAI.updateAllyAI(ally, player, [hostileEnemy], tileMap);

        expect(ally.state, equals(AllyState.following));
      });

      test('should ignore non-hostile enemies', () {
        hostileEnemy.position = Position(9, 8);
        hostileEnemy.state = EnemyState.satisfied; // Not hostile

        AllyAI.updateAllyAI(ally, player, [hostileEnemy], tileMap);

        expect(ally.state, equals(AllyState.following));
      });
    });

    group('Following Behavior', () {
      test('should move towards player when too far away', () {
        // Place ally far from player
        ally.position = Position(2, 2);
        player.position = Position(15, 15);

        final initialPosition = ally.position;
        AllyAI.updateAllyAI(ally, player, [], tileMap);

        // Ally should have moved (position changed)
        expect(ally.position, isNot(equals(initialPosition)));
        expect(ally.state, equals(AllyState.following));
      });

      test('should stay idle when at good distance from player', () {
        // Place ally at preferred distance from player
        ally.position = Position(8, 10);
        player.position = Position(10, 10);

        ally.setActive(); // Start as active
        AllyAI.updateAllyAI(ally, player, [], tileMap);

        // Ally should be idle when at good distance
        expect(ally.isIdle, isTrue);
      });

      test('should move away when too close to player', () {
        // Place ally very close to player
        ally.position = Position(10, 10);
        player.position = Position(10, 10); // Same position

        final initialPosition = ally.position;
        AllyAI.updateAllyAI(ally, player, [], tileMap);

        // Ally should have moved away
        expect(ally.position, isNot(equals(initialPosition)));
      });
    });

    group('Combat Behavior', () {
      test('should move towards closest enemy in combat mode', () {
        // Set ally to combat mode and place enemy nearby
        ally.state = AllyState.combat;
        ally.position = Position(8, 8);
        hostileEnemy.position = Position(10, 8);

        final initialPosition = ally.position;
        AllyAI.updateAllyAI(ally, player, [hostileEnemy], tileMap);

        // Ally should move towards enemy
        expect(ally.position, isNot(equals(initialPosition)));
        expect(ally.state, equals(AllyState.combat));
      });

      test('should stay in position when adjacent to enemy', () {
        // Place ally adjacent to enemy
        ally.state = AllyState.combat;
        ally.position = Position(8, 8);
        hostileEnemy.position = Position(9, 8); // Adjacent

        ally.setIdle();
        AllyAI.updateAllyAI(ally, player, [hostileEnemy], tileMap);

        // Ally should stay active (engaged in combat)
        expect(ally.isActive, isTrue);
      });

      test('should return to following when enemy too far', () {
        // Place enemy far from ally in combat mode
        ally.state = AllyState.combat;
        ally.position = Position(8, 8);
        hostileEnemy.position = Position(18, 18); // Very far

        AllyAI.updateAllyAI(ally, player, [hostileEnemy], tileMap);

        // Ally should return to following mode
        expect(ally.state, equals(AllyState.following));
      });
    });

    group('Multiple Allies', () {
      test('should update all allies correctly', () {
        final ally2 = AllyCharacter(
          originalEnemy: EnemyCharacter(
            id: 'original2',
            position: Position(12, 12),
            modelPath: 'test.obj',
          ),
        );
        ally2.position = Position(12, 12);

        final allies = [ally, ally2];

        AllyAI.updateAlliesAI(allies, player, [hostileEnemy], tileMap);

        // Both allies should be in following state (no nearby enemies)
        expect(ally.state, equals(AllyState.following));
        expect(ally2.state, equals(AllyState.following));
      });
    });

    group('Combat Target Selection', () {
      test('should find best combat target', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(10, 8), // Distance 2 from ally
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy1.activate();

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(9, 8), // Distance 1 from ally (closer)
          modelPath: 'test.obj',
          state: EnemyState.hostile,
        );
        enemy2.activate();

        ally.position = Position(8, 8);

        final target = AllyAI.getBestCombatTarget(ally, [enemy1, enemy2]);

        expect(target, equals(enemy2)); // Should choose closer enemy
      });

      test('should return null when no valid targets', () {
        final target = AllyAI.getBestCombatTarget(ally, []);

        expect(target, isNull);
      });
    });

    group('Combat Effectiveness', () {
      test('should calculate combat effectiveness correctly', () {
        ally.health = 50; // Full health
        ally.satisfaction = 100; // Full satisfaction

        hostileEnemy.health = 25; // Half health

        final effectiveness = AllyAI.calculateCombatEffectiveness(
          ally,
          hostileEnemy,
        );

        expect(effectiveness, greaterThan(0.0));
        expect(effectiveness, lessThanOrEqualTo(2.0));
      });

      test('should return zero effectiveness for dead characters', () {
        ally.health = 0; // Dead ally

        final effectiveness = AllyAI.calculateCombatEffectiveness(
          ally,
          hostileEnemy,
        );

        expect(effectiveness, equals(0.0));
      });
    });

    group('AI Statistics', () {
      test('should generate correct AI statistics', () {
        final ally2 = AllyCharacter(
          originalEnemy: EnemyCharacter(
            id: 'original2',
            position: Position(12, 12),
            modelPath: 'test.obj',
          ),
        );
        ally2.state = AllyState.combat;

        final ally3 = AllyCharacter(
          originalEnemy: EnemyCharacter(
            id: 'original3',
            position: Position(14, 14),
            modelPath: 'test.obj',
          ),
        );
        ally3.state = AllyState.satisfied;

        final allies = [ally, ally2, ally3]; // following, combat, satisfied

        final stats = AllyAI.getAIStats(allies);

        expect(stats.totalAllies, equals(3));
        expect(stats.followingAllies, equals(1));
        expect(stats.combatAllies, equals(1));
        expect(stats.satisfiedAllies, equals(1));
        expect(stats.followingPercentage, closeTo(0.33, 0.01));
        expect(stats.combatPercentage, closeTo(0.33, 0.01));
        expect(stats.satisfiedPercentage, closeTo(0.33, 0.01));
      });

      test('should handle empty ally list', () {
        final stats = AllyAI.getAIStats([]);

        expect(stats.totalAllies, equals(0));
        expect(stats.averageHealth, equals(0.0));
        expect(stats.averageSatisfaction, equals(0.0));
      });
    });

    group('Movement Cooldown', () {
      test('should respect movement cooldown', () {
        ally.movementCooldown = 2;
        ally.position = Position(2, 2);
        player.position = Position(15, 15);

        final initialPosition = ally.position;
        AllyAI.updateAllyAI(ally, player, [], tileMap);

        // Ally should not move due to cooldown
        expect(ally.position, equals(initialPosition));
        expect(ally.movementCooldown, equals(1)); // Cooldown decremented
      });

      test('should move when cooldown expires', () {
        ally.movementCooldown = 0;
        ally.position = Position(2, 2);
        player.position = Position(15, 15);

        final initialPosition = ally.position;
        AllyAI.updateAllyAI(ally, player, [], tileMap);

        // Ally should move when cooldown is zero
        expect(ally.position, isNot(equals(initialPosition)));
      });
    });
  });

  group('Direction', () {
    test('should have correct display names', () {
      expect(Direction.north.displayName, equals('North'));
      expect(Direction.south.displayName, equals('South'));
      expect(Direction.east.displayName, equals('East'));
      expect(Direction.west.displayName, equals('West'));
    });
  });
}
