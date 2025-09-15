import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:kiro_halloween_game/core/animation_system.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('UnifiedAnimationSystem', () {
    late AnimationSystem animationSystem;

    setUp(() {
      animationSystem = AnimationSystem();
    });

    tearDown(() {
      animationSystem.dispose();
    });

    group('Camera Animation', () {
      test('should initialize with correct default state', () {
        expect(animationSystem.currentCameraPosition, equals(Vector3.zero()));
        expect(animationSystem.isCameraAnimating, isFalse);
        expect(animationSystem.cameraAnimationProgress, equals(1.0));
      });

      test('should initialize to specific position', () {
        final initialPos = Vector3(10, 5, 15);
        animationSystem.initialize(initialPos);

        expect(animationSystem.currentCameraPosition.x, equals(10.0));
        expect(animationSystem.currentCameraPosition.y, equals(5.0));
        expect(animationSystem.currentCameraPosition.z, equals(15.0));
        expect(animationSystem.isCameraAnimating, isFalse);
      });

      test('should set position instantly without animation', () {
        final newPos = Vector3(20, 10, 30);
        animationSystem.setCameraPosition(newPos);

        expect(animationSystem.currentCameraPosition.x, equals(20.0));
        expect(animationSystem.currentCameraPosition.y, equals(10.0));
        expect(animationSystem.currentCameraPosition.z, equals(30.0));
        expect(animationSystem.isCameraAnimating, isFalse);
        expect(animationSystem.cameraAnimationProgress, equals(1.0));
      });

      test('should animate to new position with default settings', () async {
        animationSystem.initialize(Vector3.zero());
        final targetPos = Vector3(10, 5, 15);

        final stopwatch = Stopwatch()..start();
        await animationSystem.animateCamera(targetPos);
        stopwatch.stop();

        expect(animationSystem.currentCameraPosition.x, closeTo(10.0, 0.1));
        expect(animationSystem.currentCameraPosition.y, closeTo(5.0, 0.1));
        expect(animationSystem.currentCameraPosition.z, closeTo(15.0, 0.1));
        expect(animationSystem.isCameraAnimating, isFalse);
        expect(animationSystem.cameraAnimationProgress, equals(1.0));

        // Camera uses smooth interpolation, so timing may vary
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(600));
      });

      test('should animate with custom duration', () async {
        animationSystem.initialize(Vector3.zero());
        final targetPos = Vector3(10, 0, 0);

        final stopwatch = Stopwatch()..start();
        await animationSystem.animateCamera(targetPos, duration: 100);
        stopwatch.stop();

        expect(animationSystem.currentCameraPosition.x, closeTo(10.0, 0.1));
        expect(animationSystem.isCameraAnimating, isFalse);

        // Camera uses smooth interpolation, timing may vary
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('should handle different easing curves', () async {
        animationSystem.initialize(Vector3.zero());
        final targetPos = Vector3(10, 0, 0);

        // Test linear easing
        await animationSystem.animateCamera(
          targetPos,
          duration: 100,
          easing: AnimationEasing.linear,
        );

        expect(animationSystem.currentCameraPosition.x, closeTo(10.0, 0.1));
        expect(animationSystem.isCameraAnimating, isFalse);

        // Reset for next test
        animationSystem.setCameraPosition(Vector3.zero());

        // Test easeInOut easing
        await animationSystem.animateCamera(
          targetPos,
          duration: 100,
          easing: AnimationEasing.easeInOut,
        );

        expect(animationSystem.currentCameraPosition.x, closeTo(10.0, 0.1));
        expect(animationSystem.isCameraAnimating, isFalse);
      });

      test('should skip animation and jump to end position', () async {
        animationSystem.initialize(Vector3.zero());
        final targetPos = Vector3(10, 5, 15);

        // Start animation
        final animationFuture = animationSystem.animateCamera(targetPos);
        expect(animationSystem.isCameraAnimating, isTrue);

        // Skip animation
        animationSystem.skipCameraAnimation();
        expect(animationSystem.isCameraAnimating, isFalse);
        expect(animationSystem.currentCameraPosition.x, closeTo(10.0, 0.1));
        expect(animationSystem.currentCameraPosition.y, closeTo(5.0, 0.1));
        expect(animationSystem.currentCameraPosition.z, closeTo(15.0, 0.1));

        // Wait for animation future to complete
        await animationFuture;
      });
    });

    group('Character Animation', () {
      test('should animate character movement', () async {
        final fromPos = Position(0, 0);
        final toPos = Position(2, 3);

        final stopwatch = Stopwatch()..start();
        await animationSystem.animateCharacter(
          'test_character',
          fromPos,
          toPos,
          duration: 100,
          easing: AnimationEasing.easeInOut,
        );
        stopwatch.stop();

        expect(animationSystem.isCharacterAnimating('test_character'), isFalse);
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(80));
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });

      test('should track character animation progress', () async {
        final fromPos = Position(0, 0);
        final toPos = Position(5, 5);

        // Start animation
        final animationFuture = animationSystem.animateCharacter(
          'test_character',
          fromPos,
          toPos,
          duration: 200,
        );

        expect(animationSystem.isCharacterAnimating('test_character'), isTrue);
        expect(
          animationSystem.getCharacterAnimationProgress('test_character'),
          greaterThanOrEqualTo(0.0),
        );

        // Wait for completion
        await animationFuture;
        expect(
          animationSystem.getCharacterAnimationProgress('test_character'),
          equals(1.0),
        );
      });

      test('should cancel character animation', () {
        final fromPos = Position(0, 0);
        final toPos = Position(10, 10);

        // Start animation
        animationSystem.animateCharacter('test_character', fromPos, toPos);
        expect(animationSystem.isCharacterAnimating('test_character'), isTrue);

        // Cancel animation
        animationSystem.cancelCharacterAnimation('test_character');
        expect(animationSystem.isCharacterAnimating('test_character'), isFalse);
      });

      test('should get character world position during animation', () async {
        final fromPos = Position(0, 0);
        final toPos = Position(2, 2);

        Vector3? capturedPosition;

        // Start animation with update callback
        final animationFuture = animationSystem.animateCharacter(
          'test_character',
          fromPos,
          toPos,
          duration: 100,
          onUpdate: (worldPos) {
            capturedPosition = worldPos;
          },
        );

        await animationFuture;

        // Should have captured at least one position update
        expect(capturedPosition, isNotNull);
        expect(capturedPosition!.x, closeTo(2.0, 0.1)); // Final position
        expect(capturedPosition!.z, closeTo(2.0, 0.1)); // Final position
      });
    });

    group('Animation Speed Presets', () {
      test('should animate with speed presets', () async {
        animationSystem.initialize(Vector3.zero());
        final targetPos = Vector3(5, 0, 0);

        // Test fast speed
        final stopwatch = Stopwatch()..start();
        await animationSystem.animateCameraWithSpeed(
          targetPos,
          AnimationSpeed.fast,
        );
        stopwatch.stop();

        expect(animationSystem.currentCameraPosition.x, closeTo(5.0, 0.1));
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(400));
      });
    });
  });

  group('AnimationEasing', () {
    test('should have correct display names', () {
      expect(AnimationEasing.linear.displayName, equals('Linear'));
      expect(AnimationEasing.easeIn.displayName, equals('Ease In'));
      expect(AnimationEasing.easeOut.displayName, equals('Ease Out'));
      expect(AnimationEasing.easeInOut.displayName, equals('Ease In-Out'));
      expect(AnimationEasing.smoothStep.displayName, equals('Smooth Step'));
      expect(AnimationEasing.smootherStep.displayName, equals('Smoother Step'));
      expect(AnimationEasing.easeInBack.displayName, equals('Ease In Back'));
      expect(AnimationEasing.easeOutBack.displayName, equals('Ease Out Back'));
      expect(AnimationEasing.bounce.displayName, equals('Bounce'));
    });

    test('should apply easing curves correctly', () {
      // Test linear curve
      expect(AnimationEasing.linear.apply(0.0), equals(0.0));
      expect(AnimationEasing.linear.apply(0.5), equals(0.5));
      expect(AnimationEasing.linear.apply(1.0), equals(1.0));

      // Test easeIn curve
      expect(AnimationEasing.easeIn.apply(0.0), equals(0.0));
      expect(AnimationEasing.easeIn.apply(1.0), equals(1.0));
      expect(
        AnimationEasing.easeIn.apply(0.5),
        lessThan(0.5),
      ); // Should be slower at start

      // Test easeOut curve
      expect(AnimationEasing.easeOut.apply(0.0), equals(0.0));
      expect(AnimationEasing.easeOut.apply(1.0), equals(1.0));
      expect(
        AnimationEasing.easeOut.apply(0.5),
        greaterThan(0.5),
      ); // Should be faster at start

      // Test easeInOut curve
      expect(AnimationEasing.easeInOut.apply(0.0), equals(0.0));
      expect(AnimationEasing.easeInOut.apply(1.0), equals(1.0));
    });
  });

  group('AnimationSpeed', () {
    test('should have correct display names', () {
      expect(AnimationSpeed.instant.displayName, equals('Instant'));
      expect(AnimationSpeed.fast.displayName, equals('Fast'));
      expect(AnimationSpeed.normal.displayName, equals('Normal'));
      expect(AnimationSpeed.slow.displayName, equals('Slow'));
    });

    test('should have correct durations', () {
      expect(AnimationSpeed.instant.durationMs, equals(0));
      expect(AnimationSpeed.fast.durationMs, equals(100));
      expect(AnimationSpeed.normal.durationMs, equals(200));
      expect(AnimationSpeed.slow.durationMs, equals(300));
    });
  });
}
