import 'dialogue_event.dart';
import 'dialogue_window.dart';

/// Callback function type for dialogue events
typedef DialogueEventCallback = void Function(DialogueEvent event);

/// Central manager for all dialogue events and interactions in the game
class DialogueManager {
  final DialogueWindow _dialogueWindow = DialogueWindow();
  final List<DialogueEvent> _eventQueue = [];
  final Map<DialogueType, List<DialogueEventCallback>> _eventListeners = {};

  bool _isProcessingQueue = false;

  // Turn-based event tracking
  final List<String> _currentTurnEvents = [];
  int _turnsSinceLastEvent = 0;

  /// Gets the dialogue window instance
  DialogueWindow get dialogueWindow => _dialogueWindow;

  /// Whether there are pending dialogue events
  bool get hasPendingEvents => _eventQueue.isNotEmpty;

  /// Whether dialogue is currently active
  bool get isDialogueActive => _dialogueWindow.isActive;

  /// Initializes the dialogue manager with UI callbacks
  void initialize({
    DialogueCallback? onShow,
    DialogueCallback? onHide,
    DialogueCallback? onAdvance,
    DialogueCallback? onDismiss,
  }) {
    _dialogueWindow.setCallbacks(
      onShow: onShow,
      onHide: onHide,
      onAdvance: onAdvance ?? _processNextEvent,
      onDismiss: onDismiss,
    );
  }

  /// Adds a listener for specific dialogue types
  void addEventListener(DialogueType type, DialogueEventCallback callback) {
    _eventListeners.putIfAbsent(type, () => []).add(callback);
  }

  /// Removes a listener for specific dialogue types
  void removeEventListener(DialogueType type, DialogueEventCallback callback) {
    _eventListeners[type]?.remove(callback);
  }

  /// Triggers a dialogue event immediately or queues it
  void triggerDialogue(DialogueEvent event) {
    // Notify listeners
    _eventListeners[event.type]?.forEach((callback) => callback(event));

    // Add event message to current turn events
    _currentTurnEvents.add(event.message);
    _turnsSinceLastEvent = 0;

    // Display combined events
    _displayTurnEvents();
  }

  /// Convenience method for interaction dialogues
  void showInteraction(String message, {String? speakerName}) {
    triggerDialogue(
      DialogueEvent.interaction(message, speakerName: speakerName),
    );
  }

  /// Convenience method for item collection dialogues
  void showItemCollection(String message) {
    triggerDialogue(DialogueEvent.itemCollection(message));
  }

  /// Convenience method for combat feedback dialogues
  void showCombatFeedback(String message) {
    triggerDialogue(DialogueEvent.combat(message));
  }

  /// Convenience method for player attack dialogues
  void showPlayerAttack(String message) {
    triggerDialogue(DialogueEvent.playerAttack(message));
  }

  /// Convenience method for enemy attack dialogues
  void showEnemyAttack(String message) {
    triggerDialogue(DialogueEvent.enemyAttack(message));
  }

  /// Convenience method for story dialogues
  void showStory(String message, {String? speakerName}) {
    triggerDialogue(DialogueEvent.story(message, speakerName: speakerName));
  }

  /// Convenience method for boss dialogues
  void showBossDialogue(String message, {String? speakerName}) {
    triggerDialogue(DialogueEvent.boss(message, speakerName: speakerName));
  }

  /// Convenience method for boss encounter start
  void showBossEncounter(String message) {
    triggerDialogue(DialogueEvent.boss(message, speakerName: "Boss Encounter"));
  }

  /// Convenience method for boss attack messages
  void showBossAttack(String message) {
    triggerDialogue(DialogueEvent.boss(message, speakerName: "Boss Attack"));
  }

  /// Convenience method for boss phase changes
  void showBossPhaseChange(String message) {
    triggerDialogue(DialogueEvent.boss(message, speakerName: "Boss Phase"));
  }

  /// Convenience method for boss warnings
  void showBossWarning(String message) {
    triggerDialogue(DialogueEvent.boss(message, speakerName: "Warning"));
  }

  /// Convenience method for victory messages
  void showVictory(String message) {
    triggerDialogue(DialogueEvent.boss(message, speakerName: "Victory"));
  }

  /// Convenience method for candy effects against boss
  void showCandyEffect(String message) {
    triggerDialogue(DialogueEvent.itemCollection(message));
  }

  /// Processes the next event in the queue
  void _processNextEvent() {
    if (_isProcessingQueue || _eventQueue.isEmpty) return;

    _isProcessingQueue = true;

    // Small delay to prevent rapid-fire dialogue
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_eventQueue.isNotEmpty) {
        final nextEvent = _eventQueue.removeAt(0);
        _dialogueWindow.displayDialogue(nextEvent);
      }
      _isProcessingQueue = false;
    });
  }

  /// Updates the dialogue system (call this in game loop)
  void update() {
    _dialogueWindow.update();

    // Process next event if dialogue window becomes inactive
    if (!_dialogueWindow.isActive &&
        _eventQueue.isNotEmpty &&
        !_isProcessingQueue) {
      _processNextEvent();
    }
  }

  /// Called when a new turn begins (from GameLoopManager)
  void onNewTurn() {
    _turnsSinceLastEvent++;

    // Hide dialogue after 3 turns with no new events
    if (_turnsSinceLastEvent >= 3 && _dialogueWindow.isActive) {
      _currentTurnEvents.clear();
      _dialogueWindow.dismissDialogue();
    }
  }

  /// Displays all events from the current turn as a single multi-line dialogue
  void _displayTurnEvents() {
    if (_currentTurnEvents.isEmpty) return;

    final combinedMessage = _currentTurnEvents.join('\n');
    final turnEvent = DialogueEvent(
      message: combinedMessage,
      type: DialogueType.combat, // Use combat as default type
      canAdvance: false,
    );

    _dialogueWindow.displayDialogue(turnEvent);
  }

  /// Advances current dialogue
  void advanceDialogue() {
    _dialogueWindow.advanceDialogue();
  }

  /// Dismisses current dialogue
  void dismissDialogue() {
    _dialogueWindow.dismissDialogue();
  }

  /// Clears all dialogue state and queued events
  void clear() {
    _eventQueue.clear();
    _currentTurnEvents.clear();
    _dialogueWindow.clear();
    _isProcessingQueue = false;
    _turnsSinceLastEvent = 0;
  }

  /// Clears current turn events (called at the start of each new turn)
  void clearTurnEvents() {
    _currentTurnEvents.clear();
  }

  /// Gets current dialogue text for rendering
  String getCurrentDialogueText() {
    return _dialogueWindow.getDisplayText();
  }

  /// Gets current dialogue type for styling
  DialogueType? getCurrentDialogueType() {
    return _dialogueWindow.getDialogueType();
  }

  /// Checks if user can interact with current dialogue
  bool canAdvanceDialogue() {
    return _dialogueWindow.canAdvance;
  }
}
