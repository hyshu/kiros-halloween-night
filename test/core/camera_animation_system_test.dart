import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:kiro_halloween_game/core/camera_animation_system.dart';

void main() {
  group('CameraAnimationSystem', () {
    late CameraAnimationSystem cameraSystem;

    setUp(() {
      cameraSystem = CameraAnimationSystem();
    });

    tearDown(() {
      cameraSystem.dispose();
    });

    group('Initialization', () {
      test('should initialize with correct default state', () {
        expect(cameraSystem.currentPosition, equals(Vector3.zero()));
        expect(cameraSystem.isAnimating, isFalse);
        expect(cameraSystem.animationProgress, equals(1.0));
      });

      test('should initialize to specific position', () {
        final initialPos = Vector3(10, 5, 15);
        cameraSystem.initialize(initialPos);

        expect(cameraSystem.currentPosition.x, equals(10.0));
        expect(cameraSystem.currentPosition.y, equals(5.0));
        expect(cameraSystem.currentPosition.z, equals(15.0));
        expect(cameraSystem.isAnimating, isFalse);
      });
    });

    group('Instant Movement', () {
      test('should set position instantly without animation', () {
        final newPos = Vector3(20, 10, 30);
        cameraSystem.setPosition(newPos);

        expect(cameraSystem.currentPosition.x, equals(20.0));
        expect(cameraSystem.currentPosition.y, equals(10.0));
        expect(cameraSystem.currentPosition.z, equals(30.0));
        expect(cameraSystem.isAnimating, isFalse);
        expect(cameraSystem.animationProgress, equals(1.0));
      });

      test('should cancel ongoing animation when setting position instantly', () async {
        cameraSystem.initialize(Vector3.zero());
        
        // Start animation
        final animationFuture = cameraSystem.animateToPosition(Vector3(10, 0, 0));
        expect(cameraSystem.isAnimating, isTrue);

        // Set position instantly (should cancel animation)
        cameraSystem.setPosition(Vector3(5, 5, 5));
        expect(cameraSystem.isAnimating, isFalse);
        expect(cameraSystem.currentPosition, equals(Vector3(5, 5, 5)));

        // Wait for animation future to complete
        await animationFuture;
      });
    });

    group('Animated Movement', () {
      test('should animate to new position with default settings', () async {
        cameraSystem.initialize(Vector3.zero());
        final targetPos = Vector3(10, 5, 15);

        final stopwatch = Stopwatch()..start();
        await cameraSystem.animateToPosition(targetPos);
        stopwatch.stop();

        expect(cameraSystem.currentPosition.x, closeTo(10.0, 0.1));
        expect(cameraSystem.currentPosition.y, closeTo(5.0, 0.1));
        expect(cameraSystem.currentPosition.z, closeTo(15.0, 0.1));
        expect(cameraSystem.isAnimating, isFalse);
        expect(cameraSystem.animationProgress, equals(1.0));

        // Should take approximately 300ms (default duration)
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(250));
        expect(stopwatch.elapsedMilliseconds, lessThan(400));
      });

      test('should animate with custom duration', () async {
        cameraSystem.initialize(Vector3.zero());
        final targetPos = Vector3(10, 0, 0);

        final stopwatch = Stopwatch()..start();
        await cameraSystem.animateToPosition(targetPos, duration: 100);
        stopwatch.stop();

        expect(cameraSystem.currentPosition.x, closeTo(10.0, 0.1));
        expect(cameraSystem.isAnimating, isFalse);

        // Should take approximately 100ms
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(80));
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });

      test('should handle different easing curves', () async {
        cameraSystem.initialize(Vector3.zero());
        final targetPos = Vector3(10, 0, 0);

        // Test linear easing
        await cameraSystem.animateToPosition(
          targetPos,
          duration: 100,
          easingCurve: EasingCurve.linear,
        );

        expect(cameraSystem.currentPosition.x, closeTo(10.0, 0.1));
        expect(cameraSystem.isAnimating, isFalse);

        // Reset for next test
        cameraSystem.setPosition(Vector3.zero());

        // Test easeInOut easing
        await cameraSystem.animateToPosition(
          targetPos,
          duration: 100,
          easingCurve: EasingCurve.easeInOut,
        );

        expect(cameraSystem.currentPosition.x, closeTo(10.0, 0.1));
        expect(cameraSystem.isAnimating, isFalse);
      });
    });

    group('Animation Control', () {
      test('should skip animation and jump to end position', () async {
        cameraSystem.initialize(Vector3.zero());
        final targetPos = Vector3(10, 5, 15);

        // Start animation
        final animationFuture = cameraSystem.animateToPosition(targetPos);
        expect(cameraSystem.isAnimating, isTrue);

        // Skip animation
        cameraSystem.skipAnimation();
        expect(cameraSystem.isAnimating, isFalse);
        expect(cameraSystem.currentPosition.x, closeTo(10.0, 0.1));
        expect(cameraSystem.currentPosition.y, closeTo(5.0, 0.1));
        expect(cameraSystem.currentPosition.z, closeTo(15.0, 0.1));

        // Wait for animation future to complete
        await animationFuture;
      });

      test('should handle skip when no animation is running', () {
        cameraSystem.initialize(Vector3(5, 5, 5));
        
        // Should not throw when skipping with no animation
        cameraSystem.skipAnimation();
        
        expect(cameraSystem.isAnimating, isFalse);
        expect(cameraSystem.currentPosition, equals(Vector3(5, 5, 5)));
      });

      test('should prevent overlapping animations', () async {
        cameraSystem.initialize(Vector3.zero());

        // Start first animation
        final firstTarget = Vector3(10, 0, 0);
        final firstAnimation = cameraSystem.animateToPosition(firstTarget, duration: 200);
        expect(cameraSystem.isAnimating, isTrue);

        // Attempt second animation (should be ignored)
        final secondTarget = Vector3(0, 10, 0);
        final secondAnimation = cameraSystem.animateToPosition(secondTarget, duration: 100);

        // Wait for both futures
        await Future.wait([firstAnimation, secondAnimation]);

        // Should have reached first target, not second
        expect(cameraSystem.currentPosition.x, closeTo(10.0, 0.1));
        expect(cameraSystem.currentPosition.y, closeTo(0.0, 0.1));
        expect(cameraSystem.currentPosition.z, closeTo(0.0, 0.1));
        expect(cameraSystem.isAnimating, isFalse);
      });
    });

    group('Animation Speed Settings', () {
      test('should set animation speed correctly', () {
        cameraSystem.setAnimationSpeed(CameraAnimationSpeed.slow);
        // Duration is internal, but we can test that it doesn't throw
        expect(() => cameraSystem.setAnimationSpeed(CameraAnimationSpeed.fast), 
               returnsNormally);
        expect(() => cameraSystem.setAnimationSpeed(CameraAnimationSpeed.instant), 
               returnsNormally);
      });
    });
  });

  group('EasingCurve', () {
    test('should have correct display names', () {
      expect(EasingCurve.linear.displayName, equals('Linear'));
      expect(EasingCurve.easeIn.displayName, equals('Ease In'));
      expect(EasingCurve.easeOut.displayName, equals('Ease Out'));
      expect(EasingCurve.easeInOut.displayName, equals('Ease In-Out'));
      expect(EasingCurve.easeInBack.displayName, equals('Ease In Back'));
      expect(EasingCurve.easeOutBack.displayName, equals('Ease Out Back'));
      expect(EasingCurve.bounce.displayName, equals('Bounce'));
    });

    test('should apply easing curves correctly', () {
      // Test linear curve
      expect(EasingCurve.linear.apply(0.0), equals(0.0));
      expect(EasingCurve.linear.apply(0.5), equals(0.5));
      expect(EasingCurve.linear.apply(1.0), equals(1.0));

      // Test easeIn curve
      expect(EasingCurve.easeIn.apply(0.0), equals(0.0));
      expect(EasingCurve.easeIn.apply(1.0), equals(1.0));
      expect(EasingCurve.easeIn.apply(0.5), lessThan(0.5)); // Should be slower at start

      // Test easeOut curve
      expect(EasingCurve.easeOut.apply(0.0), equals(0.0));
      expect(EasingCurve.easeOut.apply(1.0), equals(1.0));
      expect(EasingCurve.easeOut.apply(0.5), greaterThan(0.5)); // Should be faster at start

      // Test easeInOut curve
      expect(EasingCurve.easeInOut.apply(0.0), equals(0.0));
      expect(EasingCurve.easeInOut.apply(1.0), equals(1.0));
    });
  });

  group('CameraAnimationSpeed', () {
    test('should have correct display names', () {
      expect(CameraAnimationSpeed.slow.displayName, equals('Slow'));
      expect(CameraAnimationSpeed.normal.displayName, equals('Normal'));
      expect(CameraAnimationSpeed.fast.displayName, equals('Fast'));
      expect(CameraAnimationSpeed.instant.displayName, equals('Instant'));
    });

    test('should have correct durations', () {
      expect(CameraAnimationSpeed.slow.durationMs, equals(500));
      expect(CameraAnimationSpeed.normal.durationMs, equals(300));
      expect(CameraAnimationSpeed.fast.durationMs, equals(150));
      expect(CameraAnimationSpeed.instant.durationMs, equals(0));
    });
  });
}