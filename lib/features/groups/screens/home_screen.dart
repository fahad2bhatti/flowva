import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/skeleton_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/group_controller.dart';
import '../../../data/models/group_model.dart';
import '../../tasks/controllers/task_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowva/shared/widgets/bottom_nav_bar.dart';
import '../../profile/screens/profile_screen.dart';
import 'package:flowva/features/ai/screens/ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _taskFilter = 'All';

  // FAB animation
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  // Hero section entrance animation
  late AnimationController _heroController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  // Stats counter animation
  late AnimationController _statsController;

  // AI banner pulse
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // FAB
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    );

    // Hero entrance
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic));

    // Stats
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // AI pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Start animations staggered
    _fabController.forward();
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _statsController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    _heroController.dispose();
    _statsController.dispose();
    _pulseController.dispose();
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
      case 3:
        return StreamBuilder<List<GroupModel>>(
          stream: GroupController.instance.getUserGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }
            final groups = snapshot.data ?? [];
            if (groups.isEmpty) {
              return const Center(
                child: Text(
                  'Join a group to use AI Assistant',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return AIAssistantScreen(group: groups.first);
          },
        );
      case 4:
        return const ProfileScreen();
      default: return _buildHomeTab();
    }
  }

  // ─────────────────────────────────────────────
  // Home Tab — REDESIGNED
  // ─────────────────────────────────────────────

  Widget _buildHomeTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeroHeader()),
        SliverToBoxAdapter(child: _buildStatsRow()),
        SliverToBoxAdapter(child: _buildSearchBar()),
        SliverToBoxAdapter(child: _buildQuickActions()),
        SliverToBoxAdapter(child: _buildGroupsHeader()),
        SliverToBoxAdapter(child: _buildGroupsList()),
        SliverToBoxAdapter(child: _buildAiBanner()),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }

  // ── Hero Header ──────────────────────────────
  Widget _buildHeroHeader() {
    final user = AuthController.instance.getCurrentUser();
    final displayName = user?.displayName ?? 'Flowva User';
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'F';

    return SlideTransition(
      position: _heroSlide,
      child: FadeTransition(
        opacity: _heroFade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting().toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Chat icon
              _IconBtn(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () => context.push('/dm'),
                hasBadge: false,
              ),
              const SizedBox(width: 8),
              // Notification icon
              _IconBtn(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
                hasBadge: true,
              ),
              const SizedBox(width: 8),
              // Avatar
              GestureDetector(
                onTap: () => context.push('/profile'),
                onLongPress: _showLogoutDialog,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats Row ────────────────────────────────
  Widget _buildStatsRow() {
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, child) {
        final v = _statsController.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - v)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: StreamBuilder<List<GroupModel>>(
          stream: GroupController.instance.getUserGroups(),
          builder: (ctx, snap) {
            final groupCount = snap.data?.length ?? 0;
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: TaskController.instance.getMyTasks(),
              builder: (ctx, taskSnap) {
                final tasks = taskSnap.data ?? [];
                final pendingCount = tasks.where((t) => t['status'] != 'done').length;
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0E1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1A1A2E)),
                  ),
                  child: Row(
                    children: [
                      _StatCell(
                        value: '$groupCount',
                        label: 'GROUPS',
                        valueColor: AppColors.accent,
                        isFirst: true,
                      ),
                      _StatCell(
                        value: taskSnap.connectionState == ConnectionState.waiting ? '—' : '$pendingCount',
                        label: 'TASKS',
                        valueColor: AppColors.textPrimary,
                      ),
                      _StatCell(
                        value: '—',
                        label: 'UNREAD',
                        valueColor: const Color(0xFF8B5CF6),
                        isLast: true,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── Search Bar ───────────────────────────────
  Widget _buildSearchBar() {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: _GlassSearchBar(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          onClear: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
            });
          },
        ),
      ),
    );
  }

  // ── Quick Actions ────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.add_circle_outline_rounded,  'label': 'New Group'},
      {'icon': Icons.check_box_outlined,           'label': 'Add Task' },
      {'icon': Icons.auto_awesome_outlined,        'label': 'Ask AI'   },
      {'icon': Icons.person_add_outlined,          'label': 'Invite'   },
    ];

    return _FadeSlideIn(
      delay: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 1.8,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(actions.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    child: _QuickActionTile(
                      icon : actions[i]['icon']  as IconData,
                      label: actions[i]['label'] as String,
                      onTap: () {
                        if (i == 0) _showAddGroupSheet();
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Groups Header ────────────────────────────
  Widget _buildGroupsHeader() {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 350),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MY GROUPS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 1.8,
                fontFamily: 'Inter',
              ),
            ),
            StreamBuilder<List<GroupModel>>(
              stream: GroupController.instance.getUserGroups(),
              builder: (ctx, snap) {
                final count = snap.data?.length ?? 0;
                return GestureDetector(
                  onTap: () {},
                  child: Text(
                    'View all ($count)',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.accent,
                      fontFamily: 'Inter',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Groups List ──────────────────────────────
  Widget _buildGroupsList() {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StreamBuilder<List<GroupModel>>(
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
                onCreateTap: () => context.push('/create-group'),
                onJoinTap: () => context.push('/join-group'),
              );
            }

            // Show max 3 in home, rest on groups page
            final preview = filtered.take(3).toList();

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A1A2E)),
              ),
              child: Column(
                children: List.generate(preview.length, (i) {
                  return _PremiumGroupRow(
                    group : preview[i],
                    isLast: i == preview.length - 1,
                    onTap : () => context.push('/group/${preview[i].id}', extra: preview[i]),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── AI Banner ────────────────────────────────
  Widget _buildAiBanner() {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final glow = _pulseController.value * 0.15;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2 + glow),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF12101E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flowva AI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC4B0F8),
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Summarize tasks · Generate content · Ask anything',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Feed Tab
  // ─────────────────────────────────────────────

  Widget _buildFeedTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Tasks assigned to you',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: ['All', 'Pending', 'Done'].map((filter) {
              final isSelected = _taskFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontFamily: 'Inter',
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: 1,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _taskFilter = filter;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(child: _MyTasksFeed(filter: _taskFilter)),
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
          context.push('/create-group');
        },
        onJoinGroup: () {
          Navigator.pop(ctx);
          context.push('/join-group');
        },
      ),
    );
  }

  /*void _openChat() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GroupChatPickerSheet(
        onGroupSelected: (groupId, groupName) {
          Navigator.pop(ctx);
          context.push('/chat/$groupId');
        },
      ),
    );
  }*/

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Logout', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Inter')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    try {
      await AuthController.instance.logout();
      if (mounted) {
        context.go('/login');
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
                blurRadius: 16,
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
        onItemSelected: (i) {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Group Row — replaces old GroupCard in home preview
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumGroupRow extends StatefulWidget {
  final GroupModel  group;
  final bool        isLast;
  final VoidCallback onTap;

  const _PremiumGroupRow({
    required this.group,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_PremiumGroupRow> createState() => _PremiumGroupRowState();
}

class _PremiumGroupRowState extends State<_PremiumGroupRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final initial = widget.group.name.isNotEmpty
        ? widget.group.name[0].toUpperCase()
        : 'G';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF12121E).withValues(alpha: 0.8)
              : Colors.transparent,
          border: widget.isLast
              ? null
              : const Border(
            bottom: BorderSide(color: Color(0xFF1A1A2E)),
          ),
        ),
        child: Row(
          children: [
            // Icon tile
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD0D0E8),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.group.description.isNotEmpty
                        ? widget.group.description
                        : 'Tap to open group',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Cell
// ─────────────────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color  valueColor;
  final bool   isFirst;
  final bool   isLast;

  const _StatCell({
    required this.value,
    required this.label,
    required this.valueColor,
    this.isFirst = false,
    this.isLast  = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            left : isFirst ? BorderSide.none : const BorderSide(color: Color(0xFF1A1A2E)),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: valueColor,
                letterSpacing: -0.5,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action Tile
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionTile extends StatefulWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFF141428) : const Color(0xFF0E0E1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A1A2E)),
            gradient: _pressed
                ? LinearGradient(
                    colors: [
                      const Color(0xFF141428),
                      AppColors.accent.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fade + Slide In wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _FadeSlideIn extends StatefulWidget {
  final Widget   child;
  final Duration delay;

  const _FadeSlideIn({required this.child, required this.delay});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Search Bar (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;
  final VoidCallback          onClear;

  const _GlassSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

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
        decoration: InputDecoration(
          hintText: 'Search groups…',
          hintStyle: const TextStyle(
              color: AppColors.textMuted, fontSize: 14, fontFamily: 'Inter'),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 20),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon Button (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final bool         hasBadge;

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
              top: 8, right: 8,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Error / Empty States (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
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
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 16),
            const Text('Something went wrong',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary,
                    fontSize: 13, fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool         isSearching;
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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.group_add_outlined,
                color: AppColors.accent, size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No results found' : 'No groups yet',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18,
                  fontWeight: FontWeight.bold, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Create or join a group to start collaborating.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary,
                  fontSize: 13, height: 1.5, fontFamily: 'Inter'),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: _ActionBtn(label: 'Create Group',
                      icon: Icons.add_rounded, onTap: onCreateTap)),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionBtn(label: 'Join Group',
                      icon: Icons.link_rounded, onTap: onJoinTap)),
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
  final String       label;
  final IconData     icon;
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
          Text(label, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheets (unchanged logic)
// ─────────────────────────────────────────────────────────────────────────────

class _AddGroupBottomSheet extends StatelessWidget {
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;

  const _AddGroupBottomSheet({required this.onCreateGroup, required this.onJoinGroup});

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
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Text('Add a Group',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20,
                  fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          const SizedBox(height: 6),
          const Text('Start a new workspace or hop into one',
              style: TextStyle(color: AppColors.textSecondary,
                  fontSize: 13, fontFamily: 'Inter')),
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
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;

  const _SheetOption({required this.icon, required this.title,
    required this.subtitle, required this.onTap});

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
              width: 48, height: 48,
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
                      style: const TextStyle(color: AppColors.textPrimary,
                          fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.textSecondary,
                          fontSize: 12, fontFamily: 'Inter')),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Tasks Feed (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _MyTasksFeed extends StatelessWidget {
  final String filter;
  const _MyTasksFeed({required this.filter});

  Color _priorityColor(String p) {
    if (p == 'high') return AppColors.error;
    if (p == 'low')  return AppColors.success;
    return AppColors.warning;
  }

  String _priorityLabel(String p) {
    if (p == 'high') return 'High';
    if (p == 'low')  return 'Low';
    return 'Medium';
  }

  String _formatDate(dynamic val) {
    DateTime? d;
    if (val is Timestamp) d = val.toDate();
    if (val is DateTime)  d = val;
    if (d == null) return '';
    final now  = DateTime.now();
    final diff = d.difference(now);
    if (d.day == now.day && d.month == now.month) return 'Today';
    if (diff.inDays == 1)  return 'Tomorrow';
    if (diff.inDays < 0)   return 'Overdue';
    return '${d.day}/${d.month}';
  }

  Color _dateColor(dynamic val) {
    DateTime? d;
    if (val is Timestamp) d = val.toDate();
    if (val is DateTime)  d = val;
    if (d == null) return AppColors.textMuted;
    final diff = d.difference(DateTime.now());
    if (diff.inDays < 0) return AppColors.error;
    if (diff.inDays == 0) return AppColors.warning;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TaskController.instance.getMyTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (_, i) => const SkeletonPostCard(),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text(
            snapshot.error.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: AppColors.error),
          ));
        }
        final tasks = snapshot.data ?? [];
        final filteredTasks = tasks.where((t) {
          if (filter == 'Pending') return t['status'] != 'done';
          if (filter == 'Done') return t['status'] == 'done';
          return true; // 'All'
        }).toList();

        if (filteredTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.task_alt_rounded,
                      color: AppColors.accent, size: 32),
                ),
                const SizedBox(height: 16),
                Text('No ${filter.toLowerCase()} tasks',
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 6),
                const Text('Tasks in this filter will appear here',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 13, fontFamily: 'Inter'),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }
        final pending = filteredTasks.where((t) => t['status'] != 'done').toList();
        final done    = filteredTasks.where((t) => t['status'] == 'done').toList();
        final sorted  = [...pending, ...done];

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: sorted.length,
          itemBuilder: (ctx, i) => _MyTaskCard(
            task         : sorted[i],
            priorityColor: _priorityColor,
            priorityLabel: _priorityLabel,
            formatDate   : _formatDate,
            dateColor    : _dateColor,
          ),
        );
      },
    );
  }
}

class _MyTaskCard extends StatelessWidget {
  final Map<String, dynamic>  task;
  final Color  Function(String) priorityColor;
  final String Function(String) priorityLabel;
  final String Function(dynamic) formatDate;
  final Color  Function(dynamic) dateColor;

  const _MyTaskCard({
    required this.task,
    required this.priorityColor,
    required this.priorityLabel,
    required this.formatDate,
    required this.dateColor,
  });

  @override
  Widget build(BuildContext context) {
    final String title    = task['title']?.toString() ?? 'Untitled';
    final String priority = task['priority']?.toString() ?? 'medium';
    final String status   = task['status']?.toString() ?? 'todo';
    final String assigner = task['assignedByName']?.toString() ?? 'Someone';
    final bool   isDone   = status == 'done';
    final Color  pColor   = priorityColor(priority);
    final String due      = formatDate(task['dueDate']);
    final Color  dColor   = dateColor(task['dueDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.card.withValues(alpha: 0.5)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigned by $assigner',
                    style: const TextStyle(color: AppColors.textMuted,
                        fontSize: 11, fontFamily: 'Inter')),
                const SizedBox(height: 4),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter',
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(priorityLabel(priority),
                            style: TextStyle(fontSize: 10, color: pColor,
                                fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      ),
                    if (!isDone && due.isNotEmpty) const SizedBox(width: 8),
                    if (due.isNotEmpty)
                      Row(children: [
                        Icon(Icons.calendar_today_rounded, size: 10, color: dColor),
                        const SizedBox(width: 3),
                        Text(due, style: TextStyle(
                            fontSize: 11, color: dColor,
                            fontWeight: due == 'Overdue' ? FontWeight.w600 : FontWeight.normal,
                            fontFamily: 'Inter')),
                      ]),
                    const Spacer(),
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Done ✓',
                            style: TextStyle(fontSize: 10, color: AppColors.success,
                                fontWeight: FontWeight.w600, fontFamily: 'Inter')),
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

// ─────────────────────────────────────────────────────────────────────────────
// Group Chat Picker Sheet (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _GroupChatPickerSheet extends StatelessWidget {
  final void Function(String groupId, String groupName) onGroupSelected;
  const _GroupChatPickerSheet({required this.onGroupSelected});

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
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Text('Open Group Chat',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18,
                  fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          const SizedBox(height: 6),
          const Text('Select a group to open its chat',
              style: TextStyle(color: AppColors.textSecondary,
                  fontSize: 13, fontFamily: 'Inter')),
          const SizedBox(height: 20),
          StreamBuilder<List<GroupModel>>(
            stream: GroupController.instance.getUserGroups(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              final groups = snapshot.data ?? [];
              if (groups.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No groups joined yet',
                      style: TextStyle(color: AppColors.textSecondary,
                          fontFamily: 'Inter')),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final group = groups[i];
                  return GestureDetector(
                    onTap: () => onGroupSelected(group.id, group.name),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              group.name.isNotEmpty
                                  ? group.name[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(color: AppColors.accent,
                                  fontSize: 18, fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(group.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 2),
                                const Text('# general',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12, fontFamily: 'Inter')),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}