import 'package:flutter/foundation.dart';
import 'candy_collection_system.dart';
import 'candy_item.dart';
import 'position.dart';
import '../l10n/strings.g.dart';

/// Types of visual feedback for candy collection
enum FeedbackType {
  /// Simple text message
  text,

  /// Floating text that moves upward
  floatingText,

  /// Particle effect
  particles,

  /// Screen flash
  flash,

  /// Sound effect (placeholder for future audio system)
  sound,
}

/// Visual feedback data for candy collection events
class CollectionFeedback {
  /// Type of feedback to display
  final FeedbackType type;

  /// Message to display
  final String message;

  /// Position where the feedback should appear
  final Position position;

  /// Duration of the feedback in milliseconds
  final int durationMs;

  /// Color of the feedback (as hex string)
  final String color;

  /// Size multiplier for the feedback
  final double scale;

  /// Whether the feedback is currently active
  bool isActive;

  /// Time when the feedback was created
  final DateTime createdAt;

  CollectionFeedback({
    required this.type,
    required this.message,
    required this.position,
    this.durationMs = 2000,
    this.color = '#00FF00', // Green by default
    this.scale = 1.0,
  }) : isActive = true,
       createdAt = DateTime.now();

  /// Returns true if the feedback has expired
  bool get isExpired {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds;
    return elapsed >= durationMs;
  }

  /// Gets the remaining time in milliseconds
  int get remainingTimeMs {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds;
    return (durationMs - elapsed).clamp(0, durationMs);
  }

  /// Gets the progress of the feedback (0.0 to 1.0)
  double get progress {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds;
    return (elapsed / durationMs).clamp(0.0, 1.0);
  }

  /// Deactivates the feedback
  void deactivate() {
    isActive = false;
  }

  @override
  String toString() => '$type: $message at $position';
}

/// Manages visual feedback for candy collection events
class CollectionFeedbackManager extends ChangeNotifier {
  /// List of active feedback items
  final List<CollectionFeedback> _activeFeedback = [];

  /// Maximum number of active feedback items
  final int maxActiveFeedback;

  CollectionFeedbackManager({this.maxActiveFeedback = 20});

  /// Gets all active feedback items
  List<CollectionFeedback> get activeFeedback =>
      List.unmodifiable(_activeFeedback);

  /// Processes a candy collection event and creates appropriate feedback
  void processCollectionEvent(CandyCollectionEvent event) {
    if (event.successful) {
      _createSuccessfulCollectionFeedback(event);
    } else {
      _createFailedCollectionFeedback(event);
    }

    _cleanupExpiredFeedback();
    notifyListeners();
  }

  /// Creates feedback for successful candy collection
  void _createSuccessfulCollectionFeedback(CandyCollectionEvent event) {
    final candy = event.candy;
    final message = _getCollectionMessage(candy);
    final color = _getEffectColor(candy.effect);

    // Create floating text feedback
    final feedback = CollectionFeedback(
      type: FeedbackType.floatingText,
      message: message,
      position: event.position,
      durationMs: 2500,
      color: color,
      scale: 1.2,
    );

    _addFeedback(feedback);

    // Create additional particle effect for special candy
    if (_isSpecialCandy(candy)) {
      final particleFeedback = CollectionFeedback(
        type: FeedbackType.particles,
        message: '✨',
        position: event.position,
        durationMs: 3000,
        color: '#FFD700', // Gold
        scale: 1.5,
      );

      _addFeedback(particleFeedback);
    }
  }

  /// Creates feedback for failed candy collection
  void _createFailedCollectionFeedback(CandyCollectionEvent event) {
    final feedback = CollectionFeedback(
      type: FeedbackType.text,
      message: t.items.inventoryFull,
      position: event.position,
      durationMs: 1500,
      color: '#FF4444', // Red
      scale: 1.0,
    );

    _addFeedback(feedback);
  }

  /// Gets an appropriate message for candy collection
  String _getCollectionMessage(CandyItem candy) {
    switch (candy.effect) {
      case CandyEffect.healthBoost:
        return t.items.healthBoost.replaceAll('{value}', '${candy.value}');
      case CandyEffect.maxHealthIncrease:
        return t.items.maxHealthIncrease.replaceAll('{value}', '${candy.value}');
      case CandyEffect.speedIncrease:
        return t.items.speedBoost;
      case CandyEffect.allyStrength:
        return t.items.allyPower;
      case CandyEffect.specialAbility:
        return t.items.specialPower;
      case CandyEffect.statModification:
        return t.items.statBoost;
    }
  }

  /// Gets the color associated with a candy effect
  String _getEffectColor(CandyEffect effect) {
    switch (effect) {
      case CandyEffect.healthBoost:
        return '#00FF00'; // Green
      case CandyEffect.maxHealthIncrease:
        return '#00FFFF'; // Cyan
      case CandyEffect.speedIncrease:
        return '#FFFF00'; // Yellow
      case CandyEffect.allyStrength:
        return '#FF8800'; // Orange
      case CandyEffect.specialAbility:
        return '#FF00FF'; // Magenta
      case CandyEffect.statModification:
        return '#8800FF'; // Purple
    }
  }

  /// Checks if a candy is considered special (rare effects)
  bool _isSpecialCandy(CandyItem candy) {
    return candy.effect == CandyEffect.specialAbility ||
        candy.effect == CandyEffect.maxHealthIncrease ||
        (candy.effect == CandyEffect.healthBoost && candy.value >= 25);
  }

  /// Adds feedback to the active list
  void _addFeedback(CollectionFeedback feedback) {
    _activeFeedback.add(feedback);

    // Remove oldest feedback if we exceed the maximum
    while (_activeFeedback.length > maxActiveFeedback) {
      _activeFeedback.removeAt(0);
    }
  }

  /// Removes expired feedback items
  void _cleanupExpiredFeedback() {
    _activeFeedback.removeWhere((feedback) => feedback.isExpired);
  }

  /// Updates all active feedback (should be called regularly)
  void update() {
    _cleanupExpiredFeedback();

    if (_activeFeedback.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Creates custom feedback at a specific position
  void createCustomFeedback({
    required String message,
    required Position position,
    FeedbackType type = FeedbackType.text,
    int durationMs = 2000,
    String color = '#FFFFFF',
    double scale = 1.0,
  }) {
    final feedback = CollectionFeedback(
      type: type,
      message: message,
      position: position,
      durationMs: durationMs,
      color: color,
      scale: scale,
    );

    _addFeedback(feedback);
    notifyListeners();
  }

  /// Clears all active feedback
  void clearAll() {
    _activeFeedback.clear();
    notifyListeners();
  }

  /// Gets feedback at a specific position
  List<CollectionFeedback> getFeedbackAt(Position position) {
    return _activeFeedback.where((f) => f.position == position).toList();
  }

  /// Gets feedback of a specific type
  List<CollectionFeedback> getFeedbackByType(FeedbackType type) {
    return _activeFeedback.where((f) => f.type == type).toList();
  }

  @override
  String toString() =>
      'CollectionFeedbackManager(${_activeFeedback.length} active)';
}
