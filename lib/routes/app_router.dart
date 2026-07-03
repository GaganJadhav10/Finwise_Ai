import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/expenses/expense_list_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/ai/ai_advisor_screen.dart';
import '../screens/ai/voice_entry_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loggedIn = authState.value != null;
      final loading = authState.isLoading;
      final onAuthPages = [
        '/login',
        '/signup',
        '/forgot-password',
        '/onboarding',
      ].contains(state.matchedLocation);
      final onSplash = state.matchedLocation == '/splash';

      if (loading) return onSplash ? null : '/splash';
      if (!loggedIn && !onAuthPages) return '/login';
      if (loggedIn && (onAuthPages || onSplash)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
      GoRoute(
          path: '/expenses', builder: (c, s) => const ExpenseListScreen()),
      GoRoute(
        path: '/add-expense',
        builder: (c, s) => const AddExpenseScreen(),
      ),
      GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
      GoRoute(path: '/ai-advisor', builder: (c, s) => const AiAdvisorScreen()),
      GoRoute(
          path: '/voice-entry', builder: (c, s) => const VoiceEntryScreen()),
      GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    ],
  );
});
