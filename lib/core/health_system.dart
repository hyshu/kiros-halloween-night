import 'character.dart';
import 'ally_character.dart';
import 'enemy_character.dart';

/// Manages health tracking and damage application for all characters
class HealthSystem {
  /// Map to track health changes for characters
  final Map<String, HealthTracker> _healthTrackers = {};

  /// List of health change events for feedback
  final List<HealthChangeEvent> _recentEvents = [];

  /// Maximum number of recent events to keep
  static const int maxRecentEvents = 50;

  /// Applies damage to a character and returns true if they survive
  bool applyDamage(Character character, int damage) {
    if (damage <= 0) return character.isAlive;

    // Get or create health tracker
    final tracker = _getOrCreateTracker(character);

    // Record the damage
    final previousHealth = character.health;
    final survived = character.takeDamage(damage);
    final actualDamage = previousHealth - character.health;

    // Update tracker
    tracker.recordDamage(actualDamage);

    // Create health change event
    final event = HealthChangeEvent(
      characterId: character.id,
      changeType: HealthChangeType.damage,
      amount: actualDamage,
      previousHealth: previousHealth,
      newHealth: character.health,
      timestamp: DateTime.now(),
    );

    _addEvent(event);

    // Handle special cases for different character types
    if (!survived) {
      _handleCharacterDefeated(character);
    }

    return survived;
  }

  /// Applies healing to a character
  void applyHealing(Character character, int healing) {
    if (healing <= 0) return;

    // Get or create health tracker
    final tracker = _getOrCreateTracker(character);

    // Record the healing
    final previousHealth = character.health;
    character.heal(healing);
    final actualHealing = character.health - previousHealth;

    // Update tracker
    tracker.recordHealing(actualHealing);

    // Create health change event
    final event = HealthChangeEvent(
      characterId: character.id,
      changeType: HealthChangeType.healing,
      amount: actualHealing,
      previousHealth: previousHealth,
      newHealth: character.health,
      timestamp: DateTime.now(),
    );

    _addEvent(event);
  }

  /// Gets the health tracker for a character
  HealthTracker? getHealthTracker(String characterId) {
    return _healthTrackers[characterId];
  }

  /// Gets all health trackers
  Map<String, HealthTracker> get allHealthTrackers =>
      Map.unmodifiable(_healthTrackers);

  /// Gets recent health change events
  List<HealthChangeEvent> get recentEvents => List.unmodifiable(_recentEvents);

  /// Gets recent events for a specific character
  List<HealthChangeEvent> getEventsForCharacter(String characterId) {
    return _recentEvents
        .where((event) => event.characterId == characterId)
        .toList();
  }

  /// Clears all health tracking data
  void clearAll() {
    _healthTrackers.clear();
    _recentEvents.clear();
  }

  /// Removes tracking for a specific character
  void removeCharacter(String characterId) {
    _healthTrackers.remove(characterId);
    _recentEvents.removeWhere((event) => event.characterId == characterId);
  }

  /// Gets or creates a health tracker for a character
  HealthTracker _getOrCreateTracker(Character character) {
    return _healthTrackers.putIfAbsent(
      character.id,
      () => HealthTracker(
        characterId: character.id,
        maxHealth: character.maxHealth,
        currentHealth: character.health,
      ),
    );
  }

  /// Adds a health change event to the recent events list
  void _addEvent(HealthChangeEvent event) {
    _recentEvents.add(event);

    // Keep only the most recent events
    if (_recentEvents.length > maxRecentEvents) {
      _recentEvents.removeAt(0);
    }
  }

  /// Handles when a character is defeated
  void _handleCharacterDefeated(Character character) {
    if (character is AllyCharacter) {
      // Ally becomes satisfied when defeated
      // This is already handled in AllyCharacter.takeDamage()
    } else if (character is EnemyCharacter) {
      // Enemy becomes satisfied when defeated
      character.setSatisfied();
    }

    // Create defeat event
    final event = HealthChangeEvent(
      characterId: character.id,
      changeType: HealthChangeType.defeated,
      amount: 0,
      previousHealth: 0,
      newHealth: 0,
      timestamp: DateTime.now(),
    );

    _addEvent(event);
  }

  /// Gets health statistics for a character
  HealthStats? getHealthStats(String characterId) {
    final tracker = _healthTrackers[characterId];
    if (tracker == null) return null;

    return HealthStats(
      characterId: characterId,
      maxHealth: tracker.maxHealth,
      currentHealth: tracker.currentHealth,
      totalDamageTaken: tracker.totalDamageTaken,
      totalHealingReceived: tracker.totalHealingReceived,
      damageEvents: tracker.damageEvents,
      healingEvents: tracker.healingEvents,
      isAlive: tracker.currentHealth > 0,
    );
  }
}

/// Tracks health changes for a specific character
class HealthTracker {
  final String characterId;
  final int maxHealth;
  int currentHealth;
  int totalDamageTaken = 0;
  int totalHealingReceived = 0;
  int damageEvents = 0;
  int healingEvents = 0;
  DateTime lastUpdate = DateTime.now();

  HealthTracker({
    required this.characterId,
    required this.maxHealth,
    required this.currentHealth,
  });

  /// Records damage taken
  void recordDamage(int damage) {
    totalDamageTaken += damage;
    currentHealth = (currentHealth - damage).clamp(0, maxHealth);
    damageEvents++;
    lastUpdate = DateTime.now();
  }

  /// Records healing received
  void recordHealing(int healing) {
    totalHealingReceived += healing;
    currentHealth = (currentHealth + healing).clamp(0, maxHealth);
    healingEvents++;
    lastUpdate = DateTime.now();
  }

  /// Gets the health percentage (0.0 to 1.0)
  double get healthPercentage => currentHealth / maxHealth;

  /// Returns true if the character is alive
  bool get isAlive => currentHealth > 0;

  /// Returns true if the character is at full health
  bool get isFullHealth => currentHealth >= maxHealth;

  /// Gets the net health change (healing - damage)
  int get netHealthChange => totalHealingReceived - totalDamageTaken;

  @override
  String toString() {
    return 'HealthTracker($characterId: $currentHealth/$maxHealth, '
        'Damage: $totalDamageTaken, Healing: $totalHealingReceived)';
  }
}

/// Represents a health change event
class HealthChangeEvent {
  final String characterId;
  final HealthChangeType changeType;
  final int amount;
  final int previousHealth;
  final int newHealth;
  final DateTime timestamp;

  HealthChangeEvent({
    required this.characterId,
    required this.changeType,
    required this.amount,
    required this.previousHealth,
    required this.newHealth,
    required this.timestamp,
  });

  /// Gets a description of the health change
  String get description {
    switch (changeType) {
      case HealthChangeType.damage:
        return '$characterId took $amount damage ($previousHealth → $newHealth)';
      case HealthChangeType.healing:
        return '$characterId healed $amount health ($previousHealth → $newHealth)';
      case HealthChangeType.defeated:
        return '$characterId was defeated';
    }
  }

  /// Returns true if this event represents a critical health change
  bool get isCritical {
    return changeType == HealthChangeType.defeated ||
        (changeType == HealthChangeType.damage && newHealth <= 10);
  }

  @override
  String toString() => description;
}

/// Types of health changes
enum HealthChangeType { damage, healing, defeated }

/// Health statistics for a character
class HealthStats {
  final String characterId;
  final int maxHealth;
  final int currentHealth;
  final int totalDamageTaken;
  final int totalHealingReceived;
  final int damageEvents;
  final int healingEvents;
  final bool isAlive;

  HealthStats({
    required this.characterId,
    required this.maxHealth,
    required this.currentHealth,
    required this.totalDamageTaken,
    required this.totalHealingReceived,
    required this.damageEvents,
    required this.healingEvents,
    required this.isAlive,
  });

  /// Gets the health percentage (0.0 to 1.0)
  double get healthPercentage => currentHealth / maxHealth;

  /// Gets the average damage per event
  double get averageDamagePerEvent =>
      damageEvents > 0 ? totalDamageTaken / damageEvents : 0.0;

  /// Gets the average healing per event
  double get averageHealingPerEvent =>
      healingEvents > 0 ? totalHealingReceived / healingEvents : 0.0;

  /// Gets the net health change
  int get netHealthChange => totalHealingReceived - totalDamageTaken;

  @override
  String toString() {
    return 'HealthStats($characterId: $currentHealth/$maxHealth, '
        'Events: ${damageEvents}D/${healingEvents}H, '
        'Total: ${totalDamageTaken}D/${totalHealingReceived}H)';
  }
}
