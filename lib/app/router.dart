import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_math_with_ai/app/shell.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/models/session.dart';
import 'package:speed_math_with_ai/features/coach/coach_screen.dart';
import 'package:speed_math_with_ai/features/history/history_screen.dart';
import 'package:speed_math_with_ai/features/history/session_details_screen.dart';
import 'package:speed_math_with_ai/features/home/home_screen.dart';
import 'package:speed_math_with_ai/features/home/splash_screen.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';
import 'package:speed_math_with_ai/features/practice_session/practice_session_screen.dart';
import 'package:speed_math_with_ai/features/practice_setup/practice_setup_screen.dart';
import 'package:speed_math_with_ai/features/mistakes/mistakes_screen.dart';
import 'package:speed_math_with_ai/features/report/report_screen.dart';
import 'package:speed_math_with_ai/features/results/results_screen.dart';
import 'package:speed_math_with_ai/features/settings/data_check_screen.dart';
import 'package:speed_math_with_ai/features/settings/settings_screen.dart';
import 'package:speed_math_with_ai/features/stats/stats_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/practice',
            builder: (context, state) => PracticeSetupScreen(
              initialTopic: state.extra is Topic ? state.extra as Topic : null,
            ),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/report',
            builder: (context, state) => const ReportScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/data-check',
            builder: (context, state) => const DataCheckScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/practice/session',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final config = state.extra as PracticeConfig;
          return PracticeSessionScreen(config: config);
        },
      ),
      GoRoute(
        path: '/results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final resultData = state.extra as PracticeResultData;
          return ResultsScreen(resultData: resultData);
        },
      ),
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final session = state.extra as Session;
          return SessionDetailsScreen(session: session);
        },
      ),
      GoRoute(
        path: '/mistakes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MistakesScreen(),
      ),
      GoRoute(
        path: '/coach',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CoachScreen(),
      ),
    ],
  );
});
