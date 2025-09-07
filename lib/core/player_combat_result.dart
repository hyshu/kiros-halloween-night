/// Result of a player combat encounter
class PlayerCombatResult {
  /// Damage dealt by the player
  final int playerDamageDealt;

  /// Whether the enemy was defeated
  final bool enemyDefeated;

  /// Player's health after combat
  final int playerHealth;

  /// Enemy's health after combat
  final int enemyHealth;

  /// Descriptive text of what happened in combat
  final String combatDescription;

  /// Timestamp of when combat occurred
  final DateTime timestamp;

  PlayerCombatResult({
    required this.playerDamageDealt,
    required this.enemyDefeated,
    required this.playerHealth,
    required this.enemyHealth,
    required this.combatDescription,
  }) : timestamp = DateTime.now();

  /// Whether the combat was successful for the player
  bool get wasSuccessful => enemyDefeated;

  /// Whether the player took damage (for enemy counter-attacks)
  bool get playerTookDamage => false; // Will be extended for enemy counter-attacks

  @override
  String toString() {
    return 'PlayerCombat(Damage: $playerDamageDealt, Enemy Defeated: $enemyDefeated, Player HP: $playerHealth)';
  }

  /// Creates a combat result for when player kills an enemy
  factory PlayerCombatResult.victory({
    required int damageDealt,
    required int playerHealth,
    required String description,
  }) {
    return PlayerCombatResult(
      playerDamageDealt: damageDealt,
      enemyDefeated: true,
      playerHealth: playerHealth,
      enemyHealth: 0,
      combatDescription: description,
    );
  }

  /// Creates a combat result for when enemy survives
  factory PlayerCombatResult.damage({
    required int damageDealt,
    required int playerHealth,
    required int enemyHealth,
    required String description,
  }) {
    return PlayerCombatResult(
      playerDamageDealt: damageDealt,
      enemyDefeated: false,
      playerHealth: playerHealth,
      enemyHealth: enemyHealth,
      combatDescription: description,
    );
  }
}