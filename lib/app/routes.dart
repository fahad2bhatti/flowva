import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens (import paths based on project structure)
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';

import '../features/groups/screens/home_screen.dart';

import '../features/chat/screens/group_chat_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';

import '../features/members/screens/group_members_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/complete_profile_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/ai/screens/ai_assistant_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';


import '../core/constants/app_colors.dart';

// Helper to listen to a Stream for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// 404 / Not Found page
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline, size: 96, color: AppColors.error),
            SizedBox(height: 24),
            Text('Page not found', style: TextStyle(color: AppColors.textPrimary, fontSize: 24)),
            SizedBox(height: 12),
            Text('The requested route does not exist.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// Transition helpers
CustomTransitionPage<void> _fadeTransition(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideTransition(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
      final offsetAnimation = animation.drive(tween);
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loggingIn = state.matchedLocation.startsWith('/auth');
    if (!loggedIn && !loggingIn) return '/auth/login';
    if (loggedIn && state.matchedLocation == '/auth/login') return '/home';
    return null;
  },
  routes: [
    // Splash
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadeTransition(context, state, const SplashScreen()),
    ),
    // Auth group
    GoRoute(
      path: '/auth/login',
      pageBuilder: (context, state) => _fadeTransition(context, state, const LoginScreen()),
    ),
    GoRoute(
      path: '/auth/signup',
      pageBuilder: (context, state) => _fadeTransition(context, state, const SignupScreen()),
    ),
    GoRoute(
      path: '/auth/forgot-password',
      pageBuilder: (context, state) => _fadeTransition(context, state, const ForgotPasswordScreen()),
    ),
    // Main app routes (slide transition)
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _slideTransition(context, state, const HomeScreen()),
    ),
    GoRoute(
      path: '/group/:groupId/feed',
      pageBuilder: (context, state) => _slideTransition(
        context,
        state,
        const Scaffold(body: Center(child: Text('Group Feed'))),
      ),
    ),
    GoRoute(
      path: '/group/:groupId/chat',
      pageBuilder: (context, state) => _slideTransition(
        context,
        state,
        GroupChatScreen(groupId: state.pathParameters['groupId']!),
      ),
    ),
    GoRoute(
      path: '/group/:groupId/tasks',
      pageBuilder: (context, state) => _slideTransition(
        context,
        state,
        TasksScreen(groupId: state.pathParameters['groupId']!),
      ),
    ),
    GoRoute(
      path: '/group/:groupId/members',
      pageBuilder: (context, state) => _slideTransition(
        context,
        state,
        GroupMembersScreen(groupId: state.pathParameters['groupId']!),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _slideTransition(context, state, const ProfileScreen()),
    ),
    GoRoute(
      path: '/profile/edit',
      pageBuilder: (context, state) => _slideTransition(context, state, const EditProfileScreen()),
    ),
    GoRoute(
      path: '/profile/complete',
      pageBuilder: (context, state) => _slideTransition(
        context,
        state,
        CompleteProfileScreen(
          name: FirebaseAuth.instance.currentUser?.displayName ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => _slideTransition(context, state, const NotificationsScreen()),
    ),
    GoRoute(
      path: '/ai',
      pageBuilder: (context, state) => _slideTransition(context, state, const AIAssistantScreen()),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => _slideTransition(context, state, const DashboardScreen(groupId: '',)),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);