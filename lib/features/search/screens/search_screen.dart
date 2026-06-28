import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../controllers/search_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl    = TextEditingController();
  final _focus   = FocusNode();

  List<UserModel> _results  = [];
  bool _isLoading           = false;
  bool _hasSearched         = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus keyboard on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }
    setState(() => _isLoading = true);
    final results = await UserSearchController.instance.searchByUsername(query);
    if (mounted) {
      setState(() {
        _results   = results;
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textSecondary),
          onPressed: () =>
          context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color        : AppColors.surface,
            borderRadius : BorderRadius.circular(12),
            border       : Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller : _ctrl,
            focusNode  : _focus,
            onChanged  : _search,
            style: const TextStyle(
                color      : AppColors.textPrimary,
                fontSize   : 14,
                fontFamily : 'Inter'),
            decoration: InputDecoration(
              hintText : 'Search by username...',
              hintStyle: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14, fontFamily: 'Inter'),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  _ctrl.clear();
                  _search('');
                },
                child: const Icon(Icons.clear_rounded,
                    color: AppColors.textMuted, size: 18),
              )
                  : null,
              border         : InputBorder.none,
              contentPadding : const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
        ),
        actions: const [SizedBox(width: 12)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (!_hasSearched) {
      return _buildIdleState();
    }

    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding    : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount  : _results.length,
      itemBuilder: (ctx, i) => _UserTile(user: _results[i]),
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.person_search_rounded,
                color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Find People',
              style: TextStyle(
                  color      : AppColors.textPrimary,
                  fontSize   : 16,
                  fontWeight : FontWeight.w600,
                  fontFamily : 'Inter')),
          const SizedBox(height: 6),
          const Text('Search by @username to find and message people',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color      : AppColors.textMuted,
                  fontSize   : 13,
                  fontFamily : 'Inter')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.search_off_rounded,
                color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No users found',
              style: TextStyle(
                  color      : AppColors.textPrimary,
                  fontSize   : 16,
                  fontWeight : FontWeight.w600,
                  fontFamily : 'Inter')),
          const SizedBox(height: 6),
          Text('No one found with "@${_ctrl.text.trim()}"',
              style: const TextStyle(
                  color      : AppColors.textMuted,
                  fontSize   : 13,
                  fontFamily : 'Inter')),
        ],
      ),
    );
  }
}

// ── User Tile ─────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Container(
      margin  : const EdgeInsets.only(bottom: 10),
      padding : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color        : AppColors.surface,
        borderRadius : BorderRadius.circular(14),
        border       : Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.15),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3)),
              image: user.hasPhoto
                  ? DecorationImage(
                  image: NetworkImage(user.photoUrl),
                  fit  : BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: !user.hasPhoto
                ? Text(initial,
                style: const TextStyle(
                    color      : AppColors.accent,
                    fontWeight : FontWeight.bold,
                    fontSize   : 18))
                : null,
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        color      : AppColors.textPrimary,
                        fontSize   : 14,
                        fontWeight : FontWeight.w600,
                        fontFamily : 'Inter')),
                const SizedBox(height: 2),
                Text('@${user.username}',
                    style: const TextStyle(
                        color      : AppColors.accent,
                        fontSize   : 12,
                        fontFamily : 'Inter')),
                if (user.jobRole.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(user.jobRole,
                      style: const TextStyle(
                          color      : AppColors.textMuted,
                          fontSize   : 11,
                          fontFamily : 'Inter')),
                ],
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              // View Profile
              _ActionBtn(
                icon   : Icons.person_outline_rounded,
                color  : AppColors.textSecondary,
                onTap  : () => context.push(
                    '/profile/${user.id}'),
              ),
              const SizedBox(width: 8),
              // DM
              _ActionBtn(
                icon  : Icons.chat_bubble_outline_rounded,
                color : AppColors.accent,
                onTap : () => context.push(
                  '/dm/${user.id}',
                  extra: {
                    'otherUserName' : user.name,
                    'otherUserPhoto': user.photoUrl,
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap : onTap,
    child : Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color        : color.withValues(alpha: 0.1),
        borderRadius : BorderRadius.circular(10),
        border       : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}