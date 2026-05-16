import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

/// Abstract interface for AI suggestions. 
abstract class AiService {
  Future<Map<String, dynamic>> getNextSteps(List<String> skills, List<String> interests);
  Future<List<Map<String, String>>> getCareerTrajectory(List<String> skills);
  Future<String> generateSummary(Map<String, dynamic> userData);
}

/// Real Implementation using Grok (xAI)
class GrokAiService implements AiService {
  final String _baseUrl = "https://api.x.ai/v1/chat/completions";

  Future<String?> _callGrok(String prompt) async {
    final String? apiKey = await FirebaseService.instance.getGrokApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      print("xAI API Key not found in Firebase Firestore.");
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "grok-beta",
          "messages": [
            {"role": "system", "content": "You are a professional career guidance assistant."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error']?['message'] ?? "Grok API Error \${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getNextSteps(List<String> skills, List<String> interests) async {
    try {
      final prompt = 'User Skills: \${skills.join(", ")}. Interests: \${interests.join(", ")}. '
          'Suggest 1 professional course and 1 project idea. '
          'Return ONLY a raw JSON object with keys "suggestion", "course", and "project". '
          'Do not include markdown code blocks.';
      
      final result = await _callGrok(prompt);
      if (result != null) {
        final cleanText = result.replaceAll('```json', '').replaceAll('```', '').trim();
        return json.decode(cleanText);
      }
    } catch (e) {
      // Fallback
    }
    return MockAiService().getNextSteps(skills, interests);
  }

  @override
  Future<List<Map<String, String>>> getCareerTrajectory(List<String> skills) async {
    try {
      final prompt = 'Skills: \${skills.join(", ")}. Predict a 3-step career path. '
          'Return ONLY a raw JSON list of objects with "stage" and "role". '
          'Do not include markdown code blocks.';
      
      final result = await _callGrok(prompt);
      if (result != null) {
        final cleanText = result.replaceAll('```json', '').replaceAll('```', '').trim();
        final List<dynamic> decoded = json.decode(cleanText);
        return decoded.map((e) => {
          'stage': e['stage'].toString(),
          'role': e['role'].toString(),
        }).toList();
      }
    } catch (e) {
      // Fallback
    }
    return MockAiService().getCareerTrajectory(skills);
  }

  @override
  Future<String> generateSummary(Map<String, dynamic> userData) async {
    try {
      final String goals = List<String>.from(userData['goals']?['extracurricularMotivations'] ?? []).join(", ");
      final String skills = List<String>.from(userData['skills']?.map((s) => s['name']?.toString()) ?? []).join(", ");
      final String gpa = userData['weightedGpa'] ?? userData['unweightedGpa'] ?? 'N/A';
      
      final prompt = 'Write a professional summary for a student profile. '
          'Goals: \$goals. Skills: \$skills. GPA: \$gpa. '
          'Length: 1 paragraph, under 100 words.';
      
      final result = await _callGrok(prompt);
      return result ?? 'Error generating summary.';
    } catch (e) {
      return "Grok API Error: \$e. Ensure you have credits in your xAI account.";
    }
  }
}

class MockAiService implements AiService {
  @override
  Future<Map<String, dynamic>> getNextSteps(List<String> skills, List<String> interests) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'suggestion': 'Mock Suggestion: Focus on leadership.',
      'course': 'Mock Course: AI Foundations',
      'project': 'Mock Project: Smart App'
    };
  }

  @override
  Future<List<Map<String, String>>> getCareerTrajectory(List<String> skills) async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      {'stage': 'Entry', 'role': 'Junior Dev'},
      {'stage': 'Mid', 'role': 'Senior Dev'},
      {'stage': 'Leader', 'role': 'CTO'},
    ];
  }

  @override
  Future<String> generateSummary(Map<String, dynamic> userData) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'This is a mock summary because the real API is not configured yet.';
  }
}
