import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../controllers/profile_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUid = ProfileController.instance.currentUserId ?? '';
    final uid        = userId ?? currentUid;
    final isMe       = uid == currentUid;

    return StreamBuilder<UserModel?>(
      stream: ProfileController.instance.getUserStreamById(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary),
                onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
              ),
            ),
            body: const Center(
              child: Text('User not found',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (ctx, _) => [
                _ProfileHeader(user: user, isMe: isMe),
              ],
              body: TabBarView(
                children: [
                  _AboutTab(user: user),
                  _PostsTab(userId: uid),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool      isMe;
  const _ProfileHeader({required this.user, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoverAndAvatar(user: user, isMe: isMe),
          _NameSection(user: user, isMe: isMe),
          const SizedBox(height: 16),
          _StatsRow(user: user),
          if (isMe && user.profileCompletion < 100) ...[
            const SizedBox(height: 12),
            _CompletionBar(percent: user.profileCompletion, user: user),
          ],
          if (user.currentStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            _StatusCard(status: user.currentStatus),
          ],
          if (user.skills.isNotEmpty) ...[
            const SizedBox(height: 16),
            _TagsSection(title: 'Skills', tags: user.skills),
          ],
          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: 16),
            _TagsSection(
                title: 'Interests', tags: user.interests, isAccent: true),
          ],
          if (user.badges.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BadgesSection(badges: user.badges),
          ],
          // ✅ Logout button — sirf isMe pe
          if (isMe) ...[
            const SizedBox(height: 16),
            _LogoutButton(),
          ],
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color  : AppColors.surface,
              border : Border(
                top    : BorderSide(color: AppColors.border),
                bottom : BorderSide(color: AppColors.border),
              ),
            ),
            child: const TabBar(
              labelColor          : AppColors.accent,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor      : AppColors.accent,
              indicatorWeight     : 2,
              labelStyle: TextStyle(
                  fontWeight : FontWeight.w600,
                  fontSize   : 13,
                  fontFamily : 'Inter'),
              tabs: [Tab(text: 'About'), Tab(text: 'Posts')],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(
                color      : AppColors.textPrimary,
                fontFamily : 'Inter',
                fontWeight : FontWeight.w600)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(
                color      : AppColors.textSecondary,
                fontFamily : 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    color      : AppColors.textMuted,
                    fontFamily : 'Inter')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthController.instance.logout();
              if (context.mounted) context.go('/auth/login');
            },
            child: const Text('Logout',
                style: TextStyle(
                    color      : Colors.white,
                    fontFamily : 'Inter',
                    fontWeight : FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _confirmLogout(context),
        child: Container(
          width  : double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color        : AppColors.error.withValues(alpha: 0.08),
            borderRadius : BorderRadius.circular(14),
            border       : Border.all(
                color: AppColors.error.withValues(alpha: 0.25)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 18),
              SizedBox(width: 8),
              Text('Logout',
                  style: TextStyle(
                      color      : AppColors.error,
                      fontSize   : 14,
                      fontWeight : FontWeight.w600,
                      fontFamily : 'Inter')),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover + Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _CoverAndAvatar extends StatelessWidget {
  final UserModel user;
  final bool      isMe;
  const _CoverAndAvatar({required this.user, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // ✅ isMe + pushed via route = back button dikhao
    // isMe + home tab = back button mat dikhao
    final canGoBack = context.canPop();

    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover
          Container(
            height: 140,
            width : double.infinity,
            decoration: BoxDecoration(
              color : AppColors.accent.withValues(alpha: 0.15),
              image : user.hasCover
                  ? DecorationImage(
                  image: NetworkImage(user.coverPhotoUrl),
                  fit  : BoxFit.cover)
                  : null,
            ),
            child: !user.hasCover
                ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.3),
                    AppColors.accent.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end  : Alignment.bottomRight,
                ),
              ),
            )
                : null,
          ),

          // ✅ Back button — sirf tab se nahi aaya toh dikhao
          if (canGoBack)
            Positioned(
              top: 12, left: 12,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color : Colors.black.withValues(alpha: 0.35),
                      shape : BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),

          // Edit + More options (isMe)
          if (isMe)
            Positioned(
              top: 12, right: 12,
              child: SafeArea(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/profile/edit'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color        : Colors.black.withValues(alpha: 0.35),
                          borderRadius : BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                color: Colors.white, size: 13),
                            SizedBox(width: 5),
                            Text('Edit',
                                style: TextStyle(
                                    color      : Colors.white,
                                    fontSize   : 12,
                                    fontWeight : FontWeight.w500,
                                    fontFamily : 'Inter')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Avatar
          Positioned(
            top: 96, left: 20,
            child: Stack(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape : BoxShape.circle,
                    border: Border.all(
                        color: AppColors.background, width: 3),
                    color : AppColors.accent.withValues(alpha: 0.2),
                    image : user.hasPhoto
                        ? DecorationImage(
                        image: NetworkImage(user.photoUrl),
                        fit  : BoxFit.cover)
                        : null,
                  ),
                  child: !user.hasPhoto
                      ? Center(
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color      : Colors.white,
                        fontSize   : 30,
                        fontWeight : FontWeight.bold,
                        fontFamily : 'Inter',
                      ),
                    ),
                  )
                      : null,
                ),
                if (user.isOnline)
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color : AppColors.success,
                        shape : BoxShape.circle,
                        border: Border.all(
                            color: AppColors.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Follow / Message (not me)
          if (!isMe)
            Positioned(
              bottom: 0, right: 16,
              child: Row(
                children: [
                  _OutlineBtn(
                    label  : 'Follow',
                    icon   : Icons.person_add_rounded,
                    onTap  : () =>
                        ProfileController.instance.toggleFollow(user.id),
                    filled : true,
                  ),
                  const SizedBox(width: 8),
                  _OutlineBtn(
                    label  : 'Message',
                    icon   : Icons.message_rounded,
                    onTap  : () => context.push(
                      '/dm/${user.id}',
                      extra: {
                        'otherUserName' : user.name,
                        'otherUserPhoto': user.photoUrl,
                      },
                    ),
                    filled : false,
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
// Name Section
// ─────────────────────────────────────────────────────────────────────────────

class _NameSection extends StatelessWidget {
  final UserModel user;
  final bool      isMe;
  const _NameSection({required this.user, required this.isMe});

  String _lastActive(Timestamp t) {
    final diff = DateTime.now().difference(t.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours   < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(user.name,
                    style: const TextStyle(
                        color        : AppColors.textPrimary,
                        fontSize     : 22,
                        fontWeight   : FontWeight.w700,
                        letterSpacing: -0.3,
                        fontFamily   : 'Inter')),
              ),
              if (user.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color        : AppColors.accent.withValues(alpha: 0.1),
                    borderRadius : BorderRadius.circular(20),
                    border       : Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppColors.accent, size: 13),
                      SizedBox(width: 4),
                      Text('Verified',
                          style: TextStyle(
                              color      : AppColors.accent,
                              fontSize   : 11,
                              fontWeight : FontWeight.w600,
                              fontFamily : 'Inter')),
                    ],
                  ),
                ),
            ],
          ),
          if (user.username.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text('@${user.username}',
                style: const TextStyle(
                    color      : AppColors.accent,
                    fontSize   : 13,
                    fontFamily : 'Inter')),
          ],
          if (user.jobRole.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.work_outline_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  user.experienceLevel.isNotEmpty
                      ? '${user.experienceLevel} ${user.jobRole}'
                      : user.jobRole,
                  style: const TextStyle(
                      color      : AppColors.textSecondary,
                      fontSize   : 12,
                      fontFamily : 'Inter'),
                ),
              ],
            ),
          ],
          if (user.hasBio) ...[
            const SizedBox(height: 8),
            Text(user.bio,
                style: const TextStyle(
                    color      : AppColors.textSecondary,
                    fontSize   : 13,
                    height     : 1.5,
                    fontFamily : 'Inter')),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color : user.isOnline
                      ? AppColors.success
                      : AppColors.textMuted,
                  shape : BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user.isOnline
                    ? 'Online'
                    : 'Last active ${_lastActive(user.lastActive)}',
                style: const TextStyle(
                    color      : AppColors.textMuted,
                    fontSize   : 11,
                    fontFamily : 'Inter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserModel user;
  const _StatsRow({required this.user});

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color        : const Color(0xFF0E0E1A),
          borderRadius : BorderRadius.circular(14),
          border       : Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _StatCell(label: 'Followers', value: _fmt(user.followerCount)),
            _StatCell(label: 'Following', value: _fmt(user.followingCount)),
            _StatCell(label: 'Groups',    value: _fmt(user.groupCount)),
            _StatCell(label: 'Badges',    value: _fmt(user.badgeCount),
                isLast: true),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool   isLast;
  const _StatCell(
      {required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
              right: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color      : AppColors.textPrimary,
                    fontSize   : 18,
                    fontWeight : FontWeight.w700,
                    fontFamily : 'Inter')),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color        : AppColors.textMuted,
                    fontSize     : 10,
                    letterSpacing: 0.3,
                    fontFamily   : 'Inter')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completion Bar
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionBar extends StatelessWidget {
  final int       percent;
  final UserModel user;
  const _CompletionBar({required this.percent, required this.user});

  String _hint() {
    if (!user.hasPhoto)             return 'Add a profile photo';
    if (user.bio.isEmpty)           return 'Write a short bio';
    if (user.skills.isEmpty)        return 'Add your skills';
    if (user.interests.isEmpty)     return 'Add your interests';
    if (user.jobRole.isEmpty)       return 'Set your job role';
    if (user.currentStatus.isEmpty) return 'Set a current status';
    return 'Almost there!';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color        : const Color(0xFF0E0E1A),
          borderRadius : BorderRadius.circular(14),
          border       : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profile Strength',
                    style: TextStyle(
                        color      : AppColors.textPrimary,
                        fontSize   : 12,
                        fontWeight : FontWeight.w600,
                        fontFamily : 'Inter')),
                Text('$percent%',
                    style: const TextStyle(
                        color      : AppColors.accent,
                        fontSize   : 12,
                        fontWeight : FontWeight.bold,
                        fontFamily : 'Inter')),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value          : percent / 100,
                backgroundColor: AppColors.border,
                valueColor     :
                const AlwaysStoppedAnimation(AppColors.accent),
                minHeight      : 5,
              ),
            ),
            const SizedBox(height: 5),
            Text(_hint(),
                style: const TextStyle(
                    color      : AppColors.textMuted,
                    fontSize   : 11,
                    fontFamily : 'Inter')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final String status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color  : AppColors.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border : Border.all(
              color: AppColors.accent.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded,
                color: AppColors.accent, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(status,
                  style: const TextStyle(
                      color      : AppColors.textSecondary,
                      fontSize   : 13,
                      fontFamily : 'Inter')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tags Section
// ─────────────────────────────────────────────────────────────────────────────

class _TagsSection extends StatelessWidget {
  final String       title;
  final List<String> tags;
  final bool         isAccent;
  const _TagsSection(
      {required this.title, required this.tags, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  color        : AppColors.textMuted,
                  fontSize     : 9,
                  fontWeight   : FontWeight.w600,
                  letterSpacing: 1.5,
                  fontFamily   : 'Inter')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7, runSpacing: 7,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: isAccent
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : const Color(0xFF0E0E1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAccent
                        ? AppColors.accent.withValues(alpha: 0.25)
                        : AppColors.border,
                  ),
                ),
                child: Text(tag,
                    style: TextStyle(
                        color      : isAccent
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontSize   : 12,
                        fontFamily : 'Inter')),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges Section
// ─────────────────────────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final List<String> badges;
  const _BadgesSection({required this.badges});

  static const _info = {
    'early_adopter'   : {'icon': Icons.rocket_launch_outlined,    'label': 'Early Adopter'},
    'top_contributor' : {'icon': Icons.star_outline_rounded,       'label': 'Top Contributor'},
    'verified'        : {'icon': Icons.verified_outlined,          'label': 'Verified'},
    'group_leader'    : {'icon': Icons.workspace_premium_outlined, 'label': 'Group Leader'},
    'task_master'     : {'icon': Icons.task_alt_rounded,           'label': 'Task Master'},
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BADGES',
              style: TextStyle(
                  color        : AppColors.textMuted,
                  fontSize     : 9,
                  fontWeight   : FontWeight.w600,
                  letterSpacing: 1.5,
                  fontFamily   : 'Inter')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7, runSpacing: 7,
            children: badges.map((badge) {
              final info  = _info[badge];
              final icon  = info?['icon']  as IconData? ?? Icons.military_tech_outlined;
              final label = info?['label'] as String?  ?? badge.replaceAll('_', ' ');
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color        : const Color(0xFF0E0E1A),
                  borderRadius : BorderRadius.circular(20),
                  border       : Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.accent, size: 14),
                    const SizedBox(width: 6),
                    Text(label,
                        style: const TextStyle(
                            color      : AppColors.textSecondary,
                            fontSize   : 12,
                            fontFamily : 'Inter')),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About Tab
// ─────────────────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final UserModel user;
  const _AboutTab({required this.user});

  String _fmtDate(Timestamp t) {
    final d = t.toDate();
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user.languages.isNotEmpty) ...[
          _AboutRow(
              icon  : Icons.language_rounded,
              label : 'Languages',
              value : user.languages.join(', ')),
          const SizedBox(height: 12),
        ],
        _AboutRow(
            icon  : Icons.calendar_today_rounded,
            label : 'Member Since',
            value : _fmtDate(user.joinedAt)),
        if (user.groupCount > 0) ...[
          const SizedBox(height: 12),
          _AboutRow(
              icon  : Icons.group_outlined,
              label : 'Groups',
              value : '${user.groupCount} groups joined'),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _AboutRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color        : const Color(0xFF0E0E1A),
        borderRadius : BorderRadius.circular(12),
        border       : Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color        : AppColors.textMuted,
                      fontSize     : 10,
                      letterSpacing: 0.5,
                      fontFamily   : 'Inter')),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color      : AppColors.textPrimary,
                      fontSize   : 13,
                      fontFamily : 'Inter')),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Posts Tab
// ─────────────────────────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  final String userId;
  const _PostsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }
        final posts = snapshot.data?.docs ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape : BoxShape.circle,
                    color : AppColors.accent.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.article_outlined,
                      color: AppColors.accent, size: 28),
                ),
                const SizedBox(height: 14),
                const Text('No posts yet',
                    style: TextStyle(
                        color      : AppColors.textSecondary,
                        fontSize   : 14,
                        fontFamily : 'Inter')),
              ],
            ),
          );
        }
        return ListView.builder(
          padding    : const EdgeInsets.all(16),
          itemCount  : posts.length,
          itemBuilder: (ctx, i) {
            final data = posts[i].data();
            return Container(
              margin  : const EdgeInsets.only(bottom: 10),
              padding : const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color        : const Color(0xFF0E0E1A),
                borderRadius : BorderRadius.circular(14),
                border       : Border.all(color: AppColors.border),
              ),
              child: Text(
                data['content']?.toString() ?? '',
                style: const TextStyle(
                    color      : AppColors.textSecondary,
                    fontSize   : 14,
                    height     : 1.5,
                    fontFamily : 'Inter'),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Buttons
// ─────────────────────────────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final VoidCallback onTap;
  final bool         filled;
  const _OutlineBtn(
      {required this.label,
        required this.icon,
        required this.onTap,
        required this.filled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap : onTap,
      child : Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color        : filled
              ? AppColors.accent
              : Colors.black.withValues(alpha: 0.3),
          borderRadius : BorderRadius.circular(20),
          border       : filled ? null : Border.all(color: Colors.white38),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color      : Colors.white,
                    fontSize   : 12,
                    fontWeight : FontWeight.w600,
                    fontFamily : 'Inter')),
          ],
        ),
      ),
    );
  }
}