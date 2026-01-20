import 'package:flutter/material.dart';
import '../../services/system_controller.dart';
import '../../services/system_repository.dart';
import '../../ui/widgets/system_overlay_message.dart';
import '../../ui/widgets/page_container.dart';
import '../../data/quest_pool.dart';
import 'system_log_page.dart';

/// System Home Page - Main application page
class SystemHomePage extends StatefulWidget {
  const SystemHomePage({super.key});

  @override
  State<SystemHomePage> createState() => _SystemHomePageState();
}

class _SystemHomePageState extends State<SystemHomePage> {
  SystemController? controller;
  bool loading = true;
  String? systemMsg;
  bool systemMsgVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final repo = await SystemRepository.create();
    final ctrl = SystemController(repo);

    // Set up callbacks
    ctrl.onStateChanged = () {
      if (mounted) setState(() {});
    };

    ctrl.onSystemMessage = (msg) {
      showSystemMessage(msg);
    };

    await ctrl.initialize();

    setState(() {
      controller = ctrl;
      loading = false;
    });
  }

  void showSystemMessage(String msg) {
    setState(() {
      systemMsg = msg;
      systemMsgVisible = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => systemMsgVisible = false);
      }
    });
  }

  bool isWide(BuildContext context) => MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    if (loading || controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3EF2D4),
          ),
        ),
      );
    }

    final ctrl = controller!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MANHWA SYSTEM'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'System Log',
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SystemLogPage(controller: ctrl),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: PageContainer(
              maxWidth: 1200,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(ctrl),
                    const SizedBox(height: 24),

                    // Stats Card
                    _buildStatsCard(ctrl),
                    const SizedBox(height: 24),

                    // Daily Quests
                    _buildDailyQuests(ctrl),
                    const SizedBox(height: 24),

                    // Upgrades
                    _buildUpgrades(ctrl),
                  ],
                ),
              ),
            ),
          ),

          // System message overlay
          SystemOverlayMessage(
            message: systemMsg ?? '',
            visible: systemMsgVisible,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SystemController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MANHWA SYSTEM',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3EF2D4),
            shadows: [
              Shadow(
                color: const Color(0xFF3EF2D4).withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Level ${ctrl.level} • Streak ${ctrl.streak}🔥',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(SystemController ctrl) {
    final xpProgress = ctrl.xp / ctrl.xpToNext;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3EF2D4).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // XP Bar
          Row(
            children: [
              const Text('XP:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: xpProgress,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3EF2D4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          '${ctrl.xp} / ${ctrl.xpToNext}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Coins
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coins: ${ctrl.coins}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF2D43E),
                ),
              ),
              Text(
                'Equipped: ${ctrl.equippedTitle.name}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuests(SystemController ctrl) {
    final bundle = ctrl.dailyBundle;
    if (bundle == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DAILY QUESTS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Responsive quest layout
        isWide(context)
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.3,
                ),
                itemCount: 3,
                itemBuilder: (context, i) => _buildQuestCard(ctrl, bundle, i),
              )
            : Column(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    _buildQuestCard(ctrl, bundle, i),
                    const SizedBox(height: 12),
                  ],
                ],
              ),

        // Claim Bonus Button
        if (ctrl.allQuestsDone && !bundle.bonusClaimed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: SizedBox(
                width: isWide(context) ? 400 : double.infinity,
                child: ElevatedButton(
                  onPressed: () => ctrl.claimAllBonus(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3EF2D4),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CLAIM ALL BONUS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestCard(SystemController ctrl, bundle, int i) {
    final template = templateById(bundle.templateIds[i]);
    final completed = bundle.completed[i];

    return InkWell(
      onTap: completed ? null : () => ctrl.completeQuest(i),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: completed ? const Color(0xFF0F1419) : const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: completed
                ? const Color(0xFF10B981)
                : const Color(0xFF3EF2D4).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? const Color(0xFF10B981) : Colors.white24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: completed ? Colors.white38 : Colors.white,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: completed ? Colors.white24 : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${template.baseXp} XP',
              style: const TextStyle(
                color: Color(0xFF3EF2D4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgrades(SystemController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UPGRADES',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        _buildUpgradeRow(
          'XP Boost',
          'Level ${ctrl.xpBoostLevel}',
          '+${(ctrl.xpBoostLevel * 5)}% XP',
          ctrl.xpBoostCost(),
          ctrl.coins >= ctrl.xpBoostCost(),
          () => ctrl.buyXpBoost(),
        ),
        const SizedBox(height: 12),

        _buildUpgradeRow(
          'Coin Boost',
          'Level ${ctrl.coinBoostLevel}',
          '+${(ctrl.coinBoostLevel * 5)}% Coins',
          ctrl.coinBoostCost(),
          ctrl.coins >= ctrl.coinBoostCost(),
          () => ctrl.buyCoinBoost(),
        ),
      ],
    );
  }

  Widget _buildUpgradeRow(
    String name,
    String level,
    String effect,
    int cost,
    bool canAfford,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: canAfford ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canAfford
                ? const Color(0xFF3EF2D4).withValues(alpha: 0.3)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: canAfford ? Colors.white : Colors.white38,
                    ),
                  ),
                  Text(
                    '$level • $effect',
                    style: TextStyle(
                      fontSize: 13,
                      color: canAfford ? Colors.white54 : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: canAfford ? const Color(0xFFF2D43E) : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$cost',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canAfford ? Colors.black : Colors.white24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
