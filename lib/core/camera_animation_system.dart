import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

/// Handles smooth camera animations with various easing curves
class CameraAnimationSystem extends ChangeNotifier {
  /// Current camera position
  Vector3 _currentPosition = Vector3.zero();

  /// Target camera position
  Vector3 _targetPosition = Vector3.zero();

  /// Whether an animation is currently in progress
  bool _isAnimating = false;

  /// Animation start time
  DateTime? _animationStartTime;

  /// Animation duration in milliseconds
  int _animationDuration = 300;

  /// Current easing curve
  EasingCurve _easingCurve = EasingCurve.easeInOut;

  /// Animation update timer
  Timer? _animationTimer;

  /// Current animation completer
  Completer<void>? _animationCompleter;

  /// Animation frame rate (60 FPS)
  static const int _frameRate = 60;
  static const int _frameTimeMs = 1000 ~/ _frameRate;

  /// Current camera position
  Vector3 get currentPosition => Vector3.copy(_currentPosition);

  /// Whether camera is currently animating
  bool get isAnimating => _isAnimating;

  /// Current animation progress (0.0 to 1.0)
  double get animationProgress {
    if (!_isAnimating || _animationStartTime == null) return 1.0;

    final elapsed = DateTime.now()
        .difference(_animationStartTime!)
        .inMilliseconds;
    final progress = (elapsed / _animationDuration).clamp(0.0, 1.0);
    return progress;
  }

  /// Initialize camera position
  void initialize(Vector3 initialPosition) {
    _currentPosition = Vector3.copy(initialPosition);
    _targetPosition = Vector3.copy(initialPosition);
    notifyListeners();
  }

  /// Animate camera to a new position
  Future<void> animateToPosition(
    Vector3 newPosition, {
    int? duration,
    EasingCurve? easingCurve,
  }) async {
    // If already animating, return immediately to prevent overlapping
    if (_isAnimating) {
      return;
    }

    // Set up new animation
    _targetPosition = Vector3.copy(newPosition);
    _animationDuration = duration ?? 300;
    _easingCurve = easingCurve ?? EasingCurve.easeInOut;
    _animationStartTime = DateTime.now();
    _isAnimating = true;

    // Create completer for the animation
    _animationCompleter = Completer<void>();

    // Start animation timer
    _animationTimer = Timer.periodic(
      Duration(milliseconds: _frameTimeMs),
      (timer) => _updateAnimation(timer),
    );

    notifyListeners();
    return _animationCompleter!.future;
  }

  /// Instantly move camera to position (no animation)
  void setPosition(Vector3 newPosition) {
    _stopAnimation();
    _completeAnimation();
    _currentPosition = Vector3.copy(newPosition);
    _targetPosition = Vector3.copy(newPosition);
    notifyListeners();
  }

  /// Update animation frame
  void _updateAnimation(Timer timer) {
    if (!_isAnimating || _animationStartTime == null) {
      _stopAnimation();
      _completeAnimation();
      return;
    }

    final elapsed = DateTime.now()
        .difference(_animationStartTime!)
        .inMilliseconds;
    final progress = (elapsed / _animationDuration).clamp(0.0, 1.0);

    if (progress >= 1.0) {
      // Animation complete
      _currentPosition = Vector3.copy(_targetPosition);
      _stopAnimation();
      notifyListeners();
      _completeAnimation();
      return;
    }

    // Apply easing curve
    final easedProgress = _easingCurve.apply(progress);

    // Interpolate position
    _currentPosition = Vector3(
      _lerp(_currentPosition.x, _targetPosition.x, easedProgress),
      _lerp(_currentPosition.y, _targetPosition.y, easedProgress),
      _lerp(_currentPosition.z, _targetPosition.z, easedProgress),
    );

    notifyListeners();
  }

  /// Linear interpolation helper
  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  /// Stop current animation
  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _isAnimating = false;
    _animationStartTime = null;
  }

  /// Complete the current animation future
  void _completeAnimation() {
    if (_animationCompleter != null && !_animationCompleter!.isCompleted) {
      _animationCompleter!.complete();
    }
    _animationCompleter = null;
  }

  /// Skip current animation (jump to end)
  void skipAnimation() {
    if (_isAnimating) {
      _currentPosition = Vector3.copy(_targetPosition);
      _stopAnimation();
      _completeAnimation();
      notifyListeners();
    }
  }

  /// Set animation speed (affects default duration)
  void setAnimationSpeed(CameraAnimationSpeed speed) {
    switch (speed) {
      case CameraAnimationSpeed.slow:
        _animationDuration = 500;
        break;
      case CameraAnimationSpeed.normal:
        _animationDuration = 300;
        break;
      case CameraAnimationSpeed.fast:
        _animationDuration = 150;
        break;
      case CameraAnimationSpeed.instant:
        _animationDuration = 0;
        break;
    }
  }

  @override
  void dispose() {
    _stopAnimation();
    _completeAnimation();
    super.dispose();
  }
}

/// Different easing curves for camera animations
enum EasingCurve {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  easeInBack,
  easeOutBack,
  bounce;

  /// Apply the easing curve to a progress value (0.0 to 1.0)
  double apply(double t) {
    switch (this) {
      case EasingCurve.linear:
        return t;

      case EasingCurve.easeIn:
        return t * t;

      case EasingCurve.easeOut:
        return 1 - (1 - t) * (1 - t);

      case EasingCurve.easeInOut:
        if (t < 0.5) {
          return 2 * t * t;
        } else {
          return 1 - 2 * (1 - t) * (1 - t);
        }

      case EasingCurve.easeInBack:
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return c3 * t * t * t - c1 * t * t;

      case EasingCurve.easeOutBack:
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);

      case EasingCurve.bounce:
        const n1 = 7.5625;
        const d1 = 2.75;

        if (t < 1 / d1) {
          return n1 * t * t;
        } else if (t < 2 / d1) {
          return n1 * (t -= 1.5 / d1) * t + 0.75;
        } else if (t < 2.5 / d1) {
          return n1 * (t -= 2.25 / d1) * t + 0.9375;
        } else {
          return n1 * (t -= 2.625 / d1) * t + 0.984375;
        }
    }
  }

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case EasingCurve.linear:
        return 'Linear';
      case EasingCurve.easeIn:
        return 'Ease In';
      case EasingCurve.easeOut:
        return 'Ease Out';
      case EasingCurve.easeInOut:
        return 'Ease In-Out';
      case EasingCurve.easeInBack:
        return 'Ease In Back';
      case EasingCurve.easeOutBack:
        return 'Ease Out Back';
      case EasingCurve.bounce:
        return 'Bounce';
    }
  }
}

/// Animation speed presets
enum CameraAnimationSpeed {
  slow, // 500ms
  normal, // 300ms
  fast, // 150ms
  instant; // 0ms (no animation)

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case CameraAnimationSpeed.slow:
        return 'Slow';
      case CameraAnimationSpeed.normal:
        return 'Normal';
      case CameraAnimationSpeed.fast:
        return 'Fast';
      case CameraAnimationSpeed.instant:
        return 'Instant';
    }
  }

  /// Duration in milliseconds
  int get durationMs {
    switch (this) {
      case CameraAnimationSpeed.slow:
        return 500;
      case CameraAnimationSpeed.normal:
        return 300;
      case CameraAnimationSpeed.fast:
        return 150;
      case CameraAnimationSpeed.instant:
        return 0;
    }
  }
}
