import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'position.dart';

/// Handles smooth character movement animations with interpolation
class CharacterMovementAnimationSystem extends ChangeNotifier {
  /// Active character animations
  final Map<String, CharacterMovementAnimation> _activeAnimations = {};

  /// Animation update timer
  Timer? _animationTimer;

  /// Animation frame rate (60 FPS)
  static const int _frameRate = 60;
  static const int _frameTimeMs = 1000 ~/ _frameRate;

  /// Default animation duration in milliseconds
  static const int _defaultDuration = 250;

  /// Whether the system is running
  bool _isRunning = false;

  /// Get all active animations
  Map<String, CharacterMovementAnimation> get activeAnimations =>
      Map.unmodifiable(_activeAnimations);

  /// Whether a character is currently animating
  bool isCharacterAnimating(String characterId) {
    return _activeAnimations.containsKey(characterId);
  }

  /// Whether any characters are currently animating
  bool get hasActiveAnimations => _activeAnimations.isNotEmpty;

  /// Start the animation system
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _animationTimer = Timer.periodic(
      Duration(milliseconds: _frameTimeMs),
      _updateAnimations,
    );

    debugPrint('CharacterMovementAnimationSystem: Started');
  }

  /// Stop the animation system
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _animationTimer?.cancel();
    _animationTimer = null;

    // Complete all active animations immediately
    final completers = <Completer<void>>[];
    for (final animation in _activeAnimations.values) {
      if (!animation._completer.isCompleted) {
        animation._jumpToEnd();
        completers.add(animation._completer);
      }
    }

    _activeAnimations.clear();

    // Complete all futures
    for (final completer in completers) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    debugPrint('CharacterMovementAnimationSystem: Stopped');
  }

  /// Animate a character's movement from one position to another
  Future<void> animateCharacterMovement(
    String characterId,
    Position fromPosition,
    Position toPosition, {
    int? duration,
    MovementEasing? easing,
    Function(Vector3 currentWorldPosition)? onUpdate,
  }) async {
    // Cancel any existing animation for this character
    _cancelCharacterAnimation(characterId);

    // Create new animation
    final animation = CharacterMovementAnimation(
      characterId: characterId,
      fromPosition: fromPosition,
      toPosition: toPosition,
      duration: duration ?? _defaultDuration,
      easing: easing ?? MovementEasing.easeInOut,
      onUpdate: onUpdate,
    );

    _activeAnimations[characterId] = animation;

    // Start the system if not already running
    if (!_isRunning) {
      start();
    }

    debugPrint(
      'CharacterMovementAnimationSystem: Started animation for $characterId '
      'from $fromPosition to $toPosition (${animation.duration}ms)',
    );

    notifyListeners();
    return animation._completer.future;
  }

  /// Cancel animation for a specific character
  void cancelCharacterAnimation(String characterId) {
    _cancelCharacterAnimation(characterId);
    notifyListeners();
  }

  /// Internal method to cancel character animation
  void _cancelCharacterAnimation(String characterId) {
    final animation = _activeAnimations.remove(characterId);
    if (animation != null && !animation._completer.isCompleted) {
      animation._jumpToEnd();
      animation._completer.complete();
      debugPrint(
        'CharacterMovementAnimationSystem: Cancelled animation for $characterId',
      );
    }
  }

  /// Cancel all active animations
  void cancelAllAnimations() {
    final characterIds = _activeAnimations.keys.toList();
    for (final characterId in characterIds) {
      _cancelCharacterAnimation(characterId);
    }
    notifyListeners();
  }

  /// Update all active animations
  void _updateAnimations(Timer timer) {
    if (_activeAnimations.isEmpty) {
      stop();
      return;
    }

    final now = DateTime.now();
    final completedAnimations = <String>[];

    for (final entry in _activeAnimations.entries) {
      final characterId = entry.key;
      final animation = entry.value;

      animation._update(now);

      if (animation.isCompleted) {
        completedAnimations.add(characterId);
        if (!animation._completer.isCompleted) {
          animation._completer.complete();
          debugPrint(
            'CharacterMovementAnimationSystem: Completed animation for $characterId',
          );
        }
      }
    }

    // Remove completed animations
    for (final characterId in completedAnimations) {
      _activeAnimations.remove(characterId);
    }

    // Notify listeners of updates
    if (_activeAnimations.isNotEmpty || completedAnimations.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Get current animated world position for a character
  Vector3? getCharacterWorldPosition(String characterId) {
    final animation = _activeAnimations[characterId];
    return animation?.currentWorldPosition;
  }

  /// Get animation progress for a character (0.0 to 1.0)
  double getCharacterAnimationProgress(String characterId) {
    final animation = _activeAnimations[characterId];
    return animation?.progress ?? 1.0;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// Represents a single character movement animation
class CharacterMovementAnimation {
  final String characterId;
  final Position fromPosition;
  final Position toPosition;
  final int duration;
  final MovementEasing easing;
  final Function(Vector3 currentWorldPosition)? onUpdate;

  late final DateTime _startTime;
  late final Vector3 _fromWorldPosition;
  late final Vector3 _toWorldPosition;
  late final Completer<void> _completer;

  Vector3 _currentWorldPosition = Vector3.zero();
  double _progress = 0.0;
  bool _isCompleted = false;

  CharacterMovementAnimation({
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

  /// Current world position of the character
  Vector3 get currentWorldPosition => Vector3.copy(_currentWorldPosition);

  /// Animation progress (0.0 to 1.0)
  double get progress => _progress;

  /// Whether the animation is completed
  bool get isCompleted => _isCompleted;

  /// Update the animation
  void _update(DateTime now) {
    if (_isCompleted) return;

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

  /// Jump to the end position immediately
  void _jumpToEnd() {
    _progress = 1.0;
    _isCompleted = true;
    _currentWorldPosition = Vector3.copy(_toWorldPosition);
    onUpdate?.call(currentWorldPosition);
  }

  /// Linear interpolation helper
  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }
}

/// Different easing curves for character movement
enum MovementEasing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  smoothStep,
  smootherStep;

  /// Apply the easing curve to a progress value (0.0 to 1.0)
  double apply(double t) {
    switch (this) {
      case MovementEasing.linear:
        return t;

      case MovementEasing.easeIn:
        return t * t;

      case MovementEasing.easeOut:
        return 1 - (1 - t) * (1 - t);

      case MovementEasing.easeInOut:
        if (t < 0.5) {
          return 2 * t * t;
        } else {
          return 1 - 2 * (1 - t) * (1 - t);
        }

      case MovementEasing.smoothStep:
        return t * t * (3 - 2 * t);

      case MovementEasing.smootherStep:
        return t * t * t * (t * (t * 6 - 15) + 10);
    }
  }

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case MovementEasing.linear:
        return 'Linear';
      case MovementEasing.easeIn:
        return 'Ease In';
      case MovementEasing.easeOut:
        return 'Ease Out';
      case MovementEasing.easeInOut:
        return 'Ease In-Out';
      case MovementEasing.smoothStep:
        return 'Smooth Step';
      case MovementEasing.smootherStep:
        return 'Smoother Step';
    }
  }
}

/// Animation speed presets for character movement
enum CharacterAnimationSpeed {
  slow, // 400ms
  normal, // 250ms
  fast, // 150ms
  instant; // 0ms (no animation)

  /// Duration in milliseconds
  int get durationMs {
    switch (this) {
      case CharacterAnimationSpeed.slow:
        return 400;
      case CharacterAnimationSpeed.normal:
        return 250;
      case CharacterAnimationSpeed.fast:
        return 150;
      case CharacterAnimationSpeed.instant:
        return 0;
    }
  }

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case CharacterAnimationSpeed.slow:
        return 'Slow';
      case CharacterAnimationSpeed.normal:
        return 'Normal';
      case CharacterAnimationSpeed.fast:
        return 'Fast';
      case CharacterAnimationSpeed.instant:
        return 'Instant';
    }
  }
}
