import 'package:flutter/foundation.dart';
import 'character.dart';
import 'position.dart';

/// Represents the different phases of the game
enum GamePhase {
  /// Game is initializing
  initializing,

  /// Player is exploring the world
  exploration,

  /// Combat is taking place
  combat,

  /// Dialogue is being displayed
  dialogue,

  /// Boss battle is active
  bossBattle,

  /// Game has been completed
  victory,

  /// Game has ended in defeat
  gameOver,

  /// Game is paused
  paused,
}

/// Manages the overall state of the game
class GameState extends ChangeNotifier {
  /// Current phase of the game
  GamePhase _currentPhase = GamePhase.initializing;

  /// All characters currently in the game
  final Map<String, Character> _characters = {};

  /// The player character (Kiro the ghost)
  Character? _playerCharacter;

  /// Whether the game is currently running
  bool _isRunning = false;

  /// Current turn number (for turn-based mechanics)
  int _turnNumber = 0;

  /// Game start time
  DateTime? _gameStartTime;

  /// Gets the current game phase
  GamePhase get currentPhase => _currentPhase;

  /// Gets all characters in the game
  Map<String, Character> get characters => Map.unmodifiable(_characters);

  /// Gets the player character
  Character? get playerCharacter => _playerCharacter;

  /// Gets whether the game is running
  bool get isRunning => _isRunning;

  /// Gets the current turn number
  int get turnNumber => _turnNumber;

  /// Gets the game duration (null if not started)
  Duration? get gameDuration {
    if (_gameStartTime == null) return null;
    return DateTime.now().difference(_gameStartTime!);
  }

  /// Sets the current game phase
  void setPhase(GamePhase phase) {
    if (_currentPhase != phase) {
      _currentPhase = phase;
      notifyListeners();
    }
  }

  /// Starts the game
  void startGame() {
    if (!_isRunning) {
      _isRunning = true;
      _gameStartTime = DateTime.now();
      _turnNumber = 0;
      setPhase(GamePhase.exploration);
    }
  }

  /// Pauses the game
  void pauseGame() {
    if (_isRunning && _currentPhase != GamePhase.paused) {
      setPhase(GamePhase.paused);
    }
  }

  /// Resumes the game
  void resumeGame() {
    if (_isRunning && _currentPhase == GamePhase.paused) {
      setPhase(GamePhase.exploration);
    }
  }

  /// Ends the game with victory
  void endGameWithVictory() {
    _isRunning = false;
    setPhase(GamePhase.victory);
  }

  /// Ends the game with defeat
  void endGameWithDefeat() {
    _isRunning = false;
    setPhase(GamePhase.gameOver);
  }

  /// Resets the game to initial state
  void resetGame() {
    _isRunning = false;
    _currentPhase = GamePhase.initializing;
    _characters.clear();
    _playerCharacter = null;
    _turnNumber = 0;
    _gameStartTime = null;
    notifyListeners();
  }

  /// Adds a character to the game
  void addCharacter(Character character) {
    _characters[character.id] = character;
    notifyListeners();
  }

  /// Removes a character from the game
  void removeCharacter(String characterId) {
    _characters.remove(characterId);
    if (_playerCharacter?.id == characterId) {
      _playerCharacter = null;
    }
    notifyListeners();
  }

  /// Sets the player character
  void setPlayerCharacter(Character character) {
    _playerCharacter = character;
    addCharacter(character);
  }

  /// Gets a character by ID
  Character? getCharacter(String id) {
    return _characters[id];
  }

  /// Gets all characters at a specific position
  List<Character> getCharactersAt(Position position) {
    return _characters.values
        .where((character) => character.position == position)
        .toList();
  }

  /// Gets all active characters (for performance optimization)
  List<Character> getActiveCharacters() {
    return _characters.values.where((character) => character.isActive).toList();
  }

  /// Advances to the next turn
  void nextTurn() {
    _turnNumber++;
    notifyListeners();
  }

  /// Returns true if the game can accept input
  bool get canAcceptInput {
    return _isRunning &&
        _currentPhase != GamePhase.paused &&
        _currentPhase != GamePhase.initializing;
  }

  /// Returns true if the game is in a state where characters can move
  bool get canCharactersMove {
    return canAcceptInput && _currentPhase == GamePhase.exploration;
  }

  /// Returns true if combat is active
  bool get isCombatActive => _currentPhase == GamePhase.combat;

  /// Returns true if dialogue is active
  bool get isDialogueActive => _currentPhase == GamePhase.dialogue;

  /// Returns true if boss battle is active
  bool get isBossBattleActive => _currentPhase == GamePhase.bossBattle;

  /// Returns true if the game has ended
  bool get isGameEnded =>
      _currentPhase == GamePhase.victory || _currentPhase == GamePhase.gameOver;
}
