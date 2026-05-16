import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/navigation_state.dart';
import '../app/timer_controller.dart';
import '../services/gamification_service.dart';
import '../ui/theme/app_colors.dart';
import '../ui/widgets/game_banner.dart';
import '../ui/widgets/xp_toast.dart';
import 'tabs/achievements_screen.dart';
import 'tabs/profile_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/timer_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _tasksKey = GlobalKey<TasksTabState>();
  AppNavigationState? _navigation;
  GamificationService? _gamification;
  bool _didAttach = false;
  late final PageController _pageController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAttach) {
      _didAttach = true;
      final scope = AppScope.of(context);
      _navigation = scope.navigation;
      _gamification = scope.gamification;
      _index = _navigation?.tabIndex ?? 0;
      _pageController = PageController(initialPage: _index);
      _navigation?.addListener(_handleNavigation);
      _gamification?.addListener(_handleGamification);
    }
  }

  @override
  void dispose() {
    _navigation?.removeListener(_handleNavigation);
    _gamification?.removeListener(_handleGamification);
    _pageController.dispose();
    super.dispose();
  }

  void _handleGamification() {
    if (!mounted) return;
    final g = _gamification;
    if (g == null) return;

    // We use post frame callback to ensure we are not calling show() during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 1. Show floating XP toasts
      final deltas = g.consumeXpDeltas();
      for (int i = 0; i < deltas.length; i++) {
        // Stagger toasts slightly if there are multiple
        Future.delayed(Duration(milliseconds: i * 200), () {
          if (mounted) {
            XpToast.show(context, delta: deltas[i]);
          }
        });
      }

      // 2. Show achievement unlock popup
      final pendingUnlock = g.consumePendingUnlock();
      if (pendingUnlock != null) {
        showAchievementUnlockPopup(context, pendingUnlock);
      }

      // 3. Show game banner
      final pendingBanner = g.consumePendingBanner();
      if (pendingBanner != null) {
        GameBanner.show(
          context,
          type: pendingBanner.$1,
          message: pendingBanner.$2,
        );
      }
    });
  }

  void _handleNavigation() {
    if (!mounted) return;
    final nextIndex = _navigation?.tabIndex ?? 0;
    if (nextIndex == _index) return;
    setState(() {
      _index = nextIndex;
    });
    if (_index == 0) {
      _tasksKey.currentState?.reloadTasks();
    }
    if (_pageController.hasClients &&
        _pageController.page?.round() != nextIndex) {
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = AppScope.of(context).timer;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (_index == index) return;
                setState(() {
                  _index = index;
                });
                if (_index == 0) {
                  _tasksKey.currentState?.reloadTasks();
                }
                AppScope.of(context).navigation.setTab(index);
              },
              children: [
                TasksTab(key: _tasksKey),
                const TimerTab(),
                const ProfileTab(),
              ],
            ),
          ),
          // Мини-плеер встроен в поток — не перекрывает контент
          _TimerMiniPlayerSlot(currentTabIndex: _index),
        ],
      ),
      // FAB скрывается когда мини-плеер виден, чтобы не перекрывать его
      floatingActionButton: AnimatedBuilder(
        animation: timer,
        builder: (context, _) {
          final miniPlayerVisible = timer.phase != TimerPhase.idle &&
              !timer.isMiniPlayerDismissed &&
              _index != 1;
          if (_index != 0 || miniPlayerVisible) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _tasksKey.currentState?.openAddTask(),
            backgroundColor: const Color(0xFF7FE2C0),
            foregroundColor: const Color(0xFF1C4D3F),
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) {
          AppScope.of(context).navigation.setTab(value);
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedText,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Задачи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: 'Таймер',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

/// Анимированный слот мини-плеера.
/// Раскрывается/скрывается плавно, НЕ перекрывая основной контент.
/// Свайп реализован через [GestureDetector] — без [Dismissible],
/// который крашится при пересборке из [AnimatedBuilder] каждую секунду.
class _TimerMiniPlayerSlot extends StatefulWidget {
  const _TimerMiniPlayerSlot({required this.currentTabIndex});
  final int currentTabIndex;

  @override
  State<_TimerMiniPlayerSlot> createState() => _TimerMiniPlayerSlotState();
}

class _TimerMiniPlayerSlotState extends State<_TimerMiniPlayerSlot> {
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final timer = AppScope.of(context).timer;

    return AnimatedBuilder(
      animation: timer,
      builder: (context, _) {
        final isTimerTab = widget.currentTabIndex == 1;
        final isVisible = timer.phase != TimerPhase.idle &&
            !timer.isMiniPlayerDismissed &&
            !isTimerTab;

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: isVisible
              ? _buildContent(context, timer)
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, TimerController timer) {
    final isFocus = timer.phase == TimerPhase.focus;
    final phaseName =
        timer.isPenalty ? 'Штраф' : (isFocus ? 'Фокус' : 'Отдых');
    final color = isFocus ? AppColors.primaryDark : const Color(0xFFF5B400);

    final seconds =
        timer.remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = timer.remaining.inMinutes.toString().padLeft(2, '0');
    final timeText = '$minutes:$seconds';

    return GestureDetector(
      // Только свайп — onTap убран чтобы не конфликтовать с кнопками внутри
      onHorizontalDragUpdate: (details) {
        setState(() => _dragOffset += details.delta.dx);
      },
      onHorizontalDragEnd: (details) {
        final dismiss = _dragOffset.abs() > 80 ||
            details.velocity.pixelsPerSecond.dx.abs() > 400;
        setState(() => _dragOffset = 0.0);
        if (dismiss) timer.dismissMiniPlayer();
      },
      child: Transform.translate(
        offset: Offset(_dragOffset, 0),
        child: Opacity(
          opacity: (1.0 - (_dragOffset.abs() / 200).clamp(0.0, 1.0)),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                // Левая зона (иконка + текст) — тап переводит на вкладку таймера
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    onTap: () => AppScope.of(context).navigation.setTab(1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFocus ? Icons.track_changes : Icons.coffee,
                              color: color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phaseName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedText,
                                ),
                              ),
                              Text(
                                timeText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Пауза / Продолжить — только управление таймером, без навигации
                if (timer.isRunning)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: timer.pause,
                    icon: const Icon(
                      Icons.pause,
                      color: AppColors.primaryDark,
                      size: 22,
                    ),
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: timer.resume,
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.primaryDark,
                      size: 22,
                    ),
                  ),
                // Стоп — переходит на вкладку таймера и вызывает диалог
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    AppScope.of(context).navigation.setTab(1);
                    timer.requestStop();
                  },
                  icon: const Icon(
                    Icons.stop,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
