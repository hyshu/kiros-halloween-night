import 'package:flutter/material.dart';
import '../core/dialogue_manager.dart';
import '../core/dialogue_event.dart';

/// UI widget that displays dialogue events from the dialogue manager
class DialogueUI extends StatefulWidget {
  final DialogueManager dialogueManager;

  const DialogueUI({
    super.key,
    required this.dialogueManager,
  });

  @override
  State<DialogueUI> createState() => _DialogueUIState();
}

class _DialogueUIState extends State<DialogueUI>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isVisible = false;
  String _currentText = '';
  DialogueType? _currentType;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Set up dialogue manager callbacks
    widget.dialogueManager.initialize(
      onShow: _onShowDialogue,
      onHide: _onHideDialogue,
      onAdvance: _onAdvanceDialogue,
      onDismiss: _onDismissDialogue,
    );

    // Update UI state when dialogue manager changes
    _updateDialogueState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onShowDialogue() {
    _updateDialogueState();
    if (widget.dialogueManager.isDialogueActive && !_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();
    }
  }

  void _onHideDialogue() {
    if (_isVisible) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  void _onAdvanceDialogue() {
    // Let the dialogue manager handle advancing
    _updateDialogueState();
  }

  void _onDismissDialogue() {
    _onHideDialogue();
  }

  void _updateDialogueState() {
    if (mounted) {
      setState(() {
        _currentText = widget.dialogueManager.getCurrentDialogueText();
        _currentType = widget.dialogueManager.getCurrentDialogueType();
        
        // Show dialogue if it's active but not currently visible
        if (widget.dialogueManager.isDialogueActive && !_isVisible) {
          _isVisible = true;
          _animationController.forward();
        }
        // Hide dialogue if it's not active but currently visible
        else if (!widget.dialogueManager.isDialogueActive && _isVisible) {
          _onHideDialogue();
        }
      });
    }
  }

  Color _getDialogueColor() {
    return Colors.purple.shade800;
  }

  IconData _getDialogueIcon() {
    switch (_currentType) {
      case DialogueType.interaction:
        return Icons.chat_bubble;
      case DialogueType.itemCollection:
        return Icons.inventory;
      case DialogueType.combat:
        return Icons.gps_fixed;
      case DialogueType.story:
        return Icons.auto_stories;
      case DialogueType.boss:
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update dialogue state on each build to stay synchronized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.dialogueManager.update();
      _updateDialogueState();
    });

    if (!_isVisible || _currentText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: _getDialogueColor(),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 80,
                maxHeight: 200,
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getDialogueIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (widget.dialogueManager.canAdvanceDialogue())
                              TextButton(
                                onPressed: () {
                                  widget.dialogueManager.advanceDialogue();
                                  _updateDialogueState();
                                },
                                child: const Text(
                                  'Next',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            if (widget.dialogueManager.canDismissDialogue())
                              TextButton(
                                onPressed: () {
                                  widget.dialogueManager.dismissDialogue();
                                  _updateDialogueState();
                                },
                                child: const Text(
                                  'Close',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}