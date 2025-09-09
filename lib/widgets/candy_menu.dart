import 'package:flutter/material.dart';
import '../core/candy_item.dart';

/// Simple custom menu for candy actions that doesn't depend on MaterialLocalizations
class CandyMenu extends StatelessWidget {
  final CandyItem candy;
  final bool canGiveToEnemies;
  final VoidCallback onEat;
  final VoidCallback onGive;
  final VoidCallback onCancel;

  const CandyMenu({
    super.key,
    required this.candy,
    required this.canGiveToEnemies,
    required this.onEat,
    required this.onGive,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate menu position - center it in the screen
    final menuWidth = 120.0;
    final menuHeight = 80.0;
    final left = (screenSize.width - menuWidth) / 2;
    final top = (screenSize.height - menuHeight) / 2;

    return GestureDetector(
      onTap: onCancel,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Semi-transparent background
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
            // Menu centered on screen
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: menuWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  border: Border.all(color: Colors.deepPurple, width: 1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(
                      icon: Icons.restaurant,
                      label: '食べる',
                      color: Colors.green,
                      enabled: true,
                      onTap: onEat,
                    ),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    _buildMenuItem(
                      icon: Icons.favorite_outline,
                      label: 'あげる',
                      color: Colors.pink,
                      enabled: canGiveToEnemies,
                      onTap: onGive,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? color : Colors.grey, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
