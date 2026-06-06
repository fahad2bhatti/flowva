import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../controllers/profile_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId; // null = current user
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final uid = userId ?? ProfileController.instance.currentUserId ?? '';
    final isMe = userId == null || userId == ProfileController.instance.currentUserId;

    return StreamBuilder<UserModel?>(
      stream: ProfileController.instance.getUserStreamById(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
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
              headerSliverBuilder: (context, _) => [
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

// ─────────────────────────────────────────────────────────────────────────────
// Sliver Header — Cover + Avatar + Info
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSliverHeader extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  const _ProfileSliverHeader({required this.user, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Cover + Avatar
          _CoverSection(user: user, isMe: isMe),

          // Name + Username + Bio
          _InfoSection(user: user, isMe: isMe),

          // Stats row
          _StatsRow(user: user),

          // Profile completion
          if (isMe && user.profileCompletion < 100)
            _CompletionBar(percent: user.profileCompletion),

          // Skills + Interests
          if (user.skills.isNotEmpty) _SkillsSection(user: user),
          if (user.interests.isNotEmpty) _InterestsSection(user: user),

          // Status
          if (user.currentStatus.isNotEmpty) _StatusCard(user: user),

          // Featured
          if (user.featuredItems.isNotEmpty) _FeaturedSection(user: user),

          // Badges
          if (user.badges.isNotEmpty) _BadgesSection(user: user),

          // Tab bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
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
              tabs: [
                Tab(text: 'About'),
                Tab(text: 'Posts'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover + Avatar Section
// ─────────────────────────────────────────────────────────────────────────────

class _CoverSection extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  const _CoverSection({required this.user, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover banner
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha:  0.2),
            image: user.hasCover
                ? DecorationImage(
              image: NetworkImage(user.coverPhotoUrl),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: !user.hasCover
              ? Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha:  0.4),
                  AppColors.accent.withValues(alpha:  0.1),
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
          top: 12,
          left: 12,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:  0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ),

        // Edit cover button (isMe)
        if (isMe)
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:  0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Edit',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Avatar
        Positioned(
          bottom: -40,
          left: 20,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                  color: AppColors.accent,
                  image: user.hasPhoto
                      ? DecorationImage(
                    image: NetworkImage(user.photoUrl),
                    fit: BoxFit.cover,
                  )
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
              // Online indicator
              if (user.isOnline)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Follow/Message buttons (not me)
        if (!isMe)
          Positioned(
            bottom: -20,
            right: 16,
            child: Row(
              children: [
                _ActionButton(
                  label: 'Follow',
                  icon: Icons.person_add_rounded,
                  onTap: () {},
                  filled: true,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Message',
                  icon: Icons.message_rounded,
                  onTap: () {},
                  filled: false,
                ),
              ],
            ),
          ),

        const SizedBox(height: 140),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Section — Name + Username + Bio
// ─────────────────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  const _InfoSection({required this.user, required this.isMe});

  String _lastActive(Timestamp t) {
    final diff = DateTime.now().difference(t.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
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
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (user.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha:  0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withValues(alpha:  0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.accent, size: 14),
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

          const SizedBox(height: 4),

          // Username
          if (user.username.isNotEmpty)
            Text(
              '@${user.username}',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontFamily: 'Inter'),
            ),

          // Job role + Experience
          if (user.jobRole.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.work_outline_rounded,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
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

          // Bio
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

          // Last active
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: user.isOnline ? AppColors.success : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user.isOnline ? 'Online' : 'Last active ${_lastActive(user.lastActive)}',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Inter'),
              ),
            ],
          ),
          const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatItem(label: 'Followers', value: _format(user.followerCount)),
          _Divider(),
          _StatItem(label: 'Following', value: _format(user.followingCount)),
          _Divider(),
          _StatItem(label: 'Groups', value: _format(user.groupCount)),
          _Divider(),
          _StatItem(label: 'Badges', value: _format(user.badgeCount)),
        ],
      ),
    );
  }

  String _format(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Completion Bar
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionBar extends StatelessWidget {
  final int percent;
  const _CompletionBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter')),
                Text('$percent%',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
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
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              percent < 50
                  ? 'Add more info to stand out!'
                  : percent < 80
                  ? 'Almost there — add skills & interests!'
                  : 'Great profile! Add a photo to complete it.',
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

// ─────────────────────────────────────────────────────────────────────────────
// Skills Section
// ─────────────────────────────────────────────────────────────────────────────

class _SkillsSection extends StatelessWidget {
  final UserModel user;
  const _SkillsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '🛠️ Skills'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.skills.map((skill) => _Tag(label: skill)).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interests Section
// ─────────────────────────────────────────────────────────────────────────────

class _InterestsSection extends StatelessWidget {
  final UserModel user;
  const _InterestsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '✨ Interests'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interests.map((i) => _Tag(label: i, isInterest: true)).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final UserModel user;
  const _StatusCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.accent.withValues(alpha:  0.1),
            AppColors.surface,
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withValues(alpha:  0.2)),
        ),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
// Featured Section
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedSection extends StatelessWidget {
  final UserModel user;
  const _FeaturedSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '📌 Featured'),
          const SizedBox(height: 8),
          ...user.featuredItems.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['title']?.toString() ?? 'Featured Item',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontFamily: 'Inter'),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.textMuted),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges Section
// ─────────────────────────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final UserModel user;
  const _BadgesSection({required this.user});

  Map<String, Map<String, String>> get _badgeInfo => {
    'early_adopter': {'icon': '🏆', 'label': 'Early Adopter'},
    'top_contributor': {'icon': '⭐', 'label': 'Top Contributor'},
    'verified': {'icon': '✅', 'label': 'Verified'},
    'group_leader': {'icon': '👑', 'label': 'Group Leader'},
    'task_master': {'icon': '🎯', 'label': 'Task Master'},
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '🏅 Badges'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.badges.map((badge) {
              final info = _badgeInfo[badge] ??
                  {'icon': '🎖️', 'label': badge.replaceAll('_', ' ')};
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(info['icon']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      info['label']!,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user.languages.isNotEmpty) ...[
          const _SectionTitle(title: '🌐 Languages'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.languages.map((l) => _Tag(label: l)).toList(),
          ),
          const SizedBox(height: 16),
        ],
        const _SectionTitle(title: '📅 Member Since'),
        const SizedBox(height: 8),
        Text(
          _formatDate(user.joinedAt),
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontFamily: 'Inter'),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  String _formatDate(Timestamp t) {
    final d = t.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
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
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📝', style: TextStyle(fontSize: 40)),
                SizedBox(height: 12),
                Text('No posts yet',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter')),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (ctx, i) {
            final data = posts[i].data();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared Small Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    );
  }
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
            ? AppColors.accent.withValues(alpha:  0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInterest
              ? AppColors.accent.withValues(alpha:  0.3)
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.black.withValues(alpha:  0.3),
          borderRadius: BorderRadius.circular(20),
          border: filled ? null : Border.all(color: Colors.white38),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
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

