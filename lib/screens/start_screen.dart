import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StartScreen extends StatefulWidget {
  final VoidCallback onStartGame;
  final VoidCallback onExit;

  const StartScreen({
    super.key,
    required this.onStartGame,
    required this.onExit,
  });

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1A0D2E), // Deep purple center
              Color(0xFF0F0515), // Very dark purple
              Color(0xFF0A0A0A), // Near black
            ],
          ),
        ),
        child: Stack(
          children: [
            // Floating ghost particles background effect
            ...List.generate(12, (index) => _buildFloatingParticle(index)),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Game title with glow effect
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "👻 KIRO'S",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.deepPurple.withOpacity(
                                          0.8,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "HALLOWEEN NIGHT",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade300,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.orange.withOpacity(0.6),
                                        blurRadius: 8,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "🎃 Roguelike Ghost Quest 🎃",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.purple.shade200,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 80),

                    // Menu buttons
                    Column(
                      children: [
                        _buildMenuButton(
                          label: "🚀 Start Game",
                          onPressed: widget.onStartGame,
                          primary: true,
                        ),
                        const SizedBox(height: 30),
                        _buildMenuButton(
                          label: "🚪 Exit",
                          onPressed: widget.onExit,
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "🎯 Guide Kiro through a vast 100x200 world",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "🍭 Collect candy, befriend enemies, defeat the boss!",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = (index * 37) % 100 / 100.0; // Pseudo-random based on index
    final delay = Duration(milliseconds: (random * 3000).toInt());
    final duration = Duration(seconds: 4 + (random * 4).toInt());

    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: -100, end: MediaQuery.of(context).size.height + 100),
      builder: (context, value, child) {
        return Positioned(
          left: 50 + (random * (MediaQuery.of(context).size.width - 100)),
          top: value,
          child: Opacity(
            opacity: 0.1 + (random * 0.3),
            child: Text(
              ['👻', '🎃', '🍭', '⭐'][index % 4],
              style: TextStyle(fontSize: 20 + (random * 15)),
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation after a delay
        Future.delayed(delay, () {
          if (mounted) {
            setState(() {});
          }
        });
      },
    );
  }

  Widget _buildMenuButton({
    required String label,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    return Container(
      width: 280,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: primary
            ? LinearGradient(
                colors: [Colors.deepPurple.shade600, Colors.purple.shade500],
              )
            : LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade700],
              ),
        boxShadow: [
          BoxShadow(
            color: primary
                ? Colors.deepPurple.withOpacity(0.4)
                : Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
