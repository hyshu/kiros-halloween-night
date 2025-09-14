import 'dialogue_event.dart';

/// Callback function type for dialogue window events
typedef DialogueCallback = void Function();

/// Manages the display and interaction of dialogue windows
class DialogueWindow {
  bool _isActive = false;
  DialogueEvent? _currentEvent;
  DateTime? _displayStartTime;

  // Callbacks for user interactions
  DialogueCallback? _onAdvance;
  DialogueCallback? _onDismiss;
  DialogueCallback? _onShow;
  DialogueCallback? _onHide;

  /// Whether the dialogue window is currently active
  bool get isActive => _isActive;

  /// The current dialogue event being displayed
  DialogueEvent? get currentEvent => _currentEvent;

  /// Whether the current dialogue can be advanced
  bool get canAdvance => _currentEvent?.canAdvance ?? false;

  /// Whether the dialogue should auto-dismiss based on duration
  bool get shouldAutoDismiss {
    if (_currentEvent?.displayDuration == null || _displayStartTime == null) {
      return false;
    }

    final elapsed = DateTime.now().difference(_displayStartTime!);
    return elapsed >= _currentEvent!.displayDuration!;
  }

  /// Sets callback functions for dialogue events
  void setCallbacks({
    DialogueCallback? onAdvance,
    DialogueCallback? onDismiss,
    DialogueCallback? onShow,
    DialogueCallback? onHide,
  }) {
    _onAdvance = onAdvance;
    _onDismiss = onDismiss;
    _onShow = onShow;
    _onHide = onHide;
  }

  /// Displays a dialogue event in the window
  void displayDialogue(DialogueEvent event) {
    _currentEvent = event;
    _displayStartTime = DateTime.now();

    if (!_isActive) {
      _isActive = true;
      _onShow?.call();
    }
  }

  /// Advances to the next dialogue or dismisses if at end
  void advanceDialogue() {
    if (!canAdvance) return;

    _onAdvance?.call();
    dismissDialogue();
  }

  /// Dismisses the current dialogue window
  void dismissDialogue() {
    _currentEvent = null;
    _displayStartTime = null;

    if (_isActive) {
      _isActive = false;
      _onDismiss?.call();
      _onHide?.call();
    }
  }

  /// Updates the dialogue window state (call this in game loop)
  void update() {
    if (_isActive && shouldAutoDismiss) {
      dismissDialogue();
    }
  }

  /// Clears all dialogue state
  void clear() {
    _currentEvent = null;
    _displayStartTime = null;
    _isActive = false;
  }

  /// Gets the display text for the current dialogue
  String getDisplayText() {
    if (_currentEvent == null) return '';

    final speaker = _currentEvent!.speakerName;
    final message = _currentEvent!.message;

    if (speaker != null && speaker.isNotEmpty) {
      return '$speaker: $message';
    }

    return message;
  }

  /// Gets the dialogue type for styling purposes
  DialogueType? getDialogueType() {
    return _currentEvent?.type;
  }
}
