import 'package:flutter/material.dart';

import 'app_scope.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/target_select_screen.dart';
import '../ui/theme/app_colors.dart';

class AppStart extends StatefulWidget {
  const AppStart({super.key});

  @override
  State<AppStart> createState() => _AppStartState();
}

class _AppStartState extends State<AppStart> with WidgetsBindingObserver {
  // Observe app lifecycle to show/hide ongoing timer notification when minimized
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _didLoad = false;
  Future<_StartDestination>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _future = _resolve();
    }
  }

  Future<_StartDestination> _resolve() async {
    final services = AppScope.of(context);
    final user = await services.auth.getCurrentUser();
    if (user == null) {
      return _StartDestination.login;
    }
    final targetId = await services.settings.getSelectedTarget();
    if (targetId == null) {
      return _StartDestination.target;
    }
    return _StartDestination.home;
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return _buildLoading();
    }

    return FutureBuilder<_StartDestination>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoading();
        }
        final destination = snapshot.data ?? _StartDestination.login;
        switch (destination) {
          case _StartDestination.home:
            return const HomeScreen();
          case _StartDestination.target:
            return const TargetSelectScreen();
          case _StartDestination.login:
            return const LoginScreen();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final services = AppScope.of(context);
    if (state == AppLifecycleState.paused) {
      services.timer.setOngoingNotificationsEnabled(true);
    } else if (state == AppLifecycleState.resumed) {
      services.timer.setOngoingNotificationsEnabled(false);
    }
  }

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

enum _StartDestination { login, target, home }
