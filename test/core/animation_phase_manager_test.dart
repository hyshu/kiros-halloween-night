import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/animation_phase_manager.dart';

void main() {
  group('AnimationPhaseManager', () {
    late AnimationPhaseManager animationManager;

    setUp(() {
      animationManager = AnimationPhaseManager();
    });

    tearDown(() {
      animationManager.dispose();
    });

    group('Basic Functionality', () {
      test('should initialize with correct default state', () {
        expect(animationManager.currentPhase, equals(AnimationPhase.none));
        expect(animationManager.isAnimating, isFalse);
        expect(animationManager.animationProgress, equals(1.0));
      });

      test('should handle movement animation', () async {
        // Start animation
        final animationFuture = animationManager.playMovementAnimation();
        expect(animationManager.isAnimating, isTrue);
        expect(animationManager.currentPhase, equals(AnimationPhase.movement));
        expect(
          animationManager.isPlayingPhase(AnimationPhase.movement),
          isTrue,
        );
        expect(
          animationManager.animationProgress,
          equals(0.5),
        ); // Placeholder value

        // Wait for completion
        await animationFuture;
        expect(animationManager.isAnimating, isFalse);
        expect(animationManager.currentPhase, equals(AnimationPhase.none));
      });

      test('should handle combat animation', () async {
        final animationFuture = animationManager.playCombatAnimation();
        expect(animationManager.isAnimating, isTrue);
        expect(animationManager.currentPhase, equals(AnimationPhase.combat));

        await animationFuture;
        expect(animationManager.isAnimating, isFalse);
      });

      test('should handle AI movement animation', () async {
        final animationFuture = animationManager.playAIMovementAnimation();
        expect(animationManager.isAnimating, isTrue);
        expect(
          animationManager.currentPhase,
          equals(AnimationPhase.aiMovement),
        );

        await animationFuture;
        expect(animationManager.isAnimating, isFalse);
      });

      test('should handle ally movement animation', () async {
        final animationFuture = animationManager.playAllyMovementAnimation();
        expect(animationManager.isAnimating, isTrue);
        expect(
          animationManager.currentPhase,
          equals(AnimationPhase.allyMovement),
        );

        await animationFuture;
        expect(animationManager.isAnimating, isFalse);
      });

      test('should handle effects animation', () async {
        final animationFuture = animationManager.playEffectsAnimation();
        expect(animationManager.isAnimating, isTrue);
        expect(animationManager.currentPhase, equals(AnimationPhase.effects));

        await animationFuture;
        expect(animationManager.isAnimating, isFalse);
      });
    });

    group('Animation Control', () {
      test('should prevent overlapping animations', () async {
        // Start first animation
        final firstAnimation = animationManager.playMovementAnimation();
        expect(animationManager.isAnimating, isTrue);
        expect(animationManager.currentPhase, equals(AnimationPhase.movement));

        // Try to start second animation (should be ignored)
        final secondAnimation = animationManager.playCombatAnimation();
        expect(
          animationManager.currentPhase,
          equals(AnimationPhase.movement),
        ); // Still first animation

        // Wait for first animation to complete
        await firstAnimation;
        await secondAnimation; // This should complete immediately since it was ignored

        expect(animationManager.isAnimating, isFalse);
        expect(animationManager.currentPhase, equals(AnimationPhase.none));
      });

      test('should allow skipping animations', () async {
        // Start animation
        final animationFuture = animationManager.playMovementAnimation();
        expect(animationManager.isAnimating, isTrue);

        // Skip animation
        animationManager.skipCurrentAnimation();
        expect(animationManager.isAnimating, isFalse);
        expect(animationManager.currentPhase, equals(AnimationPhase.none));

        // Original animation future should still complete
        await animationFuture;
      });

      test('should handle skip when no animation is playing', () {
        expect(animationManager.isAnimating, isFalse);

        // Should not throw when skipping with no animation
        animationManager.skipCurrentAnimation();

        expect(animationManager.isAnimating, isFalse);
        expect(animationManager.currentPhase, equals(AnimationPhase.none));
      });
    });

    group('Animation Timing', () {
      test('should complete animation within expected timeframe', () async {
        final stopwatch = Stopwatch()..start();

        await animationManager.playMovementAnimation();

        stopwatch.stop();

        // Should complete in roughly 100ms (with some tolerance for test environment)
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    group('State Queries', () {
      test('should correctly identify specific animation phases', () async {
        expect(
          animationManager.isPlayingPhase(AnimationPhase.movement),
          isFalse,
        );

        final animationFuture = animationManager.playMovementAnimation();

        expect(
          animationManager.isPlayingPhase(AnimationPhase.movement),
          isTrue,
        );
        expect(animationManager.isPlayingPhase(AnimationPhase.combat), isFalse);

        await animationFuture;

        expect(
          animationManager.isPlayingPhase(AnimationPhase.movement),
          isFalse,
        );
      });
    });
  });

  group('AnimationPhase Enum', () {
    test('should have correct display names', () {
      expect(AnimationPhase.none.displayName, equals('None'));
      expect(AnimationPhase.movement.displayName, equals('Player Movement'));
      expect(AnimationPhase.combat.displayName, equals('Combat'));
      expect(AnimationPhase.aiMovement.displayName, equals('Enemy Movement'));
      expect(AnimationPhase.allyMovement.displayName, equals('Ally Movement'));
      expect(AnimationPhase.effects.displayName, equals('Effects'));
    });

    test('should have correct input blocking behavior', () {
      expect(AnimationPhase.none.blocksInput, isFalse);
      expect(AnimationPhase.movement.blocksInput, isTrue);
      expect(AnimationPhase.combat.blocksInput, isTrue);
      expect(AnimationPhase.aiMovement.blocksInput, isTrue);
      expect(AnimationPhase.allyMovement.blocksInput, isTrue);
      expect(AnimationPhase.effects.blocksInput, isTrue);
    });
  });
}
