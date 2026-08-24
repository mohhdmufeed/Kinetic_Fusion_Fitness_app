import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth/auth_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/workouts/screens/routines_screen.dart';
import '../features/workouts/screens/workout_logger_screen.dart';
import '../features/workouts/screens/workout_history_screen.dart';
import '../features/exercises/screens/exercise_list_screen.dart';
import '../features/exercises/screens/exercise_detail_screen.dart';
import '../features/nutrition/screens/nutrition_screen.dart';
import '../features/nutrition/screens/food_diary_screen.dart';
import '../features/nutrition/screens/ingredient_search_screen.dart';
import '../features/measurements/screens/measurements_screen.dart';
import '../features/charts/charts_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/runs/screens/run_history_screen.dart';
import '../features/runs/screens/run_tracker_screen.dart';
import '../features/categories/screens/categories_hub_screen.dart';
import '../features/categories/screens/category_report_screen.dart';
import '../features/categories/screens/trainer_tips_screen.dart';
import '../features/categories/screens/trends_dashboard_screen.dart';
import '../features/live_session/screens/live_workout_screen.dart';
import '../features/wishlist/screens/wishlist_screen.dart';
import '../features/account/screens/account_screen.dart';
import '../features/account/screens/gym_admin_screen.dart';
import '../features/feedback/screens/feedback_screen.dart';
import '../features/body/screens/body_screen.dart';
import '../features/you/screens/you_screen.dart';
import '../features/explore/screens/explore_screen.dart';
import '../features/activity/screens/activity_screen.dart';
import '../features/community/screens/community_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/achievements/screens/achievements_screen.dart';
import '../features/explore/screens/trainer_discovery_screen.dart';
import '../shared/widgets/main_shell.dart';

class AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _initialized = false;
  bool _isLoggedIn = false;

  AuthRouterNotifier(this._ref) {
    _ref.listen<AsyncValue<bool>>(isLoggedInProvider, (previous, next) {
      if (next.hasValue) {
        _isLoggedIn = next.value!;
        _initialized = true;
        notifyListeners();
      }
    });
    _checkInitialAuth();
  }

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> _checkInitialAuth() async {
    final authService = _ref.read(authServiceProvider);
    _isLoggedIn = await authService.isLoggedIn();
    _initialized = true;
    notifyListeners();
  }
}

final authRouterNotifierProvider = ChangeNotifierProvider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authRouterNotifierProvider);

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      if (!authNotifier.isInitialized) {
        return '/splash';
      }

      final loggedIn = authNotifier.isLoggedIn;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthScreen = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/onboarding';

      if (!loggedIn && !isAuthScreen) {
        return '/login';
      }

      if (loggedIn && (isAuthScreen || isSplash)) {
        return '/dashboard';
      }

      if (!loggedIn && isSplash) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const Scaffold(
          backgroundColor: Color(0xFF0D1117),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
          ),
        ),
      ),
      // Auth routes
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/run-tracker', builder: (_, __) => const RunTrackerScreen()),
      GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const GymAdminScreen()),
      GoRoute(path: '/feedback', builder: (_, __) => const FeedbackScreen()),
      GoRoute(
        path: '/live-session/:type',
        builder: (_, state) => LiveWorkoutScreen(
          activityType: state.pathParameters['type'] ?? 'running',
          wishlistId: int.tryParse(state.uri.queryParameters['wishlistId'] ?? ''),
        ),
      ),
      GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
      GoRoute(
        path: '/categories/report/:type',
        builder: (_, state) => CategoryReportScreen(
          activityType: state.pathParameters['type'] ?? 'running',
        ),
      ),
      GoRoute(path: '/categories/tips', builder: (_, __) => const TrainerTipsScreen()),
      GoRoute(path: '/categories/trends', builder: (_, __) => const TrendsDashboardScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
          GoRoute(path: '/activity', builder: (_, __) => const ActivityScreen()),
          GoRoute(path: '/community', builder: (_, __) => const CommunityScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/achievements', builder: (_, __) => const AchievementsScreen()),
          GoRoute(path: '/trainers', builder: (_, __) => const TrainerDiscoveryScreen()),
          GoRoute(path: '/body', builder: (_, __) => const BodyScreen()),
          GoRoute(path: '/you', builder: (_, __) => const YouScreen()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesHubScreen()),
          GoRoute(
            path: '/workouts',
            builder: (_, __) => const RoutinesScreen(),
            routes: [
              GoRoute(
                path: 'log/:exerciseId',
                builder: (_, state) => WorkoutLoggerScreen(
                    exerciseId:
                        int.parse(state.pathParameters['exerciseId']!)),
              ),
              GoRoute(
                  path: 'history',
                  builder: (_, __) => const WorkoutHistoryScreen()),
            ],
          ),
          GoRoute(
            path: '/exercises',
            builder: (_, __) => const ExerciseListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ExerciseDetailScreen(
                    exerciseId: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/nutrition',
            builder: (_, __) => const NutritionScreen(),
            routes: [
              GoRoute(
                  path: 'diary',
                  builder: (_, __) => const FoodDiaryScreen()),
              GoRoute(
                  path: 'search',
                  builder: (_, __) => const IngredientSearchScreen()),
            ],
          ),
          GoRoute(
              path: '/measurements',
              builder: (_, __) => const MeasurementsScreen()),
          GoRoute(path: '/charts', builder: (_, __) => const ChartsScreen()),
          GoRoute(path: '/runs', builder: (_, __) => const RunHistoryScreen()),
          GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
