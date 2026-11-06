import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/pookie_brand_mark.dart';
import '../../models/collectible_model.dart';
import '../../models/achievement_model.dart';
import '../../providers/notifications_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'LEGENDARY':
        return const Color(0xFFF59E0B);
      case 'EPIC':
        return const Color(0xFF9333EA);
      case 'RARE':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF10B981);
    }
  }

  void _inspectItem(CollectibleItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getRarityColor(item.rarity).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(item.icon, style: const TextStyle(fontSize: 42)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRarityColor(item.rarity),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.rarity.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.description.isNotEmpty
                  ? item.description
                  : 'An exclusive collectible discovered during real-world exploration on Pookie Match.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            if (item.perkDescription != null && item.perkDescription!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.coralPale,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.coral.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.coral, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.perkDescription!,
                        style: const TextStyle(fontSize: 12, color: AppColors.coralDark, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const PookieBrandMark(size: 26, fontSize: 18),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(notificationsProvider.notifier).loadInventory();
              ref.read(notificationsProvider.notifier).loadAchievements();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationsProvider.notifier).loadInventory();
          await ref.read(notificationsProvider.notifier).loadAchievements();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats Banner (matching website 3-card banner)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      emoji: '🎒',
                      label: 'COLLECTIBLES',
                      value: '${state.inventory.length}',
                      bgColor: const Color(0xFFFFF1F0),
                      borderColor: const Color(0xFFFFD9D6),
                      accentColor: AppColors.coral,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      emoji: '🏆',
                      label: 'BADGES',
                      value: '${state.achievements.where((a) => a.unlocked).length}/${state.achievements.length}',
                      bgColor: const Color(0xFFFEF3C7),
                      borderColor: const Color(0xFFFDE68A),
                      accentColor: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      emoji: '⭐',
                      label: 'SCORE',
                      value: '${state.totalPoints} pts',
                      bgColor: const Color(0xFFEDE9FE),
                      borderColor: const Color(0xFFDDD6FE),
                      accentColor: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tab Bar matching website
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4ECEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.ink,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.card_giftcard, size: 16),
                          const SizedBox(width: 6),
                          Text('Backpack Items (${state.inventory.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.military_tech, size: 16),
                          const SizedBox(width: 6),
                          Text('Badges (${state.achievements.where((a) => a.unlocked).length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab View Content
              SizedBox(
                height: 520,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInventoryGrid(state.inventory),
                    _buildAchievementsList(state.achievements),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String label,
    required String value,
    required Color bgColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid(List<CollectibleItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.coralPale,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🎒', style: TextStyle(fontSize: 34))),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Backpack is Empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Explore the Adventure Map or solve City Quests to collect rare virtual items and gifts!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final rarityColor = _getRarityColor(item.rarity);

        return InkWell(
          onTap: () => _inspectItem(item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.subtleShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rarityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.rarity.toUpperCase(),
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (item.quantity > 1)
                      Text(
                        'x${item.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(item.icon, style: const TextStyle(fontSize: 40)),
                const Spacer(),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsList(List<AchievementModel> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('No exploration badges available yet.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ach = list[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ach.unlocked ? Colors.white : const Color(0xFFF9F8F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ach.unlocked ? const Color(0xFFFDE68A) : AppColors.border),
            boxShadow: ach.unlocked ? AppColors.subtleShadow : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ach.unlocked ? const Color(0xFFFEF3C7) : const Color(0xFFE9E0E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(ach.badgeIcon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ach.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: ach.unlocked ? AppColors.ink : AppColors.textMuted,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ach.unlocked ? const Color(0xFFEAF8F2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ach.unlocked ? 'UNLOCKED' : '+${ach.points} pts',
                            style: TextStyle(
                              color: ach.unlocked ? AppColors.success : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ach.description,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

