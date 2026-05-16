import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../services/gamification_service.dart';
import '../../ui/theme/app_colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late GamificationService _gamification;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _gamification = AppScope.of(context).gamification;
      _gamification.addListener(_onUpdate);
    }
  }

  @override
  void dispose() {
    _gamification.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _gamification.achievements;
    final unlockedCount = _gamification.unlockedCount;
    final total = achievements.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.primaryDark,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Достижения',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Progress header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Разблокировано: $unlockedCount / $total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : unlockedCount / total,
                            minHeight: 6,
                            backgroundColor: Colors.white24,
                            color: const Color(0xFF7FFFD4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final a = achievements[index];
                return _AchievementCard(achievement: a);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked
              ? const Color(0xFFD0E8DC)
              : const Color(0xFFE1E6E2),
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: AppColors.primaryDark.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 36,
                    color: unlocked ? null : Colors.transparent,
                  ),
                ),
                if (!unlocked)
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 28,
                        color: Color(0xFFB0BEC5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: unlocked ? AppColors.primaryDark : AppColors.mutedText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.mutedText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (unlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F3EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '+${achievement.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Achievement unlock popup ──────────────────────────────────────────────────

/// Call this from a [StatefulWidget] that listens to [GamificationService].
/// Shows an animated non-blocking banner celebrating the newly unlocked achievement.
void showAchievementUnlockPopup(
  BuildContext context,
  Achievement achievement,
) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AchievementUnlockBanner(
      achievement: achievement,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _AchievementUnlockBanner extends StatefulWidget {
  const _AchievementUnlockBanner({required this.achievement, required this.onDone});

  final Achievement achievement;
  final VoidCallback onDone;

  @override
  State<_AchievementUnlockBanner> createState() => _AchievementUnlockBannerState();
}

class _AchievementUnlockBannerState extends State<_AchievementUnlockBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _ctrl.reverse().whenComplete(widget.onDone);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(_slideAnim),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  Text(widget.achievement.icon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Достижение открыто!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.achievement.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.achievement.xpReward > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7FFFD4).withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${widget.achievement.xpReward} XP',
                        style: const TextStyle(
                          color: Color(0xFF7FFFD4),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
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
