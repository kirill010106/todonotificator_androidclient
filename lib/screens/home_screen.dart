import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/navigation_state.dart';
import '../ui/theme/app_colors.dart';
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
  bool _didAttach = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAttach) {
      _didAttach = true;
      _navigation = AppScope.of(context).navigation;
      _index = _navigation?.tabIndex ?? 0;
      _navigation?.addListener(_handleNavigation);
    }
  }

  @override
  void dispose() {
    _navigation?.removeListener(_handleNavigation);
    super.dispose();
  }

  void _handleNavigation() {
    if (!mounted) {
      return;
    }
    final nextIndex = _navigation?.tabIndex ?? 0;
    if (nextIndex == _index) {
      return;
    }
    setState(() {
      _index = nextIndex;
    });
    if (_index == 0) {
      _tasksKey.currentState?.reloadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: IndexedStack(
        index: _index,
        children: [
          TasksTab(key: _tasksKey),
          const TimerTab(),
          const ProfileTab(),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () => _tasksKey.currentState?.openAddTask(),
              backgroundColor: const Color(0xFF7FE2C0),
              foregroundColor: const Color(0xFF1C4D3F),
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
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
