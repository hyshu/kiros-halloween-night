import 'package:flutter/material.dart';

import '../core/candy_item.dart';
import '../core/gift_system.dart';

/// UI overlay for the gift system
class GiftOverlay extends StatefulWidget {
  final GiftSystem giftSystem;
  final Function() onConfirmGift;
  final Function() onCancelGift;

  const GiftOverlay({
    super.key,
    required this.giftSystem,
    required this.onConfirmGift,
    required this.onCancelGift,
  });

  @override
  State<GiftOverlay> createState() => _GiftOverlayState();
}

class _GiftOverlayState extends State<GiftOverlay> {
  @override
  Widget build(BuildContext context) {
    if (!widget.giftSystem.isGiftUIActive) {
      return const SizedBox.shrink();
    }

    final targetEnemy = widget.giftSystem.targetEnemy;
    final availableCandy = widget.giftSystem.availableCandy;
    final selectedCandy = widget.giftSystem.selectedCandy;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepPurple, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Give Candy to ${targetEnemy?.enemyType.displayName ?? "Enemy"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Enemy info
              if (targetEnemy != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        targetEnemy.id,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Health: ${targetEnemy.health}/${targetEnemy.maxHealth}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Available candy list
              Text(
                'Choose candy to give:',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: availableCandy.map((candy) {
                      final isSelected = selectedCandy?.id == candy.id;
                      final isRecommended = targetEnemy != null && 
                          widget.giftSystem.getRecommendedCandy(
                            targetEnemy, availableCandy)?.id == candy.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            widget.giftSystem.selectCandy(candy);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.deepPurple.withValues(alpha: 0.3)
                                  : const Color(0xFF0F0F1E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepPurple
                                    : isRecommended
                                        ? Colors.amber.withValues(alpha: 0.7)
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getCandyColor(candy.effect),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.cake,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        candy.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        candy.description,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isRecommended)
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: widget.onCancelGift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: selectedCandy != null ? widget.onConfirmGift : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Give Gift'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCandyColor(CandyEffect effect) {
    switch (effect) {
      case CandyEffect.healthBoost:
        return Colors.red;
      case CandyEffect.maxHealthIncrease:
        return Colors.pink;
      case CandyEffect.speedIncrease:
        return Colors.blue;
      case CandyEffect.allyStrength:
        return Colors.purple;
      case CandyEffect.specialAbility:
        return Colors.amber;
      case CandyEffect.statModification:
        return Colors.green;
    }
  }
}