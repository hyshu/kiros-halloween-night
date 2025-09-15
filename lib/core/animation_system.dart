import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'position.dart';

/// Handles both camera and character animations
/// with a single timer to improve performance and coordination
class AnimationSystem extends ChangeNotifier {
  /// Active camera animation
  CameraAnimation? _cameraAnimation;

  /// Active character animations
  final Map<String, CharacterAnimation> _characterAnimations = {};

  /// Global animation timer (60 FPS)
  Timer? _animationTimer;
  static const int _frameRate = 60;
  static const int _frameTimeMs = 1000 ~/ _frameRate;

  /// Whether the system is running
  bool _isRunning = false;

  /// Current camera position
  Vector3 _currentCameraPosition = Vector3.zero();

  /// Get current camera position
  Vector3 get currentCameraPosition => Vector3.copy(_currentCameraPosition);

  /// Whether camera is currently animating
  bool get isCameraAnimating => _cameraAnimation != null;

  /// Whether any characters are currently animating
  bool get hasActiveCharacterAnimations => _characterAnimations.isNotEmpty;

  /// Whether any animations are active
  bool get hasActiveAnimations =>
      isCameraAnimating || hasActiveCharacterAnimations;

  /// Whether a specific character is animating
  bool isCharacterAnimating(String characterId) {
    return _characterAnimations.containsKey(characterId);
  }

  /// Initialize the system with initial camera position
  void initialize(Vector3 initialCameraPosition) {
    _currentCameraPosition = Vector3.copy(initialCameraPosition);
    notifyListeners();
  }

  /// Start the unified animation system
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _animationTimer = Timer.periodic(
      Duration(milliseconds: _frameTimeMs),
      _updateAllAnimations,
    );

    debugPrint('UnifiedAnimationSystem: Started with single 60FPS timer');
  }

  /// Stop the unified animation system
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _animationTimer?.cancel();
    _animationTimer = null;

    // Complete all active animations
    _completeAllAnimations();

    debugPrint('UnifiedAnimationSystem: Stopped');
  }

  /// Animate camera to a new position
  Future<void> animateCamera(
    Vector3 targetPosition, {
    int? duration,
    AnimationEasing? easing,
  }) async {
    // Cancel existing camera animation
    _cancelCameraAnimation();

    _cameraAnimation = CameraAnimation(
      startPosition: Vector3.copy(_currentCameraPosition),
      targetPosition: Vector3.copy(targetPosition),
      duration: duration ?? 200,
      easing: easing ?? AnimationEasing.easeInOut,
    );

    // Start system if not already running
    if (!_isRunning) {
      start();
    }

    debugPrint(
      'UnifiedAnimationSystem: Started camera animation to $targetPosition',
    );
    notifyListeners();
    return _cameraAnimation!._completer.future;
  }

  /// Set camera position instantly (no animation)
  void setCameraPosition(Vector3 position) {
    _cancelCameraAnimation();
    _currentCameraPosition = Vector3.copy(position);
    notifyListeners();
  }

  /// Animate character movement
  Future<void> animateCharacter(
    String characterId,
    Position fromPosition,
    Position toPosition, {
    int? duration,
    AnimationEasing? easing,
    Function(Vector3 currentWorldPosition)? onUpdate,
  }) async {
    // Cancel existing animation for this character
    _cancelCharacterAnimation(characterId);

    _characterAnimations[characterId] = CharacterAnimation(
      characterId: characterId,
      fromPosition: fromPosition,
      toPosition: toPosition,
      duration: duration ?? 150,
      easing: easing ?? AnimationEasing.easeInOut,
      onUpdate: onUpdate,
    );

    // Start system if not already running
    if (!_isRunning) {
      start();
    }

    debugPrint(
      'UnifiedAnimationSystem: Started character animation for $characterId',
    );
    notifyListeners();
    return _characterAnimations[characterId]!._completer.future;
  }

  /// Cancel character animation
  void cancelCharacterAnimation(String characterId) {
    _cancelCharacterAnimation(characterId);
    notifyListeners();
  }

  /// Cancel all character animations
  void cancelAllCharacterAnimations() {
    final characterIds = _characterAnimations.keys.toList();
    for (final characterId in characterIds) {
      _cancelCharacterAnimation(characterId);
    }
    notifyListeners();
  }

  /// Get current animated world position for a character
  Vector3? getCharacterWorldPosition(String characterId) {
    final animation = _characterAnimations[characterId];
    return animation?.currentWorldPosition;
  }

  /// Get animation progress for a character (0.0 to 1.0)
  double getCharacterAnimationProgress(String characterId) {
    final animation = _characterAnimations[characterId];
    return animation?.progress ?? 1.0;
  }

  /// Get camera animation progress (0.0 to 1.0)
  double get cameraAnimationProgress {
    return _cameraAnimation?.progress ?? 1.0;
  }

  // === Convenience methods for backward compatibility ===

  /// Animate camera to position with speed preset
  Future<void> animateCameraWithSpeed(
    Vector3 targetPosition,
    AnimationSpeed speed, {
    AnimationEasing? easing,
  }) async {
    return animateCamera(
      targetPosition,
      duration: speed.durationMs,
      easing: easing,
    );
  }

  /// Animate character with speed preset
  Future<void> animateCharacterWithSpeed(
    String characterId,
    Position fromPosition,
    Position toPosition,
    AnimationSpeed speed, {
    AnimationEasing? easing,
    Function(Vector3 currentWorldPosition)? onUpdate,
  }) async {
    return animateCharacter(
      characterId,
      fromPosition,
      toPosition,
      duration: speed.durationMs,
      easing: easing,
      onUpdate: onUpdate,
    );
  }

  /// Set camera position instantly (alias for setCameraPosition)
  void setCameraPositionInstant(Vector3 position) {
    setCameraPosition(position);
  }

  /// Skip current camera animation (jump to end)
  void skipCameraAnimation() {
    if (_cameraAnimation != null) {
      _currentCameraPosition = _cameraAnimation!.targetPosition;
      _completeCameraAnimation();
      notifyListeners();
    }
  }

  /// Check if camera is currently animating (alias for backward compatibility)
  bool get cameraIsAnimating => _cameraAnimation != null;

  /// Get current camera position (alias)
  Vector3 get cameraPosition => Vector3.copy(_currentCameraPosition);

  /// Update all animations in a single frame
  void _updateAllAnimations(Timer timer) {
    final now = DateTime.now();
    bool hasUpdates = false;

    // Update camera animation
    if (_cameraAnimation != null) {
      final wasComplete = _cameraAnimation!.isCompleted;
      _cameraAnimation!._update(now);
      _currentCameraPosition = _cameraAnimation!.currentPosition;

      if (_cameraAnimation!.isCompleted && !wasComplete) {
        _completeCameraAnimation();
      }
      hasUpdates = true;
    }

    // Update character animations
    final completedCharacters = <String>[];
    for (final entry in _characterAnimations.entries) {
      final characterId = entry.key;
      final animation = entry.value;

      final wasComplete = animation.isCompleted;
      animation._update(now);

      if (animation.isCompleted && !wasComplete) {
        completedCharacters.add(characterId);
        _completeCharacterAnimation(characterId);
      }
      hasUpdates = true;
    }

    // Remove completed character animations
    for (final characterId in completedCharacters) {
      _characterAnimations.remove(characterId);
    }

    // Stop system if no active animations
    if (!hasActiveAnimations) {
      stop();
      return;
    }

    // Notify listeners if there were updates
    if (hasUpdates) {
      notifyListeners();
    }
  }

  /// Cancel camera animation
  void _cancelCameraAnimation() {
    if (_cameraAnimation != null) {
      _cameraAnimation!._cancel();
      _cameraAnimation = null;
    }
  }

  /// Cancel character animation
  void _cancelCharacterAnimation(String characterId) {
    final animation = _characterAnimations.remove(characterId);
    animation?._cancel();
  }

  /// Complete camera animation
  void _completeCameraAnimation() {
    if (_cameraAnimation != null) {
      _cameraAnimation!._complete();
      _cameraAnimation = null;
    }
  }

  /// Complete character animation
  void _completeCharacterAnimation(String characterId) {
    final animation = _characterAnimations[characterId];
    animation?._complete();
  }

  /// Complete all active animations
  void _completeAllAnimations() {
    // Complete camera animation
    _cancelCameraAnimation();

    // Complete all character animations
    final characterIds = _characterAnimations.keys.toList();
    for (final characterId in characterIds) {
      _cancelCharacterAnimation(characterId);
    }
    _characterAnimations.clear();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// Camera animation data
class CameraAnimation {
  final Vector3 startPosition;
  final Vector3 targetPosition;
  final int duration;
  final AnimationEasing easing;

  late final Completer<void> _completer;

  Vector3 _currentPosition = Vector3.zero();
  double _progress = 0.0;
  bool _isCompleted = false;
  bool _isCancelled = false;

  CameraAnimation({
    required this.startPosition,
    required this.targetPosition,
    required this.duration,
    required this.easing,
  }) {
    _completer = Completer<void>();
    _currentPosition = Vector3.copy(startPosition);
  }

  /// Current camera position
  Vector3 get currentPosition => Vector3.copy(_currentPosition);

  /// Animation progress (0.0 to 1.0)
  double get progress => _progress;

  /// Whether animation uses smooth interpolation
  bool get isSmooth => true;

  /// Whether animation is completed
  bool get isCompleted => _isCompleted;

  /// Update animation
  void _update(DateTime now) {
    if (_isCompleted || _isCancelled) return;

    // Use smooth interpolation for camera (similar to original implementation)
    const smoothingFactor = 0.2; // Increased for faster completion
    final distanceToTarget = _currentPosition.distanceTo(targetPosition);

    // If very close to target, snap to target and complete
    if (distanceToTarget < 0.1) {
      _currentPosition = Vector3.copy(targetPosition);
      _progress = 1.0;
      _isCompleted = true;
      return;
    }

    // Smooth interpolation towards target
    _currentPosition = Vector3(
      _lerp(_currentPosition.x, targetPosition.x, smoothingFactor),
      _lerp(_currentPosition.y, targetPosition.y, smoothingFactor),
      _lerp(_currentPosition.z, targetPosition.z, smoothingFactor),
    );

    // Update progress based on distance
    final totalDistance = startPosition.distanceTo(targetPosition);
    final remainingDistance = _currentPosition.distanceTo(targetPosition);
    _progress = totalDistance > 0
        ? (1.0 - (remainingDistance / totalDistance)).clamp(0.0, 1.0)
        : 1.0;
  }

  /// Complete animation
  void _complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  /// Cancel animation
  void _cancel() {
    _isCancelled = true;
    _currentPosition = Vector3.copy(targetPosition);
    _progress = 1.0;
    _complete();
  }

  /// Linear interpolation helper
  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }
}

/// Character animation data
class CharacterAnimation {
  final String characterId;
  final Position fromPosition;
  final Position toPosition;
  final int duration;
  final AnimationEasing easing;
  final Function(Vector3 currentWorldPosition)? onUpdate;

  late final DateTime _startTime;
  late final Vector3 _fromWorldPosition;
  late final Vector3 _toWorldPosition;
  late final Completer<void> _completer;

  Vector3 _currentWorldPosition = Vector3.zero();
  double _progress = 0.0;
  bool _isCompleted = false;
  bool _isCancelled = false;

  CharacterAnimation({
    required this.characterId,
    required this.fromPosition,
    required this.toPosition,
    required this.duration,
    required this.easing,
    this.onUpdate,
  }) {
    _startTime = DateTime.now();
    _completer = Completer<void>();

    // Convert positions to world coordinates
    _fromWorldPosition = Vector3(
      fromPosition.x * Position.tileSpacing,
      0.0,
      fromPosition.z * Position.tileSpacing,
    );
    _toWorldPosition = Vector3(
      toPosition.x * Position.tileSpacing,
      0.0,
      toPosition.z * Position.tileSpacing,
    );

    _currentWorldPosition = Vector3.copy(_fromWorldPosition);
  }

  /// Current world position
  Vector3 get currentWorldPosition => Vector3.copy(_currentWorldPosition);

  /// Animation progress (0.0 to 1.0)
  double get progress => _progress;

  /// Whether animation uses time-based interpolation
  bool get isTimeBased => true;

  /// Whether animation is completed
  bool get isCompleted => _isCompleted;

  /// Update animation
  void _update(DateTime now) {
    if (_isCompleted || _isCancelled) return;

    final elapsed = now.difference(_startTime).inMilliseconds;
    _progress = (elapsed / duration).clamp(0.0, 1.0);

    if (_progress >= 1.0) {
      _progress = 1.0;
      _isCompleted = true;
    }

    // Apply easing
    final easedProgress = easing.apply(_progress);

    // Interpolate position
    _currentWorldPosition = Vector3(
      _lerp(_fromWorldPosition.x, _toWorldPosition.x, easedProgress),
      _lerp(_fromWorldPosition.y, _toWorldPosition.y, easedProgress),
      _lerp(_fromWorldPosition.z, _toWorldPosition.z, easedProgress),
    );

    // Call update callback
    onUpdate?.call(currentWorldPosition);
  }

  /// Complete animation
  void _complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  /// Cancel animation
  void _cancel() {
    _isCancelled = true;
    _currentWorldPosition = Vector3.copy(_toWorldPosition);
    _progress = 1.0;
    // Ensure the final position update is called when cancelling
    onUpdate?.call(currentWorldPosition);
    debugPrint('CharacterAnimation: Animation cancelled for $characterId, position set to final target: $toPosition');
    _complete();
  }

  /// Linear interpolation helper
  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }
}

/// Unified easing curves for all animations
enum AnimationEasing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  smoothStep,
  smootherStep,
  easeInBack,
  easeOutBack,
  bounce;

  /// Apply the easing curve to a progress value (0.0 to 1.0)
  double apply(double t) {
    switch (this) {
      case AnimationEasing.linear:
        return t;
      case AnimationEasing.easeIn:
        return t * t;
      case AnimationEasing.easeOut:
        return 1 - (1 - t) * (1 - t);
      case AnimationEasing.easeInOut:
        if (t < 0.5) {
          return 2 * t * t;
        } else {
          return 1 - 2 * (1 - t) * (1 - t);
        }
      case AnimationEasing.smoothStep:
        return t * t * (3 - 2 * t);
      case AnimationEasing.smootherStep:
        return t * t * t * (t * (t * 6 - 15) + 10);
      case AnimationEasing.easeInBack:
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return c3 * t * t * t - c1 * t * t;
      case AnimationEasing.easeOutBack:
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return 1 + c3 * _pow(t - 1, 3) + c1 * _pow(t - 1, 2);
      case AnimationEasing.bounce:
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

  /// Helper method for power calculation
  static double _pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case AnimationEasing.linear:
        return 'Linear';
      case AnimationEasing.easeIn:
        return 'Ease In';
      case AnimationEasing.easeOut:
        return 'Ease Out';
      case AnimationEasing.easeInOut:
        return 'Ease In-Out';
      case AnimationEasing.smoothStep:
        return 'Smooth Step';
      case AnimationEasing.smootherStep:
        return 'Smoother Step';
      case AnimationEasing.easeInBack:
        return 'Ease In Back';
      case AnimationEasing.easeOutBack:
        return 'Ease Out Back';
      case AnimationEasing.bounce:
        return 'Bounce';
    }
  }
}

/// Unified animation speed presets
enum AnimationSpeed {
  instant, // 0ms (no animation)
  fast, // 100ms
  normal, // 200ms
  slow; // 300ms

  /// Duration in milliseconds
  int get durationMs {
    switch (this) {
      case AnimationSpeed.instant:
        return 0;
      case AnimationSpeed.fast:
        return 100;
      case AnimationSpeed.normal:
        return 200;
      case AnimationSpeed.slow:
        return 300;
    }
  }

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case AnimationSpeed.instant:
        return 'Instant';
      case AnimationSpeed.fast:
        return 'Fast';
      case AnimationSpeed.normal:
        return 'Normal';
      case AnimationSpeed.slow:
        return 'Slow';
    }
  }
}
