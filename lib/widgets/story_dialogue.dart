import 'package:flutter/material.dart';
import '../l10n/strings.g.dart';

class StoryDialogue extends StatefulWidget {
  final VoidCallback onContinue;

  const StoryDialogue({super.key, required this.onContinue});

  @override
  State<StoryDialogue> createState() => _StoryDialogueState();
}

class _StoryDialogueState extends State<StoryDialogue>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _typewriterController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _typewriterAnimation;

  late final String _storyText;

  int _currentCharIndex = 0;
  bool _isTypingComplete = false;

  @override
  void initState() {
    super.initState();

    // Initialize story text from localization
    _storyText = t.story.text;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _typewriterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typewriterController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    _typewriterController.addListener(() {
      final progress = _typewriterAnimation.value;
      final targetIndex = (progress * _storyText.length).round();

      if (targetIndex != _currentCharIndex &&
          targetIndex <= _storyText.length) {
        setState(() {
          _currentCharIndex = targetIndex;
        });
      }
    });

    _typewriterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isTypingComplete = true;
        });
      }
    });

    await _typewriterController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  void _skipToEnd() {
    if (!_isTypingComplete) {
      _typewriterController.stop();
      setState(() {
        _currentCharIndex = _storyText.length;
        _isTypingComplete = true;
      });
    } else {
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skipToEnd,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [Color(0xFF1A0D2E), Color(0xFF0F0515), Color(0xFF000000)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.deepPurple.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("👻", style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Text(
                            t.story.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.deepPurple.withValues(
                                    alpha: 0.8,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text("🎃", style: const TextStyle(fontSize: 28)),
                        ],
                      ),
                    ),

                    // Story text
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 500,
                        minHeight: 200,
                      ),
                      child: Text(
                        _storyText.substring(0, _currentCharIndex),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.6,
                          fontFamily: 'NotoSans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Continue button or hint
                    if (_isTypingComplete) ...[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade600,
                              Colors.purple.shade500,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: widget.onContinue,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    t.story.startAdventure,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Skip hint
                      AnimatedOpacity(
                        opacity: 0.7,
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          t.story.tapToSkip,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    // Typing cursor
                    if (!_isTypingComplete)
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: (value * 2) % 1,
                                child: Text(
                                  "▐",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.deepPurple.shade300,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
