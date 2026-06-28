import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/group_model.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';

import '../features/groups/screens/home_screen.dart';
import '../features/groups/screens/create_group_screen.dart';
import '../features/groups/screens/join_group_screen.dart';
import '../features/feed/screens/group_feed_screen.dart';
import '../features/chat/screens/chat_screens.dart';

import '../features/chat/screens/group_chat_screen.dart';
import '../features/chat/screens/dm_screen.dart';           // ← ADDED
import '../features/chat/screens/dm_list_screen.dart';      // ← ADDED

import '../features/search/screens/search_screen.dart';

import '../features/tasks/screens/tasks_screen.dart';

import '../features/members/screens/group_members_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/complete_profile_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/ai/screens/ai_assistant_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';

import '../core/constants/app_colors.dart';

import '../../main.dart' show navigatorKey;

// ── GoRouter refresh helper ───────────────────────────────────────────────────
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

// ── 404 Screen ────────────────────────────────────────────────────────────────
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
            Text('Page not found',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24)),
            SizedBox(height: 12),
            Text('The requested route does not exist.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Transition helpers ────────────────────────────────────────────────────────
CustomTransitionPage<void> _fadeTransition(
    BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slideTransition(
    BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, _, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(
          position: animation.drive(tween), child: child);
    },
  );
}

// ── Router ────────────────────────────────────────────────────────────────────
final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/splash',
  refreshListenable:
  GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final loggedIn  = FirebaseAuth.instance.currentUser != null;
    final loggingIn = state.matchedLocation.startsWith('/auth');
    final isSplash  = state.matchedLocation == '/splash';

    if (isSplash) return null;
    if (!loggedIn && !loggingIn) return '/auth/login';
    if (loggedIn && state.matchedLocation == '/auth/login') return '/home';
    return null;
  },
  routes: [
    // ── Splash ───────────────────────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      pageBuilder: (c, s) => _fadeTransition(c, s, const SplashScreen()),
    ),

    // ── Auth ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/auth/login',
      pageBuilder: (c, s) => _fadeTransition(c, s, const LoginScreen()),
    ),
    GoRoute(
      path: '/auth/signup',
      pageBuilder: (c, s) => _fadeTransition(c, s, const SignupScreen()),
    ),
    GoRoute(
      path: '/auth/forgot-password',
      pageBuilder: (c, s) =>
          _fadeTransition(c, s, const ForgotPasswordScreen()),
    ),

    // ── Home ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/home',
      pageBuilder: (c, s) => _slideTransition(c, s, const HomeScreen()),
    ),

    // ── Legacy/Alias Auth ─────────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      pageBuilder: (c, s) => _fadeTransition(c, s, const LoginScreen()),
    ),

    // ── Group Action Routes ────────────────────────────────────────────────────
    GoRoute(
      path: '/create-group',
      pageBuilder: (c, s) => _slideTransition(c, s, const CreateGroupScreen()),
    ),
    GoRoute(
      path: '/join-group',
      pageBuilder: (c, s) => _slideTransition(c, s, const JoinGroupScreen()),
    ),
    GoRoute(
      path: '/group/:groupId',
      pageBuilder: (c, s) {
        final group = s.extra as GroupModel?;
        if (group != null) {
          return _slideTransition(c, s, GroupFeedScreen(group: group));
        }
        return _slideTransition(
          c, s,
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('groups')
                .doc(s.pathParameters['groupId'])
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Group not found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return GroupFeedScreen(
                group: GroupModel.fromFirestore(snapshot.data!),
              );
            },
          ),
        );
      },
    ),

    // ── Chat Routes ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/chat/:groupId',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        ChatScreen(
          groupId: s.pathParameters['groupId']!,
          channelName: 'general',
        ),
      ),
    ),

    // ── Group routes ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/group/:groupId/feed',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        const Scaffold(body: Center(child: Text('Group Feed'))),
      ),
    ),
    GoRoute(
      path: '/groups/:groupId/feed',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        const Scaffold(body: Center(child: Text('Group Feed'))),
      ),
    ),
    GoRoute(
      path: '/groups/:groupId/feed/:postId',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        const Scaffold(body: Center(child: Text('Post Detail'))),
      ),
    ),
    GoRoute(
      path: '/group/:groupId/chat',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        GroupChatScreen(groupId: s.pathParameters['groupId']!),
      ),
    ),
    GoRoute(
      path: '/chat/:groupId/:channel',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        GroupChatScreen(groupId: s.pathParameters['groupId']!),
      ),
    ),
    GoRoute(
      path: '/group/:groupId/tasks',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        TasksScreen(groupId: s.pathParameters['groupId']!),
      ),
    ),
    GoRoute(
      path: '/groups/:groupId',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        TasksScreen(groupId: s.pathParameters['groupId']!),
      ),
    ),
    GoRoute(
      path: '/groups/:groupId/tasks/:taskId',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        TasksScreen(groupId: s.pathParameters['groupId']!),
      ),
    ),
    GoRoute(
      path: '/group/:groupId/members',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        GroupMembersScreen(groupId: s.pathParameters['groupId']!),
      ),
    ),

    // ── Profile ───────────────────────────────────────────────────────────────
    GoRoute(
      path: '/profile',
      pageBuilder: (c, s) => _slideTransition(c, s, const ProfileScreen()),
    ),
    GoRoute(
      path: '/profile/:userId',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        ProfileScreen(userId: s.pathParameters['userId']),
      ),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (c, s) => _slideTransition(c, s, const SearchScreen()),
    ),
    GoRoute(
      path: '/profile/edit',
      pageBuilder: (c, s) =>
          _slideTransition(c, s, const EditProfileScreen()),
    ),
    GoRoute(
      path: '/profile/complete',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        CompleteProfileScreen(
          name: FirebaseAuth.instance.currentUser?.displayName ?? '',
        ),
      ),
    ),

    // ── Notifications ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/notifications',
      pageBuilder: (c, s) =>
          _slideTransition(c, s, const NotificationsScreen()),
    ),

    // ── AI ────────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/ai',
      pageBuilder: (c, s) =>
          _slideTransition(c, s, const AIAssistantScreen()),
    ),

    // ── Dashboard ─────────────────────────────────────────────────────────────
    GoRoute(
      path: '/dashboard/:groupId',
      pageBuilder: (c, s) => _slideTransition(
        c, s,
        DashboardScreen(groupId: s.pathParameters['groupId']!),
      ),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (c, s) =>
          _slideTransition(c, s, const DashboardScreen(groupId: '')),
    ),

    // ── DM routes ─────────────────────────────────────────────────────────────
    GoRoute(
      path: '/dm',
      pageBuilder: (c, s) => _slideTransition(c, s, const DmListScreen()),
    ),
    GoRoute(
      path: '/dm/:otherUserId',
      pageBuilder: (c, s) {
        final extra = s.extra as Map<String, dynamic>? ?? {};
        return _slideTransition(
          c, s,
          DMScreen(
            otherUserId: s.pathParameters['otherUserId']!,
            otherUserName: extra['otherUserName'] as String? ?? 'User',
            otherUserPhoto: extra['otherUserPhoto'] as String? ?? "",
          ),
        );
      },
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);