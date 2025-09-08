import 'dart:math';
import 'ally_character.dart';
import 'enemy_character.dart';
import 'combat_manager.dart';
import '../l10n/strings.g.dart';

/// System for providing combat feedback through dialogue and events
class CombatFeedbackSystem {
  /// List of recent combat feedback messages
  final List<CombatFeedbackMessage> _recentMessages = [];

  /// Maximum number of recent messages to keep
  static const int maxRecentMessages = 20;

  /// Random number generator for message variation
  static final Random _random = Random();

  /// Generates feedback for combat results
  List<CombatFeedbackMessage> generateCombatFeedback(
    List<CombatResult> combatResults,
  ) {
    final messages = <CombatFeedbackMessage>[];

    for (final result in combatResults) {
      final message = _createCombatMessage(result);
      messages.add(message);
      _addMessage(message);
    }

    return messages;
  }

  /// Generates feedback for ally state changes
  CombatFeedbackMessage? generateAllyStateChangeFeedback(
    AllyCharacter ally,
    AllyState previousState,
    AllyState newState,
  ) {
    if (previousState == newState) return null;

    final message = _createAllyStateChangeMessage(
      ally,
      previousState,
      newState,
    );
    _addMessage(message);
    return message;
  }

  /// Generates feedback for enemy defeat
  CombatFeedbackMessage generateEnemyDefeatedFeedback(EnemyCharacter enemy) {
    final message = _createEnemyDefeatedMessage(enemy);
    _addMessage(message);
    return message;
  }

  /// Generates feedback for ally satisfaction changes
  CombatFeedbackMessage? generateSatisfactionFeedback(
    AllyCharacter ally,
    int previousSatisfaction,
    int newSatisfaction,
  ) {
    final difference = newSatisfaction - previousSatisfaction;
    if (difference.abs() < 10) return null; // Only report significant changes

    final message = _createSatisfactionChangeMessage(ally, difference);
    _addMessage(message);
    return message;
  }

  /// Generates feedback for combat engagement
  CombatFeedbackMessage generateCombatEngagementFeedback(
    AllyCharacter ally,
    EnemyCharacter enemy,
  ) {
    final message = _createCombatEngagementMessage(ally, enemy);
    _addMessage(message);
    return message;
  }

  /// Creates a combat result message
  CombatFeedbackMessage _createCombatMessage(CombatResult result) {
    final allyName = _getCharacterDisplayName(result.ally);
    final enemyName = _getCharacterDisplayName(result.enemy);

    String messageText;
    CombatFeedbackType messageType;

    if (result.isAllyVictory) {
      messageText = _getVictoryMessage(
        allyName,
        enemyName,
        result.allyDamageDealt,
      );
      messageType = CombatFeedbackType.allyVictory;
    } else if (result.isEnemyVictory) {
      messageText = _getDefeatMessage(
        allyName,
        enemyName,
        result.enemyDamageDealt,
      );
      messageType = CombatFeedbackType.allyDefeat;
    } else if (result.isMutualDefeat) {
      messageText = _getMutualDefeatMessage(allyName, enemyName);
      messageType = CombatFeedbackType.mutualDefeat;
    } else {
      messageText = _getOngoingCombatMessage(
        allyName,
        enemyName,
        result.allyDamageDealt,
        result.enemyDamageDealt,
      );
      messageType = CombatFeedbackType.ongoingCombat;
    }

    return CombatFeedbackMessage(
      text: messageText,
      type: messageType,
      timestamp: DateTime.now(),
      ally: result.ally,
      enemy: result.enemy,
      combatResult: result,
    );
  }

  /// Creates an ally state change message
  CombatFeedbackMessage _createAllyStateChangeMessage(
    AllyCharacter ally,
    AllyState previousState,
    AllyState newState,
  ) {
    final allyName = _getCharacterDisplayName(ally);
    String messageText;
    CombatFeedbackType messageType;

    switch (newState) {
      case AllyState.combat:
        final messages = _getStateChangeMessages('combat');
        messageText = messages[_random.nextInt(messages.length)].replaceAll(
          '{ally}',
          allyName,
        );
        messageType = CombatFeedbackType.stateChange;
        break;
      case AllyState.following:
        final messages = _getStateChangeMessages('following');
        messageText = messages[_random.nextInt(messages.length)].replaceAll(
          '{ally}',
          allyName,
        );
        messageType = CombatFeedbackType.stateChange;
        break;
      case AllyState.satisfied:
        final messages = _getStateChangeMessages('satisfied');
        messageText = messages[_random.nextInt(messages.length)].replaceAll(
          '{ally}',
          allyName,
        );
        messageType = CombatFeedbackType.allySatisfied;
        break;
    }

    return CombatFeedbackMessage(
      text: messageText,
      type: messageType,
      timestamp: DateTime.now(),
      ally: ally,
    );
  }

  /// Creates an enemy defeated message
  CombatFeedbackMessage _createEnemyDefeatedMessage(EnemyCharacter enemy) {
    final enemyName = _getCharacterDisplayName(enemy);
    final messages = [
      t.combat.messages.hasBeenDefeated.replaceAll(' ', enemyName),
      t.combat.messages.fallsToGround.replaceAll(' ', enemyName),
      t.combat.messages.noLongerThreat.replaceAll(' ', enemyName),
    ];

    return CombatFeedbackMessage(
      text: messages[_random.nextInt(messages.length)],
      type: CombatFeedbackType.enemyDefeated,
      timestamp: DateTime.now(),
      enemy: enemy,
    );
  }

  /// Creates a satisfaction change message
  CombatFeedbackMessage _createSatisfactionChangeMessage(
    AllyCharacter ally,
    int satisfactionChange,
  ) {
    final allyName = _getCharacterDisplayName(ally);
    String messageText;
    CombatFeedbackType messageType;

    if (satisfactionChange > 0) {
      final messages = [
        t.combat.messages.looksContent.replaceAll(' ', allyName),
        t.combat.messages.seemsPleased.replaceAll(' ', allyName),
        t.combat.messages.appearsHappier.replaceAll(' ', allyName),
      ];
      messageText = messages[_random.nextInt(messages.length)];
      messageType = CombatFeedbackType.satisfactionIncrease;
    } else {
      final messages = [
        t.combat.messages.looksLessSatisfied.replaceAll(' ', allyName),
        t.combat.messages.seemsTroubled.replaceAll(' ', allyName),
        t.combat.messages.appearsUnhappy.replaceAll(' ', allyName),
      ];
      messageText = messages[_random.nextInt(messages.length)];
      messageType = CombatFeedbackType.satisfactionDecrease;
    }

    return CombatFeedbackMessage(
      text: messageText,
      type: messageType,
      timestamp: DateTime.now(),
      ally: ally,
    );
  }

  /// Creates a combat engagement message
  CombatFeedbackMessage _createCombatEngagementMessage(
    AllyCharacter ally,
    EnemyCharacter enemy,
  ) {
    final allyName = _getCharacterDisplayName(ally);
    final enemyName = _getCharacterDisplayName(enemy);

    final messages = [
      t.combat.messages.engagesInCombat
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
      t.combat.messages.movesToAttack
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
      t.combat.messages.confronts
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
    ];

    return CombatFeedbackMessage(
      text: messages[_random.nextInt(messages.length)],
      type: CombatFeedbackType.combatEngagement,
      timestamp: DateTime.now(),
      ally: ally,
      enemy: enemy,
    );
  }

  /// Gets victory message variations
  String _getVictoryMessage(String allyName, String enemyName, int damage) {
    final messages = [
      t.combat.messages.allyDefeatsEnemyStrike
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
      t.combat.messages.allyEmergesVictorious
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
      t.combat.messages.allyOvercomes
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Gets defeat message variations
  String _getDefeatMessage(String allyName, String enemyName, int damage) {
    final messages = [
      t.combat.messages.allyDefeatedBy
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
      t.combat.messages.enemyOvercomes
          .replaceAll(' ', enemyName)
          .replaceAll(' ', allyName),
      t.combat.messages.allyFalls
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Gets mutual defeat message variations
  String _getMutualDefeatMessage(String allyName, String enemyName) {
    final messages = [
      t.combat.messages.bothDefeatEachOther
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
      t.combat.messages.bothFallInCombat
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
      t.combat.messages.bothDefeated
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Gets ongoing combat message variations
  String _getOngoingCombatMessage(
    String allyName,
    String enemyName,
    int allyDamage,
    int enemyDamage,
  ) {
    final messages = [
      t.combat.messages.exchangeBlows
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
      t.combat.messages.battleContinues
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
      t.combat.messages.fightFiercely
          .replaceAll(' ', allyName)
          .replaceAll(' ', enemyName),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Gets state change message variations
  List<String> _getStateChangeMessages(String state) {
    switch (state) {
      case 'combat':
        return [
          t.combat.messages.entersCombat,
          t.combat.messages.preparesForBattle,
          t.combat.messages.readiesForCombat,
        ];
      case 'following':
        return [
          t.combat.messages.returnsToFollowing,
          t.combat.messages.comesBack,
          t.combat.messages.resumesFollowing,
        ];
      case 'satisfied':
        return [
          t.combat.messages.looksSatisfied,
          t.combat.messages.seemsContent,
          t.combat.messages.appearsFullfilled,
        ];
      default:
        return ['{ally} changes state.'];
    }
  }

  /// Gets a display name for a character
  String _getCharacterDisplayName(dynamic character) {
    if (character is AllyCharacter) {
      return 'Ally ${character.originalEnemy.enemyType.displayName}';
    } else if (character is EnemyCharacter) {
      return character.enemyType.displayName;
    }
    return 'Unknown';
  }

  /// Adds a message to the recent messages list
  void _addMessage(CombatFeedbackMessage message) {
    _recentMessages.add(message);

    // Keep only the most recent messages
    if (_recentMessages.length > maxRecentMessages) {
      _recentMessages.removeAt(0);
    }
  }

  /// Gets all recent combat feedback messages
  List<CombatFeedbackMessage> get recentMessages =>
      List.unmodifiable(_recentMessages);

  /// Gets recent messages of a specific type
  List<CombatFeedbackMessage> getMessagesByType(CombatFeedbackType type) {
    return _recentMessages.where((message) => message.type == type).toList();
  }

  /// Gets recent messages involving a specific ally
  List<CombatFeedbackMessage> getMessagesForAlly(AllyCharacter ally) {
    return _recentMessages.where((message) => message.ally == ally).toList();
  }

  /// Gets recent messages involving a specific enemy
  List<CombatFeedbackMessage> getMessagesForEnemy(EnemyCharacter enemy) {
    return _recentMessages.where((message) => message.enemy == enemy).toList();
  }

  /// Clears all recent messages
  void clearMessages() {
    _recentMessages.clear();
  }

  /// Gets the most recent message
  CombatFeedbackMessage? get latestMessage =>
      _recentMessages.isNotEmpty ? _recentMessages.last : null;
}

/// Represents a combat feedback message
class CombatFeedbackMessage {
  final String text;
  final CombatFeedbackType type;
  final DateTime timestamp;
  final AllyCharacter? ally;
  final EnemyCharacter? enemy;
  final CombatResult? combatResult;

  CombatFeedbackMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    this.ally,
    this.enemy,
    this.combatResult,
  });

  /// Gets the age of this message
  Duration get age => DateTime.now().difference(timestamp);

  /// Returns true if this message is recent (less than 30 seconds old)
  bool get isRecent => age.inSeconds < 30;

  /// Returns true if this message involves combat
  bool get isCombatRelated => [
    CombatFeedbackType.allyVictory,
    CombatFeedbackType.allyDefeat,
    CombatFeedbackType.mutualDefeat,
    CombatFeedbackType.ongoingCombat,
    CombatFeedbackType.combatEngagement,
  ].contains(type);

  /// Returns true if this message is about ally state changes
  bool get isStateRelated => [
    CombatFeedbackType.stateChange,
    CombatFeedbackType.allySatisfied,
    CombatFeedbackType.satisfactionIncrease,
    CombatFeedbackType.satisfactionDecrease,
  ].contains(type);

  @override
  String toString() => '$text (${type.displayName})';
}

/// Types of combat feedback messages
enum CombatFeedbackType {
  allyVictory,
  allyDefeat,
  mutualDefeat,
  ongoingCombat,
  combatEngagement,
  stateChange,
  allySatisfied,
  satisfactionIncrease,
  satisfactionDecrease,
  enemyDefeated;

  String get displayName {
    switch (this) {
      case CombatFeedbackType.allyVictory:
        return 'Ally Victory';
      case CombatFeedbackType.allyDefeat:
        return 'Ally Defeat';
      case CombatFeedbackType.mutualDefeat:
        return 'Mutual Defeat';
      case CombatFeedbackType.ongoingCombat:
        return 'Ongoing Combat';
      case CombatFeedbackType.combatEngagement:
        return 'Combat Engagement';
      case CombatFeedbackType.stateChange:
        return 'State Change';
      case CombatFeedbackType.allySatisfied:
        return 'Ally Satisfied';
      case CombatFeedbackType.satisfactionIncrease:
        return 'Satisfaction Increase';
      case CombatFeedbackType.satisfactionDecrease:
        return 'Satisfaction Decrease';
      case CombatFeedbackType.enemyDefeated:
        return 'Enemy Defeated';
    }
  }

  /// Returns true if this is a positive feedback type
  bool get isPositive => [
    CombatFeedbackType.allyVictory,
    CombatFeedbackType.satisfactionIncrease,
    CombatFeedbackType.enemyDefeated,
  ].contains(this);

  /// Returns true if this is a negative feedback type
  bool get isNegative => [
    CombatFeedbackType.allyDefeat,
    CombatFeedbackType.allySatisfied,
    CombatFeedbackType.satisfactionDecrease,
  ].contains(this);
}
