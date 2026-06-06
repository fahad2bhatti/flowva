import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  static GeminiService get instance => _instance;
  GeminiService._internal();

  late GenerativeModel _model;
  late GenerativeModel _flashModel;
  bool _initialized = false;

  // .env se API key load karo
  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1000,
      ),
    );

    _flashModel = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 500,
      ),
    );

    _initialized = true;
  }

  // 1. Generate Daily Standup
  Future<String> generateDailyStandup({
    required String groupName,
    required List<Map<String, dynamic>> tasks,
    required int totalMembers,
  }) async {
    await initialize();

    final taskSummary = tasks.map((t) =>
    "- ${t['title']} (${t['status']}) - Priority: ${t['priority']}"
    ).join('\n');

    final prompt = '''
You are an AI project manager for "$groupName" ($totalMembers members).
Generate a professional, energetic daily standup based on these tasks:

Tasks:
$taskSummary

Format (use exactly this):
✨ AI Standup - {current time}

**Yesterday's Progress:**
- {completed tasks summary}

**Today's Focus:**
- {upcoming tasks}

**Blockers/Risks:**
- {if any, otherwise "None"}

Keep it concise (max 150 words). Add appropriate emojis.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? _getFallbackStandup();
    } catch (e) {
      debugPrint("Gemini error: $e");
      return _getFallbackStandup();
    }
  }

  String _getFallbackStandup() {
    return '''
✨ AI Standup - ${DateTime.now().hour}:00

**Yesterday's Progress:**
- Team made good progress on ongoing tasks

**Today's Focus:**
- Continue with priority tasks

**Blockers/Risks:**
- None reported

> 🤖 Powered by Gemini AI
''';
  }

  // 2. Summarize Long Post
  Future<String> summarizePost(String content) async {
    await initialize();

    final prompt = '''
Summarize the following post in 1 short sentence (max 20 words):
"$content"
''';

    try {
      final response = await _flashModel.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? (content.length > 50 ? '${content.substring(0, 50)}...' : content);
    } catch (e) {
      return content.length > 60 ? '${content.substring(0, 60)}...' : content;
    }
  }

  // 3. Suggest Task Breakdown
  Future<List<String>> breakDownTask(String taskTitle, String taskDescription) async {
    await initialize();

    final prompt = '''
Break down this task into 3-5 subtasks:
Task: "$taskTitle"
Description: "$taskDescription"

Return only as a numbered list, no extra text.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      final subtasks = text.split('\n')
          .where((line) => line.trim().isNotEmpty && RegExp(r'^\d+\.').hasMatch(line))
          .map((line) => line.replaceFirst(RegExp(r'^\d+\.'), '').trim())
          .toList();

      return subtasks.isEmpty ? ['Complete the task', 'Review and submit'] : subtasks;
    } catch (e) {
      return ['Complete: $taskTitle', 'Review and submit'];
    }
  }

  // 4. Analyze Team Sentiment
  Future<Map<String, dynamic>> analyzeSentiment(List<String> recentPosts) async {
    await initialize();

    final postsText = recentPosts.take(5).join('\n---\n');

    final prompt = '''
Analyze the sentiment of these team messages and return ONLY JSON:
{
  "overall": "positive/neutral/negative",
  "urgent": true/false,
  "summary": "one line summary"
}

Messages:
$postsText
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(text);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        return {
          'overall': _extractValue(jsonStr, 'overall'),
          'urgent': _extractValue(jsonStr, 'urgent') == 'true',
          'summary': _extractValue(jsonStr, 'summary'),
        };
      }
      return {'overall': 'neutral', 'urgent': false, 'summary': 'Team activity detected'};
    } catch (e) {
      return {'overall': 'neutral', 'urgent': false, 'summary': 'Analysis unavailable'};
    }
  }

  String _extractValue(String json, String key) {
    final pattern = RegExp('"$key":"?([^",}]+)"?');
    final match = pattern.firstMatch(json);
    return match?.group(1)?.trim() ?? '';
  }

  // 5. Smart Task Suggestions
  Future<List<String>> getTaskSuggestions(String groupContext) async {
    await initialize();

    final prompt = '''
Based on this project description: "$groupContext"
Suggest 3 tasks that the team should prioritize.
Return as a simple list (one task per line, no numbering).
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      return text.split('\n')
          .where((l) => l.trim().isNotEmpty)
          .take(3)
          .toList();
    } catch (e) {
      return ['Plan next sprint', 'Review pending tasks', 'Team check-in'];
    }
  }
}

