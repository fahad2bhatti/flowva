import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/group_repository.dart';
import '../widgets/member_tile.dart';
import '../../../shared/components/empty_state.dart';
import '../../../core/constants/app_colors.dart';

class MembersScreen extends StatefulWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final GroupRepository _groupRepo = GroupRepository.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _searchQuery = '';
  String _selectedRole = 'All';
  bool _isSearching = false;

  final List<String> _roleFilters = ['All', 'owner', 'admin', 'member', 'guest'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          _buildRoleFilters(),
          Expanded(child: _buildMembersList()),
        ],
      ),
      floatingActionButton: _buildInviteFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: const Text(
        'Members',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: () => setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) _searchQuery = '';
          }),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search members...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 18),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      ),
    );
  }

  Widget _buildRoleFilters() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _roleFilters.length,
        itemBuilder: (context, index) {
          final role = _roleFilters[index];
          final isSelected = _selectedRole == role;
          return GestureDetector(
            onTap: () => setState(() => _selectedRole = role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                role == 'All' ? 'All' : role[0].toUpperCase() + role.substring(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembersList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _groupRepo.getGroupMembers(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading members',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        var members = snapshot.data ?? [];

        // Filter by role
        if (_selectedRole != 'All') {
          members = members
              .where((m) => m['role'] == _selectedRole)
              .toList();
        }

        // Filter by search
        if (_searchQuery.isNotEmpty) {
          members = members.where((m) {
            final user = m['user'] as UserModel;
            return user.name.toLowerCase().contains(_searchQuery) ||
                user.username.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (members.isEmpty) {
          return FlowvaEmptyState(type: EmptyStateType.noResults);
        }

        // Sort: owner first, then admin, then member
        members.sort((a, b) {
          const order = {'owner': 0, 'admin': 1, 'member': 2, 'guest': 3};
          return (order[a['role']] ?? 4).compareTo(order[b['role']] ?? 4);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final user = member['user'] as UserModel;
            final role = member['role'] as String;
            final currentUid = _auth.currentUser?.uid;
            final isOwner = _getMyRole(snapshot.data ?? []) == 'owner';

            return MemberTile(
              user: user,
              role: role,
              isCurrentUser: user.id == currentUid,
              canManage: isOwner && user.id != currentUid,
              onRoleChange: (newRole) =>
                  _changeRole(user.id, newRole),
              onRemove: () => _removeMember(user.id, user.name),
            );
          },
        );
      },
    );
  }

  String _getMyRole(List<Map<String, dynamic>> members) {
    final uid = _auth.currentUser?.uid;
    final me = members.where((m) => (m['user'] as UserModel).id == uid);
    if (me.isEmpty) return 'member';
    return me.first['role'] as String;
  }

  Widget _buildInviteFAB() {
    return FloatingActionButton.extended(
      onPressed: _showInviteSheet,
      backgroundColor: AppColors.accent,
      icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
      label: const Text(
        'Invite',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showInviteSheet() async {
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
    final inviteCode = doc.data()?['inviteCode'] ?? '';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Invite to Group',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this code with people you want to invite',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                inviteCode,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InviteButton(
                    icon: Icons.copy_rounded,
                    label: 'Copy Code',
                    onTap: () {
                      // Copy to clipboard
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite code copied!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(String memberId, String newRole) async {
    final success = await _groupRepo.updateMemberRole(
        widget.groupId, memberId, newRole);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Role updated!' : 'Failed to update role'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _removeMember(String memberId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove Member',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Remove $name from this group?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final success =
    await _groupRepo.removeMember(widget.groupId, memberId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '$name removed' : 'Failed to remove'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InviteButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}