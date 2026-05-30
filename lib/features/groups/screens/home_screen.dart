import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/skeleton_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/login_screen.dart';
import '../controllers/group_controller.dart';
import '../../../data/models/group_model.dart';
import '../widgets/group_card.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import '../../feed/screens/group_feed_screen.dart';
import '../../tasks/controllers/task_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowva/shared/widgets/bottom_nav_bar.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Tab Bodies
  // ─────────────────────────────────────────────

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return _buildFeedTab();
      case 2: return _buildComingSoon('Tasks', Icons.check_circle_outline_rounded);
      case 3: return _buildComingSoon('AI Assistant', Icons.auto_awesome_rounded);
      case 4:
        return const ProfileScreen();
      default: return _buildHomeTab();
    }
  }

  // ─────────────────────────────────────────────
  // Home Tab
  // ─────────────────────────────────────────────

  Widget _buildHomeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AuthController.instance.getCurrentUser()?.displayName ?? 'Flowva User',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _IconBtn(icon: Icons.notifications_none_rounded, onTap: () {}, hasBadge: true),
              const SizedBox(width: 10),
              _AvatarBtn(onTap: _handleLogout),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _GlassSearchBar(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),

        const SizedBox(height: 20),

        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Groups',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  fontFamily: 'Inter',
                ),
              ),
              StreamBuilder<List<GroupModel>>(
                stream: GroupController.instance.getUserGroups(),
                builder: (ctx, snap) {
                  final count = snap.data?.length ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Groups list
        Expanded(child: _buildGroupsList()),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Feed Tab — Mujhe assign tasks
  // ─────────────────────────────────────────────

  Widget _buildFeedTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text(
            'My Tasks',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            'Tasks assigned to you',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ),

        // Tasks stream
        Expanded(child: _MyTasksFeed()),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Coming Soon
  // ─────────────────────────────────────────────

  Widget _buildComingSoon(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming Soon',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Groups List (Home tab)
  // ─────────────────────────────────────────────

  Widget _buildGroupsList() {
    return StreamBuilder<List<GroupModel>>(
      stream: GroupController.instance.getUserGroups(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString().replaceAll('Exception: ', ''),
          );
        }

        final groups = snapshot.data ?? [];
        final filtered = _searchQuery.isEmpty
            ? groups
            : groups.where((g) =>
        g.name.toLowerCase().contains(_searchQuery) ||
            g.description.toLowerCase().contains(_searchQuery)).toList();

        if (filtered.isEmpty) {
          return _EmptyState(
            isSearching: _searchQuery.isNotEmpty,
            onCreateTap: () => Navigator.push(context, _slideRoute(const CreateGroupScreen())),
            onJoinTap: () => Navigator.push(context, _slideRoute(const JoinGroupScreen())),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => GroupCard(
            group: filtered[i],
            onTap: () => Navigator.push(
              context,
              _slideRoute(GroupFeedScreen(group: filtered[i])),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showAddGroupSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddGroupBottomSheet(
        onCreateGroup: () {
          Navigator.pop(ctx);
          Navigator.push(context, _slideRoute(const CreateGroupScreen()));
        },
        onJoinGroup: () {
          Navigator.pop(ctx);
          Navigator.push(context, _slideRoute(const JoinGroupScreen()));
        },
      ),
    );
  }

  void _handleLogout() async {
    try {
      await AuthController.instance.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  PageRoute _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
      floatingActionButton: _selectedIndex == 0
          ? ScaleTransition(
        scale: _fabAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _showAddGroupSheet,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed Group Tile — Feed tab mein group select karne ke liye
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Empty Feed State
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Shared Small Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _GlassSearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 14, fontFamily: 'Inter'),
        decoration: const InputDecoration(
          hintText: 'Search groups…',
          hintStyle: TextStyle(
              color: AppColors.textMuted, fontSize: 14, fontFamily: 'Inter'),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  const _IconBtn({required this.icon, required this.onTap, this.hasBadge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          if (hasBadge)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AvatarBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final displayName =
        AuthController.instance.getCurrentUser()?.displayName ?? 'F';
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'F';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: 3,
      itemBuilder: (ctx, i) => const SkeletonGroupCard(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 16),
            const Text('Something went wrong',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onCreateTap;
  final VoidCallback onJoinTap;

  const _EmptyState({
    required this.isSearching,
    required this.onCreateTap,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.group_add_outlined,
                color: AppColors.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No results found' : 'No groups yet',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Create or join a group to start collaborating.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'Inter'),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                        label: 'Create Group',
                        icon: Icons.add_rounded,
                        onTap: onCreateTap),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionBtn(
                        label: 'Join Group',
                        icon: Icons.link_rounded,
                        onTap: onJoinTap),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

class _AddGroupBottomSheet extends StatelessWidget {
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;

  const _AddGroupBottomSheet({
    required this.onCreateGroup,
    required this.onJoinGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Text('Add a Group',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter')),
          const SizedBox(height: 6),
          const Text('Start a new workspace or hop into one',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
          const SizedBox(height: 24),
          _SheetOption(
            icon: Icons.add_circle_outline_rounded,
            title: 'Create Group',
            subtitle: 'Start a new group and invite your team',
            onTap: onCreateGroup,
          ),
          const SizedBox(height: 12),
          _SheetOption(
            icon: Icons.link_rounded,
            title: 'Join Group',
            subtitle: 'Enter an invite code to join an existing group',
            onTap: onJoinGroup,
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Tasks Feed — Feed tab mein mujhe assign tasks
// ─────────────────────────────────────────────────────────────────────────────

class _MyTasksFeed extends StatelessWidget {
  const _MyTasksFeed();

  Color _priorityColor(String p) {
    if (p == 'high') return AppColors.error;
    if (p == 'low') return AppColors.success;
    return AppColors.warning;
  }

  String _priorityLabel(String p) {
    if (p == 'high') return 'High';
    if (p == 'low') return 'Low';
    return 'Medium';
  }

  String _formatDate(dynamic val) {
    DateTime? d;
    if (val is Timestamp) d = val.toDate();
    if (val is DateTime) d = val;
    if (d == null) return '';
    final now = DateTime.now();
    final diff = d.difference(now);
    if (d.day == now.day && d.month == now.month) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 0) return 'Overdue';
    return '${d.day}/${d.month}';
  }

  Color _dateColor(dynamic val) {
    DateTime? d;
    if (val is Timestamp) d = val.toDate();
    if (val is DateTime) d = val;
    if (d == null) return AppColors.textMuted;
    final diff = d.difference(DateTime.now());
    if (diff.inDays < 0) return AppColors.error;   // overdue
    if (diff.inDays == 0) return AppColors.warning; // today
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TaskController.instance.getMyTasks(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (_, i) => const SkeletonPostCard(),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        // Empty
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.task_alt_rounded,
                      color: AppColors.accent, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No tasks assigned',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tasks assigned to you will appear here',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Inter'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Filter — pending tasks pehle, done baad mein
        final pending = tasks.where((t) => t['status'] != 'done').toList();
        final done = tasks.where((t) => t['status'] == 'done').toList();
        final sorted = [...pending, ...done];

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: sorted.length,
          itemBuilder: (ctx, i) => _MyTaskCard(
            task: sorted[i],
            priorityColor: _priorityColor,
            priorityLabel: _priorityLabel,
            formatDate: _formatDate,
            dateColor: _dateColor,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Task Card
// ─────────────────────────────────────────────────────────────────────────────

class _MyTaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final Color Function(String) priorityColor;
  final String Function(String) priorityLabel;
  final String Function(dynamic) formatDate;
  final Color Function(dynamic) dateColor;

  const _MyTaskCard({
    required this.task,
    required this.priorityColor,
    required this.priorityLabel,
    required this.formatDate,
    required this.dateColor,
  });

  @override
  Widget build(BuildContext context) {
    final String title = task['title']?.toString() ?? 'Untitled';
    final String priority = task['priority']?.toString() ?? 'medium';
    final String status = task['status']?.toString() ?? 'todo';
    final String assigner = task['assignedByName']?.toString() ?? 'Someone';
    final bool isDone = status == 'done';
    final Color pColor = priorityColor(priority);
    final String due = formatDate(task['dueDate']);
    final Color dColor = dateColor(task['dueDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.card.withValues(alpha: 0.5)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppColors.border.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.success.withValues(alpha: 0.1)
                  : pColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDone ? Icons.check_circle_rounded : Icons.flag_rounded,
              color: isDone ? AppColors.success : pColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assigned by
                Text(
                  'Assigned by $assigner',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Inter'),
                ),
                const SizedBox(height: 4),

                // Title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDone
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),

                // Priority + Due date + Status
                Row(
                  children: [
                    // Priority badge
                    if (!isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priorityLabel(priority),
                          style: TextStyle(
                              fontSize: 10,
                              color: pColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter'),
                        ),
                      ),

                    if (!isDone && due.isNotEmpty) const SizedBox(width: 8),

                    // Due date
                    if (due.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 10, color: dColor),
                          const SizedBox(width: 3),
                          Text(
                            due,
                            style: TextStyle(
                                fontSize: 11,
                                color: dColor,
                                fontWeight: due == 'Overdue'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontFamily: 'Inter'),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // Done badge
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Done ✓',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}