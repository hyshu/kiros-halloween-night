import 'package:flutter/foundation.dart';

/// Manages animation phases between turns in the turn-based game
class AnimationPhaseManager extends ChangeNotifier {
  /// Current animation phase state
  AnimationPhase _currentPhase = AnimationPhase.none;

  /// Whether an animation is currently playing
  bool _isAnimating = false;

  /// Duration of the animation phase (placeholder)
  static const Duration animationDuration = Duration(milliseconds: 100);

  /// Current animation phase
  AnimationPhase get currentPhase => _currentPhase;

  /// Whether an animation is currently playing
  bool get isAnimating => _isAnimating;

  /// Plays the movement animation phase
  Future<void> playMovementAnimation({
    Future<void> Function()? onMovementAnimation,
  }) async {
    await _playAnimationPhase(
      AnimationPhase.movement, 
      customAction: onMovementAnimation,
    );
  }

  /// Plays the combat animation phase
  Future<void> playCombatAnimation() async {
    await _playAnimationPhase(AnimationPhase.combat);
  }

  /// Plays the AI movement animation phase
  Future<void> playAIMovementAnimation() async {
    await _playAnimationPhase(AnimationPhase.aiMovement);
  }

  /// Plays the ally movement animation phase
  Future<void> playAllyMovementAnimation() async {
    await _playAnimationPhase(AnimationPhase.allyMovement);
  }

  /// Plays the effects animation phase (for abilities, items, etc.)
  Future<void> playEffectsAnimation() async {
    await _playAnimationPhase(AnimationPhase.effects);
  }

  /// Generic method to play any animation phase
  Future<void> _playAnimationPhase(
    AnimationPhase phase, {
    Future<void> Function()? customAction,
  }) async {
    if (_isAnimating) return; // Prevent overlapping animations

    _currentPhase = phase;
    _isAnimating = true;
    notifyListeners();

    debugPrint(
      'AnimationPhaseManager: Starting ${phase.displayName} animation',
    );

    // Execute custom action if provided (e.g., camera animation)
    if (customAction != null) {
      await customAction();
    } else {
      // Placeholder: Use Future.delayed for phases without custom actions
      await Future.delayed(animationDuration);
    }

    _isAnimating = false;
    _currentPhase = AnimationPhase.none;
    notifyListeners();

    debugPrint(
      'AnimationPhaseManager: Finished ${phase.displayName} animation',
    );
  }

  /// Skips the current animation (for fast play or debugging)
  void skipCurrentAnimation() {
    if (_isAnimating) {
      _isAnimating = false;
      _currentPhase = AnimationPhase.none;
      notifyListeners();
      debugPrint('AnimationPhaseManager: Animation skipped');
    }
  }

  /// Checks if a specific animation phase is currently playing
  bool isPlayingPhase(AnimationPhase phase) {
    return _isAnimating && _currentPhase == phase;
  }

  /// Gets the progress of the current animation (0.0 to 1.0)
  /// This is a placeholder implementation
  double get animationProgress {
    // In the future, this will return actual animation progress
    return _isAnimating ? 0.5 : 1.0;
  }

  @override
  void dispose() {
    _isAnimating = false;
    super.dispose();
  }
}

/// Represents different types of animation phases
enum AnimationPhase {
  none,
  movement, // Player movement animations
  combat, // Combat animations (attacks, damage)
  aiMovement, // Enemy AI movement animations
  allyMovement, // Ally movement animations
  effects; // Special effects (abilities, items, etc.)

  /// Human-readable display name for the animation phase
  String get displayName {
    switch (this) {
      case AnimationPhase.none:
        return 'None';
      case AnimationPhase.movement:
        return 'Player Movement';
      case AnimationPhase.combat:
        return 'Combat';
      case AnimationPhase.aiMovement:
        return 'Enemy Movement';
      case AnimationPhase.allyMovement:
        return 'Ally Movement';
      case AnimationPhase.effects:
        return 'Effects';
    }
  }

  /// Whether this animation phase blocks user input
  bool get blocksInput {
    switch (this) {
      case AnimationPhase.none:
        return false;
      case AnimationPhase.movement:
      case AnimationPhase.combat:
      case AnimationPhase.aiMovement:
      case AnimationPhase.allyMovement:
      case AnimationPhase.effects:
        return true;
    }
  }
}
