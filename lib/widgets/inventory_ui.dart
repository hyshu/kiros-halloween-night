import 'package:flutter/material.dart';
import '../core/inventory.dart';
import '../core/candy_item.dart';
import '../l10n/strings.g.dart';

/// UI widget for displaying the player's candy inventory
class InventoryUI extends StatelessWidget {
  final Inventory inventory;
  final Function(String candyId)? onUseCandy;
  final VoidCallback? onClose;

  const InventoryUI({
    super.key,
    required this.inventory,
    this.onUseCandy,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border.all(color: Colors.deepPurple, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildStats(),
          Expanded(child: _buildCandyList()),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F23),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            t.ui.inventory,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(
                '${inventory.count}/${inventory.maxCapacity}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white70),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final activeEffects = inventory.activeEffects;
    if (activeEffects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Effects',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...activeEffects.values.map((effect) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      effect.name,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${effect.remainingDuration} turns',
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCandyList() {
    if (inventory.isEmpty) {
      return const Center(
        child: Text(
          'No candies in inventory',
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
      );
    }

    final candyGroups = _groupCandyByType();
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: candyGroups.length,
      itemBuilder: (context, index) {
        final entry = candyGroups.entries.elementAt(index);
        final candyName = entry.key;
        final candyList = entry.value;
        final candy = candyList.first;
        final count = candyList.length;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getEffectColor(candy.effect).withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getEffectColor(candy.effect).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getEffectIcon(candy.effect),
                color: _getEffectColor(candy.effect),
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    candyName,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                if (count > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              candy.description,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onUseCandy?.call(candy.id),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F23),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white60, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap an item to use it. Press I to close.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<CandyItem>> _groupCandyByType() {
    final groups = <String, List<CandyItem>>{};
    for (final candy in inventory.candyItems) {
      groups.putIfAbsent(candy.name, () => []).add(candy);
    }
    return groups;
  }

  Color _getEffectColor(CandyEffect effect) {
    switch (effect) {
      case CandyEffect.healthBoost:
        return Colors.red;
      case CandyEffect.maxHealthIncrease:
        return Colors.red.shade300;
      case CandyEffect.speedIncrease:
        return Colors.blue;
      case CandyEffect.allyStrength:
        return Colors.green;
      case CandyEffect.specialAbility:
        return Colors.purple;
      case CandyEffect.statModification:
        return Colors.amber;
    }
  }

  IconData _getEffectIcon(CandyEffect effect) {
    switch (effect) {
      case CandyEffect.healthBoost:
        return Icons.favorite;
      case CandyEffect.maxHealthIncrease:
        return Icons.favorite_border;
      case CandyEffect.speedIncrease:
        return Icons.speed;
      case CandyEffect.allyStrength:
        return Icons.group;
      case CandyEffect.specialAbility:
        return Icons.auto_awesome;
      case CandyEffect.statModification:
        return Icons.trending_up;
    }
  }
}

/// Overlay widget that shows the inventory UI
class InventoryOverlay extends StatelessWidget {
  final Inventory inventory;
  final Function(String candyId)? onUseCandy;
  final VoidCallback? onClose;

  const InventoryOverlay({
    super.key,
    required this.inventory,
    this.onUseCandy,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: InventoryUI(
          inventory: inventory,
          onUseCandy: onUseCandy,
          onClose: onClose,
        ),
      ),
    );
  }
}