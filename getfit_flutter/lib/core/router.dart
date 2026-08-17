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
import '../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull ?? false;
      final onAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/onboarding';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/run-tracker', builder: (_, __) => const RunTrackerScreen()),
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
