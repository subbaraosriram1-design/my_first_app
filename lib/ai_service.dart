import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'api_config.dart';

/// Abstract interface for AI suggestions. 
abstract class AiService {
  Future<Map<String, dynamic>> getNextSteps(List<String> skills, List<String> interests);
  Future<List<Map<String, String>>> getCareerTrajectory(List<String> skills);
  Future<String> generateSummary(Map<String, dynamic> userData);
}

/// Implementation using Groq
class GroqAiService implements AiService {
  
  Future<String?> _callAi(String prompt) async {
    String? apiKey;

    if (ApiConfig.useHardcodedKey) {
      apiKey = ApiConfig.apiKey;
    } else {
      apiKey = await FirebaseService.instance.getGrokApiKey(); // Keeping the method name or update it
    }
    
    if (apiKey == null || apiKey.isEmpty) {
      print("Error: AI API Key not found.");
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": ApiConfig.model,
          "messages": [
            {"role": "system", "content": "You are a professional career guidance assistant. Always respond in JSON format when requested."},
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
        throw Exception(errorData['error']?['message'] ?? "API Error ${response.statusCode}");
      }
    } catch (e) {
      print("AI API Call Exception: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getNextSteps(List<String> skills, List<String> interests) async {
    try {
      final prompt = 'User Skills: ${skills.join(", ")}. Interests: ${interests.join(", ")}. '
          'Suggest 1 professional course and 1 project idea. '
          'Return ONLY a raw JSON object with keys "suggestion", "course", and "project". '
          'Do not include markdown code blocks or additional text.';
      
      final result = await _callAi(prompt);
      if (result != null) {
        final cleanText = _stripMarkdown(result);
        return json.decode(cleanText);
      }
    } catch (e) {
      print("Error in getNextSteps: $e");
    }
    return MockAiService().getNextSteps(skills, interests);
  }

  @override
  Future<List<Map<String, String>>> getCareerTrajectory(List<String> skills) async {
    try {
      final prompt = 'Skills: ${skills.join(", ")}. Predict a 3-step career path. '
          'Return ONLY a raw JSON list of objects with "stage" and "role". '
          'Do not include markdown code blocks or additional text.';
      
      final result = await _callAi(prompt);
      if (result != null) {
        final cleanText = _stripMarkdown(result);
        final List<dynamic> decoded = json.decode(cleanText);
        return decoded.map((e) => {
          'stage': e['stage'].toString(),
          'role': e['role'].toString(),
        }).toList();
      }
    } catch (e) {
      print("Error in getCareerTrajectory: $e");
    }
    return MockAiService().getCareerTrajectory(skills);
  }

  @override
  Future<String> generateSummary(Map<String, dynamic> userData) async {
    try {
      // Extracting all available profile information for a comprehensive summary
      final String name = userData['fullName'] ?? 'The candidate';
      final String tagline = userData['tagline'] ?? '';
      
      final List<dynamic> skillsRaw = userData['skills'] ?? [];
      final String skills = skillsRaw.join(", ");
      
      final List<dynamic> otherInterestsRaw = userData['otherInterests'] ?? [];
      final String otherInterests = otherInterestsRaw.join(", ");
      
      final List<dynamic> careerInterestsRaw = userData['careerInterests'] ?? [];
      final String careerInterests = careerInterestsRaw.join(", ");

      final String gpa = "Weighted GPA: ${userData['weightedGpa'] ?? 'N/A'}, Unweighted GPA: ${userData['unweightedGpa'] ?? 'N/A'}";
      final String scores = "SAT: ${userData['satScoreRange'] ?? 'N/A'}, ACT: ${userData['actScoreRange'] ?? 'N/A'}";

      // Process Education
      final List<dynamic> eduRaw = userData['educationList'] ?? [];
      final String education = eduRaw.map((e) => "${e['level']} student at ${e['school']} (Class of ${e['classOf']})").join("; ");

      // Process Projects
      final List<dynamic> projectsRaw = userData['projects'] ?? [];
      final String projects = projectsRaw.map((p) => "${p['title']}: ${p['description']}").join(". ");

      // Process Certifications
      final List<dynamic> certsRaw = userData['certifications'] ?? [];
      final String certs = certsRaw.map((c) => "${c['name']} (${c['level']})").join(", ");

      // Process Goals & Activity Preferences
      final Map<String, dynamic> goalsData = userData['goals'] ?? {};
      final String motivations = List<String>.from(goalsData['extracurricularMotivations'] ?? []).join(", ");
      final String targetLevel = goalsData['targetAchievementLevel'] ?? 'N/A';
      final bool leadership = goalsData['interestedInLeadership'] ?? false;
      final bool research = goalsData['interestedInResearch'] ?? false;

      final Map<String, dynamic> activityPrefs = userData['activityPreferences'] ?? {};
      final String selectiveness = activityPrefs['opportunitySelectiveness'] ?? 'flexible';

      // Constructing the detailed prompt
      final String detailedContext = """
        User Profile Data:
        - Candidate Name: $name
        - Professional Tagline: $tagline
        - Core Technical/Soft Skills: $skills
        - Broader Interests/Hobbies: $otherInterests
        - Target Career Paths: $careerInterests
        - Academic Performance: $gpa, $scores
        - Education Track: $education
        - Significant Projects: $projects
        - Professional Certifications: $certs
        - Strategic Motivations: $motivations
        - Ambition Level: $targetLevel
        - Leadership Interest: ${leadership ? 'High' : 'Standard'}
        - Research Interest: ${research ? 'High' : 'Standard'}
        - Work Environment Preference: $selectiveness opportunities
      """;

      final prompt = """
        Act as a Senior Executive Career Consultant. Write a high-impact, sophisticated, and deeply professional personal summary for the student whose data is provided below.
        
        $detailedContext
        
        Guidelines for the Summary:
        1. Tone: Authoritative, polished, and forward-looking. Use strong action verbs (e.g., "Spearheaded," "Adeptly," "Leveraging").
        2. Content: 
           - Start with a powerful hook that identifies the student's unique value proposition.
           - Bridge their academic excellence (GPA/SAT) with their practical technical skills ($skills).
           - Explicitly highlight their project experience (like the AI Resume Builder) as tangible evidence of their innovative problem-solving.
           - Mention their interest in $careerInterests as a clearly defined career trajectory.
           - Incorporate their interest in ${leadership ? 'leadership' : 'collaborative'} and ${research ? 'research-driven' : 'hands-on'} environments.
        3. Structure: One cohesive, high-quality paragraph (approx. 120-150 words).
        4. Perspective: Third person (use "$name" or "This candidate").
        
        IMPORTANT: Return ONLY the plain text. No JSON, no markdown, no quotes, no conversational filler.
      """;

      final result = await _callAi(prompt);
      
      if (result != null) {
        String cleanResult = result.trim();
        // Safety check to strip common AI "chatter" or JSON formatting
        if (cleanResult.startsWith('{') || cleanResult.startsWith('```')) {
          cleanResult = _stripMarkdown(cleanResult);
          if (cleanResult.startsWith('{')) {
             try {
              final Map<String, dynamic> decoded = json.decode(cleanResult);
              return decoded['summary'] ?? decoded.values.first.toString();
            } catch (e) {
              cleanResult = cleanResult.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '').trim();
            }
          }
        }
        return cleanResult;
      }
      return 'Error generating summary.';
    } catch (e) {
      return "AI API Error: $e. Please check your API configuration.";
    }
  }

  String _stripMarkdown(String text) {
    return text.replaceAll('```json', '').replaceAll('```', '').trim();
  }
}

class MockAiService implements AiService {
  @override
  Future<Map<String, dynamic>> getNextSteps(List<String> skills, List<String> interests) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'suggestion': 'Focus on building a portfolio in your interest areas.',
      'course': 'Advanced Data structures & Algorithms',
      'project': 'AI-powered Personal Finance Tracker'
    };
  }

  @override
  Future<List<Map<String, String>>> getCareerTrajectory(List<String> skills) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      {'stage': 'Early Career', 'role': 'Junior Software Engineer'},
      {'stage': 'Mid-Level', 'role': 'Senior Full Stack Developer'},
      {'stage': 'Senior Level', 'role': 'Solutions Architect'},
    ];
  }

  @override
  Future<String> generateSummary(Map<String, dynamic> userData) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'Ambitious student with a strong focus on technical growth and community contribution.';
  }
}
