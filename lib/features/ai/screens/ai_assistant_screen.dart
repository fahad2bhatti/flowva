import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flowva/core/constants/app_colors.dart';
import 'package:flowva/features/ai/controllers/ai_controller.dart';
import 'package:flowva/data/models/group_model.dart';
import 'package:flowva/data/models/task_model.dart';
import 'package:flowva/features/tasks/controllers/task_controller.dart';

class AIAssistantScreen extends StatefulWidget {
  final GroupModel? group;
  const AIAssistantScreen({super.key, this.group});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final AIController _aiController = AIController.instance;
  final TaskController _taskController = TaskController.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _loading = false;
  bool _isTyping = false;
  List<Map<String, dynamic>> _groupTasks = [];
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add({
      'isUser': false,
      'message': 'Hello! I\'m Flowva AI. How can I help you today?',
      'timestamp': DateTime.now(),
    });
  }

  Future<void> _loadData() async {
    if (widget.group != null) {
      setState(() => _loading = true);

      try {
        // FIX 1: getGroupTasksList returns List<TaskModel> — convert using toMap()
        final List<TaskModel> rawTasks =
        await _taskController.getGroupTasksList(widget.group!.id);
        final List<Map<String, dynamic>> taskMaps =
        rawTasks.map((task) => task.toMap()..['id'] = task.id).toList();

        setState(() {
          _groupTasks = taskMaps;
          _loading = false;
        });

        await _aiController.generateDailyStandup(
          group: widget.group!,
          tasks: _groupTasks,
        );
      } catch (e) {
        setState(() => _loading = false);
        debugPrint('AIAssistantScreen _loadData error: $e');
      }
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'message': message,
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });

    _scrollToBottom();
    _messageController.clear();

    await _processCommand(message);

    if (mounted) setState(() => _isTyping = false);
    _scrollToBottom();
  }

  Future<void> _processCommand(String command) async {
    String response;
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('standup') || lowerCommand.contains('daily')) {
      final standup =
          _aiController.dailyStandup ?? 'No standup available. Pull to refresh.';
      response = 'Daily Standup\n\n$standup';
    } else if (lowerCommand.contains('task') && lowerCommand.contains('break')) {
      response =
      'Please tell me the task title and description.\n\nExample: "Break down: Fix login API - The endpoint is returning 500 error"';
    } else if (lowerCommand.contains('suggest')) {
      await _aiController
          .getTaskSuggestions(widget.group?.description ?? 'Project management');
      final suggestions = _aiController.taskSuggestions;
      response = suggestions.isNotEmpty
          ? 'Task Suggestions\n\n${suggestions.map((s) => '• $s').join('\n')}'
          : 'No suggestions available right now.';
    } else if (lowerCommand.contains('sentiment')) {
      final analysis = _aiController.lastAnalysis;
      if (analysis != null) {
        response =
        'Team Sentiment\n\nOverall: ${analysis['overall']}\nUrgent: ${analysis['urgent'] ? 'Yes' : 'No'}\nSummary: ${analysis['summary']}';
      } else {
        response = 'No sentiment data available. Analyze team posts first.';
      }
    } else if (lowerCommand.contains('summarize')) {
      response = 'Please paste the post content you want me to summarize.';
    } else {
      response =
      'I can help you with:\n\n• "Daily standup" - Get team progress\n• "Break down a task" - Split tasks into subtasks\n• "Suggest tasks" - AI task recommendations\n• "Team sentiment" - Analyze team mood\n• "Summarize a post" - Shorten long content\n\nWhat would you like?';
    }

    if (mounted) {
      setState(() {
        _messages.add({
          'isUser': false,
          'message': response,
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSuggestionTap(String suggestion) => _sendMessage(suggestion);

  // FIX 2: Safe pop — GoRouter ke saath Navigator.pop(context) crash karta hai
  void _safePop() {
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: _safePop, // FIX 2 applied
        ),
        title: const Text(
          'Flowva AI',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.accent, size: 20),
            onPressed: _showHistoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.accent,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  final message = _messages[index];
                  return _buildMessageBubble(
                    message['message'] as String,
                    message['isUser'] as bool,
                    message['timestamp'] as DateTime,
                  );
                },
              ),
            ),
          ),
          if (_messages.length <= 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildSuggestionChips(),
            ),
          if (_messages.length <= 1 && !_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildWelcomeCard(),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flowva AI Assistant',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your AI project manager. Ask me anything about your team!',
                  style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      {'icon': Icons.auto_awesome_rounded, 'label': 'Daily standup'},
      {'icon': Icons.task_alt_rounded, 'label': 'Break down a task'},
      {'icon': Icons.lightbulb_outline, 'label': 'Suggest tasks'},
      {'icon': Icons.analytics_outlined, 'label': 'Team sentiment'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: suggestions.map((s) {
        return ActionChip(
          label: Text(s['label'] as String,
              style:
              const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          avatar: Icon(s['icon'] as IconData, color: AppColors.accent, size: 18),
          onPressed: () => _onSuggestionTap(s['label'] as String),
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildMessageBubble(
      String message, bool isUser, DateTime timestamp) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
        BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
            isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
            isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 12, color: AppColors.accent),
                  const SizedBox(width: 4),
                  const Text('Flowva AI',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              3,
                  (i) => Padding(
                padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                ),
              )),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded,
                  color: AppColors.textSecondary, size: 22),
              onPressed: _showQuickActionsSheet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask Flowva AI...',
                  hintStyle:
                  TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
              child:
              const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // FIX 3: Bottom sheet Navigator.pop(ctx) — ctx is sheet's local context, safe to use
  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Text('Quick Actions',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildQuickActionItem(Icons.auto_awesome_rounded, 'Daily Standup',
                    () {
                  Navigator.pop(ctx);
                  _sendMessage('Daily standup');
                }),
            _buildQuickActionItem(Icons.task_alt_rounded, 'Break Down Task',
                    () async {
                  Navigator.pop(ctx);
                  final taskInfo = await _showTaskInputDialog();
                  if (taskInfo != null) {
                    await _aiController.breakDownTask(
                        taskInfo['title']!, taskInfo['desc']!);
                    _sendMessage('Break down: ${taskInfo['title']}');
                  }
                }),
            _buildQuickActionItem(Icons.summarize, 'Summarize Post', () async {
              Navigator.pop(ctx);
              final postContent = await _showPostInputDialog();
              if (postContent != null && postContent.isNotEmpty) {
                await _aiController.summarizePost(postContent);
                _sendMessage('Summarize: $postContent');
              }
            }),
            _buildQuickActionItem(Icons.insights, 'Team Insights', () {
              Navigator.pop(ctx);
              _sendMessage('Team sentiment');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
      IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.accent, size: 22),
      ),
      title: Text(label,
          style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Chat History',
            style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _messages.isEmpty
              ? const Center(
              child: Text('No conversation yet',
                  style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final msg = _messages[i];
              final text = msg['message'] as String;
              return ListTile(
                leading: Icon(
                  msg['isUser'] as bool
                      ? Icons.person
                      : Icons.auto_awesome_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                title: Text(
                  text.length > 50
                      ? '${text.substring(0, 50)}...'
                      : text,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                ),
                subtitle: Text(
                  _formatTime(msg['timestamp'] as DateTime),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
            const Text('Close', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPostInputDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Paste Post Content',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter long post content...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Summarize'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _showTaskInputDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Break Down Task',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Task Title',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Task Description',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                ctx, {'title': titleCtrl.text, 'desc': descCtrl.text}),
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Break Down'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}