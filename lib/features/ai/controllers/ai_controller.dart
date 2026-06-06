import 'package:flutter/material.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/models/group_model.dart';

class AIController extends ChangeNotifier {
  static final AIController _instance = AIController._internal();
  static AIController get instance => _instance;
  AIController._internal();

  final GeminiService _gemini = GeminiService.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _dailyStandup;
  String? get dailyStandup => _dailyStandup;

  List<String> _taskSuggestions = [];
  List<String> get taskSuggestions => _taskSuggestions;

  String? _sentimentSummary;
  String? get sentimentSummary => _sentimentSummary;

  Map<String, dynamic>? _lastAnalysis;
  Map<String, dynamic>? get lastAnalysis => _lastAnalysis;

  Future<void> generateDailyStandup({
    required GroupModel group,
    required List<Map<String, dynamic>> tasks,
  }) async {
    _isLoading = true;
    notifyListeners();

    final taskMaps = tasks.map((t) => {
      'title': t['title'] ?? '',
      'status': t['status'] ?? '',
      'priority': t['priority'] ?? '',
    }).toList();

    final standup = await _gemini.generateDailyStandup(
      groupName: group.name,
      tasks: taskMaps,
      totalMembers: group.memberCount,
    );

    _dailyStandup = standup;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> getTaskSuggestions(String context) async {
    _isLoading = true;
    notifyListeners();

    _taskSuggestions = await _gemini.getTaskSuggestions(context);

    _isLoading = false;
    notifyListeners();
  }

  Future<String> summarizePost(String content) async {
    return await _gemini.summarizePost(content);
  }

  Future<List<String>> breakDownTask(String title, String description) async {
    return await _gemini.breakDownTask(title, description);
  }

  Future<void> analyzeTeamSentiment(List<String> posts) async {
    _isLoading = true;
    notifyListeners();

    _lastAnalysis = await _gemini.analyzeSentiment(posts);
    _sentimentSummary = _lastAnalysis?['summary'];

    _isLoading = false;
    notifyListeners();
  }

  void clearStandup() {
    _dailyStandup = null;
    notifyListeners();
  }
}

