/// Represents different types of dialogue events in the game
enum DialogueType {
  interaction,
  itemCollection,
  combat,
  playerAttack,
  enemyAttack,
  story,
  boss
}

/// Represents a single dialogue event with message and interaction options
class DialogueEvent {
  final String message;
  final DialogueType type;
  final bool canAdvance;
  final bool canDismiss;
  final String? speakerName;
  final Duration? displayDuration;

  const DialogueEvent({
    required this.message,
    required this.type,
    this.canAdvance = true,
    this.canDismiss = true,
    this.speakerName,
    this.displayDuration,
  });

  /// Creates a dialogue event for enemy interactions
  factory DialogueEvent.interaction(String message, {String? speakerName}) {
    return DialogueEvent(
      message: message,
      type: DialogueType.interaction,
      speakerName: speakerName,
    );
  }

  /// Creates a dialogue event for item collection
  factory DialogueEvent.itemCollection(String message) {
    return DialogueEvent(
      message: message,
      type: DialogueType.itemCollection,
      displayDuration: const Duration(seconds: 2),
    );
  }

  /// Creates a dialogue event for combat feedback
  factory DialogueEvent.combat(String message) {
    return DialogueEvent(
      message: message,
      type: DialogueType.combat,
      displayDuration: const Duration(seconds: 3),
    );
  }

  /// Creates a dialogue event for player attack
  factory DialogueEvent.playerAttack(String message) {
    return DialogueEvent(
      message: message,
      type: DialogueType.playerAttack,
      displayDuration: const Duration(seconds: 3),
    );
  }

  /// Creates a dialogue event for enemy attack
  factory DialogueEvent.enemyAttack(String message) {
    return DialogueEvent(
      message: message,
      type: DialogueType.enemyAttack,
      displayDuration: const Duration(seconds: 3),
    );
  }

  /// Creates a dialogue event for story progression
  factory DialogueEvent.story(String message, {String? speakerName}) {
    return DialogueEvent(
      message: message,
      type: DialogueType.story,
      speakerName: speakerName,
    );
  }

  /// Creates a dialogue event for boss encounters
  factory DialogueEvent.boss(String message, {String? speakerName}) {
    return DialogueEvent(
      message: message,
      type: DialogueType.boss,
      speakerName: speakerName,
    );
  }

  @override
  String toString() {
    return 'DialogueEvent(message: $message, type: $type, speaker: $speakerName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DialogueEvent &&
        other.message == message &&
        other.type == type &&
        other.canAdvance == canAdvance &&
        other.canDismiss == canDismiss &&
        other.speakerName == speakerName;
  }

  @override
  int get hashCode {
    return Object.hash(message, type, canAdvance, canDismiss, speakerName);
  }
}