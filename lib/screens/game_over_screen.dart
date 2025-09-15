import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameOverScreen extends StatefulWidget {
  final bool isVictory;
  final int candyCollected;
  final int enemiesDefeated;
  final int candiesGiven;
  final Duration survivalTime;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const GameOverScreen({
    super.key,
    required this.isVictory,
    required this.candyCollected,
    required this.enemiesDefeated,
    required this.candiesGiven,
    required this.survivalTime,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _statsController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOutBack),
    );

    _playAnimations();
  }

  void _playAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _statsController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: widget.isVictory
                ? [
                    const Color(0xFF2E1065), // Victory purple
                    const Color(0xFF1E0B38),
                    const Color(0xFF0A0A0A),
                  ]
                : [
                    const Color(0xFF4A1B1B), // Defeat red
                    const Color(0xFF2D0B0B),
                    const Color(0xFF0A0A0A),
                  ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Game Over Title
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildGameOverTitle(),
                    ),

                    const SizedBox(height: 40),

                    // Statistics
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(_statsAnimation),
                      child: FadeTransition(
                        opacity: _statsAnimation,
                        child: _buildStatistics(),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Action Buttons
                    FadeTransition(
                      opacity: _statsAnimation,
                      child: _buildActionButtons(),
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

  Widget _buildGameOverTitle() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.isVictory
                ? Colors.purple.withValues(alpha: 0.4)
                : Colors.red.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.isVictory ? "🏆 VICTORY! 🏆" : "💀 GAME OVER 💀",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: widget.isVictory
                      ? Colors.purple.withValues(alpha: 0.8)
                      : Colors.red.withValues(alpha: 0.8),
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.isVictory
                ? "🎃 Kiro defeated the boss and saved Halloween! 🎃"
                : "👻 Kiro's adventure has come to an end... 👻",
            style: TextStyle(
              fontSize: 16,
              color: widget.isVictory
                  ? Colors.orange.shade300
                  : Colors.red.shade300,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isVictory
              ? Colors.purple.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            "🎯 Adventure Statistics",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: "🍭",
                  label: "Candy Collected",
                  value: widget.candyCollected.toString(),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  icon: "🎁",
                  label: "Candies Given",
                  value: widget.candiesGiven.toString(),
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  icon: "⚔️",
                  label: "Enemies Defeated",
                  value: widget.enemiesDefeated.toString(),
                  color: Colors.red,
                ),
              ),
            ],
          ),

          if (widget.isVictory) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "🌟 Perfect Victory! Halloween is saved! 🌟",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: fullWidth ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          label: "🆕 New Game",
          onPressed: widget.onRestart,
          primary: true,
        ),
        const SizedBox(height: 15),
        _buildActionButton(label: "🏠 Main Menu", onPressed: widget.onMainMenu),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    return Container(
      width: 250,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: primary
            ? LinearGradient(
                colors: [
                  widget.isVictory
                      ? Colors.deepPurple.shade600
                      : Colors.red.shade600,
                  widget.isVictory
                      ? Colors.purple.shade500
                      : Colors.red.shade500,
                ],
              )
            : LinearGradient(
                colors: [Colors.grey.shade700, Colors.grey.shade600],
              ),
        boxShadow: [
          BoxShadow(
            color: primary
                ? (widget.isVictory
                      ? Colors.deepPurple.withValues(alpha: 0.4)
                      : Colors.red.withValues(alpha: 0.4))
                : Colors.black.withValues(alpha: 0.3),
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
              style: const TextStyle(
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
