import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final uid  = userId ?? ProfileController.instance.currentUserId ?? '';
    final isMe = userId == null ||
        userId == ProfileController.instance.currentUserId;

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
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
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
                _ProfileSliverHeader(user: user, isMe: isMe),
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

// ─────────────────────────────────────────────
// Sliver Header
// ─────────────────────────────────────────────

class _ProfileSliverHeader extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  const _ProfileSliverHeader({required this.user, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _CoverSection(user: user, isMe: isMe),
          const SizedBox(height: 48),
          _InfoSection(user: user, isMe: isMe),
          const SizedBox(height: 16),
          _StatsRow(user: user),
          if (isMe && user.profileCompletion < 100) ...[
            const SizedBox(height: 12),
            _CompletionBar(percent: user.profileCompletion),
          ],
          if (user.currentStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            _StatusCard(user: user),
          ],
          if (user.skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TagsSection(title: 'Skills', tags: user.skills),
          ],
          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TagsSection(
                title: 'Interests', tags: user.interests, isInterest: true),
          ],
          if (user.badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            _BadgesSection(user: user),
          ],
          const SizedBox(height: 12),
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: const TabBar(
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2,
              labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'Inter'),
              tabs: [Tab(text: 'About'), Tab(text: 'Posts')],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Cover + Avatar
// ─────────────────────────────────────────────

class _CoverSection extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  const _CoverSection({required this.user, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover
        Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            image: user.hasCover
                ? DecorationImage(
                image: NetworkImage(user.coverPhotoUrl),
                fit: BoxFit.cover)
                : null,
          ),
          child: !user.hasCover
              ? Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.3),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          )
              : null,
        ),

        // Back button
        Positioned(
          top: 12, left: 12,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => context.canPop() ? context.pop() : null,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ),

        // Edit button (isMe)
        if (isMe)
          Positioned(
            top: 12, right: 12,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => context.push('/profile/edit'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          color: Colors.white, size: 13),
                      SizedBox(width: 5),
                      Text('Edit',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Avatar
        Positioned(
          bottom: -44, left: 20,
          child: Stack(
            children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                  color: AppColors.accent,
                  image: user.hasPhoto
                      ? DecorationImage(
                      image: NetworkImage(user.photoUrl),
                      fit: BoxFit.cover)
                      : null,
                ),
                child: !user.hasPhoto
                    ? Center(
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
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
                      color: AppColors.success,
                      shape: BoxShape.circle,
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
            bottom: -36, right: 16,
            child: Row(
              children: [
                _OutlineBtn(
                  label: 'Follow',
                  icon: Icons.person_add_rounded,
                  onTap: () => ProfileController.instance
                      .toggleFollow(user.id),
                ),
                const SizedBox(width: 8),
                _OutlineBtn(
                  label: 'Message',
                  icon: Icons.message_rounded,
                  onTap: () => context.push(
                    '/dm/${user.id}',
                    extra: {
                      'otherUserName' : user.name,
                      'otherUserPhoto': user.photoUrl,
                    },
                  ),
                  filled: true,
                ),
              ],
            ),
          ),

        const SizedBox(height: 130),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Info Section
// ─────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  const _InfoSection({required this.user, required this.isMe});

  String _lastActive(Timestamp t) {
    final diff = DateTime.now().difference(t.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Verified
          Row(
            children: [
              Expanded(
                child: Text(
                  user.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (user.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppColors.accent, size: 13),
                      SizedBox(width: 4),
                      Text('Verified',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
            ],
          ),

          if (user.username.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text('@${user.username}',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontFamily: 'Inter')),
          ],

          if (user.jobRole.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.work_outline_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  user.experienceLevel.isNotEmpty
                      ? '${user.experienceLevel} ${user.jobRole}'
                      : user.jobRole,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Inter'),
                ),
              ],
            ),
          ],

          if (user.hasBio) ...[
            const SizedBox(height: 10),
            Text(
              user.bio,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: 'Inter'),
            ),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: user.isOnline
                      ? AppColors.success
                      : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user.isOnline
                    ? 'Online'
                    : 'Last active ${_lastActive(user.lastActive)}',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Inter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _StatCell(label: 'Followers', value: _fmt(user.followerCount)),
            _VertLine(),
            _StatCell(label: 'Following', value: _fmt(user.followingCount)),
            _VertLine(),
            _StatCell(label: 'Groups',    value: _fmt(user.groupCount)),
            _VertLine(),
            _StatCell(label: 'Badges',    value: _fmt(user.badgeCount)),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label, value;
  const _StatCell({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter')),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

class _VertLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: AppColors.border);
}

// ─────────────────────────────────────────────
// Completion Bar
// ─────────────────────────────────────────────

class _CompletionBar extends StatelessWidget {
  final int percent;
  const _CompletionBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profile Strength',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter')),
                Text('$percent%',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter')),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: AppColors.border,
                valueColor:
                const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              percent < 50
                  ? 'Add more info to stand out'
                  : percent < 80
                  ? 'Almost there — add skills and interests'
                  : 'Add a photo to complete your profile',
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'Inter'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Status Card
// ─────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final UserModel user;
  const _StatusCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded,
                color: AppColors.accent, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                user.currentStatus,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontFamily: 'Inter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tags Section — Skills + Interests
// ─────────────────────────────────────────────

class _TagsSection extends StatelessWidget {
  final String title;
  final List<String> tags;
  final bool isInterest;

  const _TagsSection({
    required this.title,
    required this.tags,
    this.isInterest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((t) => _Tag(label: t, isInterest: isInterest))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Badges Section
// ─────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final UserModel user;
  const _BadgesSection({required this.user});

  static const _badgeInfo = {
    'early_adopter'   : {'icon': Icons.emoji_events_rounded,  'label': 'Early Adopter'},
    'top_contributor' : {'icon': Icons.star_rounded,           'label': 'Top Contributor'},
    'verified'        : {'icon': Icons.verified_rounded,       'label': 'Verified'},
    'group_leader'    : {'icon': Icons.workspace_premium_rounded,'label': 'Group Leader'},
    'task_master'     : {'icon': Icons.task_alt_rounded,       'label': 'Task Master'},
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BADGES',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.badges.map((badge) {
              final info = _badgeInfo[badge];
              final icon  = info?['icon']  as IconData? ?? Icons.military_tech_rounded;
              final label = info?['label'] as String?  ?? badge.replaceAll('_', ' ');
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.accent, size: 13),
                    const SizedBox(width: 6),
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter')),
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

// ─────────────────────────────────────────────
// About Tab
// ─────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final UserModel user;
  const _AboutTab({required this.user});

  String _formatDate(Timestamp t) {
    final d = t.toDate();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        if (user.languages.isNotEmpty) ...[
          const _SectionLabel(text: 'LANGUAGES'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.languages
                .map((l) => _Tag(label: l))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        const _SectionLabel(text: 'MEMBER SINCE'),
        const SizedBox(height: 6),
        Text(
          _formatDate(user.joinedAt),
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontFamily: 'Inter'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Posts Tab
// ─────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  final String userId;
  const _PostsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('posts')
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
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.article_outlined,
                      color: AppColors.accent, size: 28),
                ),
                const SizedBox(height: 12),
                const Text('No posts yet',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter')),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: posts.length,
          itemBuilder: (ctx, i) {
            final data = posts[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                data['content']?.toString() ?? '',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'Inter'),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 1.5,
      fontFamily: 'Inter',
    ),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isInterest;
  const _Tag({required this.label, this.isInterest = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isInterest
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInterest
              ? AppColors.accent.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isInterest ? AppColors.accent : AppColors.textSecondary,
          fontSize: 12,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.accent
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: filled ? null : Border.all(color: Colors.white38),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}