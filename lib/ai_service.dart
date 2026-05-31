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
  Future<Map<String, dynamic>> getDetailedCareerPlan(Map<String, dynamic> userData, String targetCareer);
  Future<Map<String, dynamic>> getSkillResources(String skill, String careerContext);
  Future<Map<String, dynamic>> getCareerAnalysis(Map<String, dynamic> userData, String primaryInterest);
  Future<List<Map<String, dynamic>>> getNearbyRecommendations(Map<String, dynamic> userData, String category);
  Future<Map<String, dynamic>> generatePersonalPlan(String title, String description, List<String> currentSkills, {DateTime? targetCompletionDate});
  Future<Map<String, dynamic>> validateSkillRelevance(String skill, String careerInterest);
  Future<String> getPersonalGuidance(String goal, String prompt, Map<String, dynamic> userData);
  Future<String> getChatResponse(String userMessage, Map<String, dynamic> userData);
  Future<Map<String, dynamic>> getTieredCollegeSuggestions(Map<String, dynamic> userData, {Map<String, dynamic>? preferences});
  Future<Map<String, dynamic>> getSpecificCollegeAdvice(Map<String, dynamic> userData, String collegeName);
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
            {
              "role": "system", 
              "content": "You are a professional, extremely polite, and encouraging career guidance assistant. "
                         "Always use a positive tone. Your goal is to inspire and motivate the user. "
                         "When you see their accomplishments, praise them warmly. "
                         "Never be demotivating. Always respond in JSON format when requested."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
        }),
      ).timeout(const Duration(seconds: 25));

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
      final name = userData['fullName'] ?? 'The candidate';
      final tagline = userData['tagline'] ?? '';
      final skills = (userData['skills'] as List?)?.join(", ") ?? '';
      final careerInterests = (userData['careerInterests'] as List?)?.join(", ") ?? '';

      final prompt = """
        User Profile: $name, $tagline. Skills: $skills. Career Interests: $careerInterests.
        Write a high-impact, professional personal summary for a student.
        Return ONLY the plain text. No JSON, no markdown.
      """;

      final result = await _callAi(prompt);
      return result?.trim() ?? 'Error generating summary.';
    } catch (e) {
      return "AI API Error: $e";
    }
  }

  @override
  Future<Map<String, dynamic>> getDetailedCareerPlan(Map<String, dynamic> userData, String targetCareer) async {
    try {
      final prompt = """
        User Profile: ${jsonEncode(userData)}
        Target Career: $targetCareer
        Act as an expert advisor. Return a JSON object with:
        "achievements": "Summary...", "gap_analysis": "Next steps...", 
        "steps": [{"title": "Step", "duration": "Time"}], "timeline": "Total",
        "industry_news": [{"title": "News", "impact": "Impact", "date": "Now"}],
        "required_skills": [{"name": "Skill", "justification": "Why", "already_mastered": false, "already_in_profile": false}]
      """;

      final result = await _callAi(prompt);
      if (result != null) return json.decode(_stripMarkdown(result));
    } catch (e) {
      print("Error in getDetailedCareerPlan: $e");
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getSkillResources(String skill, String careerContext) async {
    try {
      final prompt = "Provide learning resources for $skill in $careerContext context. Return JSON.";
      final result = await _callAi(prompt);
      if (result != null) return json.decode(_stripMarkdown(result));
    } catch (e) {
      print("Error in getSkillResources: $e");
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getCareerAnalysis(Map<String, dynamic> userData, String primaryInterest) async {
    try {
      final prompt = "Analyze user profile for $primaryInterest. Return JSON with 'strengths' and 'opportunities' lists.";
      final result = await _callAi(prompt);
      if (result != null) return json.decode(_stripMarkdown(result));
    } catch (e) {
      print("Error in getCareerAnalysis: $e");
    }
    return MockAiService().getCareerAnalysis(userData, primaryInterest);
  }

  @override
  Future<List<Map<String, dynamic>>> getNearbyRecommendations(Map<String, dynamic> userData, String category) async {
    try {
      final prompt = "Generate 5 recommendations for $category based on user profile. Return JSON list.";
      final result = await _callAi(prompt);
      if (result != null) {
        final List<dynamic> decoded = json.decode(_stripMarkdown(result));
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (e) {
      print("Error in getNearbyRecommendations: $e");
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> generatePersonalPlan(String title, String description, List<String> currentSkills, {DateTime? targetCompletionDate}) async {
    try {
      String dateContext = targetCompletionDate != null ? "Target date: ${targetCompletionDate.toIso8601String()}" : "";
      final prompt = """
        Goal: $title, Desc: $description, Skills: ${currentSkills.join(", ")}. $dateContext
        Return JSON: {"strengths": "", "negatives": "", "steps": [{"title": "", "description": ""}], "references": [{"title": "", "link": ""}]}
      """;
      final result = await _callAi(prompt);
      if (result != null) return json.decode(_stripMarkdown(result));
    } catch (e) {
      print("Error in generatePersonalPlan: $e");
    }
    return MockAiService().generatePersonalPlan(title, description, currentSkills);
  }

  @override
  Future<Map<String, dynamic>> validateSkillRelevance(String skill, String careerInterest) async {
    try {
      final prompt = "Analyze relevance of $skill for $careerInterest. Return JSON with 'is_relevant', 'connection_type', 'explanation'.";
      final result = await _callAi(prompt);
      if (result != null) return json.decode(_stripMarkdown(result));
    } catch (e) {
      print("Error in validateSkillRelevance: $e");
    }
    return MockAiService().validateSkillRelevance(skill, careerInterest);
  }

  @override
  Future<String> getPersonalGuidance(String goal, String prompt, Map<String, dynamic> userData) async {
    try {
      final result = await _callAi("Topic: $goal. Query: $prompt. Profile: ${jsonEncode(userData)}");
      return result ?? "No guidance available.";
    } catch (e) {
      print("Error in getPersonalGuidance: $e");
      return "Error fetching guidance.";
    }
  }

  @override
  Future<String> getChatResponse(String userMessage, Map<String, dynamic> userData) async {
    try {
      final String fullPrompt = """
        User Query: $userMessage
        Profile: ${jsonEncode(userData)}
        Act as Expert Admissions/Career Consultant. Restricted to: 1. College Admission 2. Skill Acquisition.
        Analyze profile meticulously. If outside topics, redirect.
      """;
      final result = await _callAi(fullPrompt);
      return result ?? "I'm sorry, I couldn't process your request.";
    } catch (e) {
      print("Error in getChatResponse: $e");
      return "An error occurred.";
    }
  }

  @override
  Future<Map<String, dynamic>> getTieredCollegeSuggestions(Map<String, dynamic> userData, {Map<String, dynamic>? preferences}) async {
    try {
      final prefString = preferences != null ? "User Search Preferences: ${jsonEncode(preferences)}" : "";
      final prompt = """
        User Profile: ${jsonEncode(userData)}
        $prefString
        
        Provide a tiered analysis of US colleges based on the profile and the specified preferences. 
        You MUST categorize colleges into 3 tiers based on the Common Data Set (CDS) admission standards:
        1. "Safety/Easy": 10 colleges where the user's profile is well above the 75th percentile.
        2. "Match/Moderate": 10 colleges where the user's profile is between the 25th and 75th percentile.
        3. "Reach/Hard": 10 elite colleges where the user's profile is below or at the 25th percentile.

        Important: Prioritize colleges that match the user's 'subjects' of interest and 'distanceRange' or 'campusSetting' if provided in preferences.
        If 'effortLevel' is Low, suggest more Safety options. If High, focus on high-impact Reach schools.

        For EACH college, provide:
        - "name", "location", "match_percentage" (Current baseline based on GPA/Scores).
        - "match_reason" (Reference CDS data points like GPA rigor and how it aligns with their preferences).
        - "how_to_achieve" (Specific steps).
        - "suitable_courses" (List).
        - "roadmap_impact": A number (1-5) representing how much completing targeted actions improves their chance.
        - "action_value": (E.g. 5) % increase for each completed action.

        Return a JSON object with keys "safety", "match", and "reach", each containing 10 colleges.
        Also include "strengths", "weaknesses", and "top_60_roadmap" for general context.
        Return ONLY raw JSON.
      """;

      final result = await _callAi(prompt);
      if (result != null) return json.decode(_stripMarkdown(result));
    } catch (e) {
      print("Error in getTieredCollegeSuggestions: $e");
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getSpecificCollegeAdvice(Map<String, dynamic> userData, String collegeName) async {
    try {
      final prompt = """
        User Profile: ${jsonEncode(userData)}
        College: $collegeName
        Analyze admission probability based on $collegeName's Common Data Set (CDS).
        Return JSON with:
        - "name", "match_analysis", "academic_strategy", "action_plan", "chances" (Reach/Match/Safety).
        - "base_percentage": (Initial % based on profile).
        - "suggested_extracurriculars": List of high-impact actions.
        - "action_value": (E.g. 5) % increase for each completed action.
        - "holistic_narrative", "cds_insight".
      """;
      final result = await _callAi(prompt);
      if (result != null) return json.decode(_stripMarkdown(result));
    } catch (e) {
      print("Error in getSpecificCollegeAdvice: $e");
    }
    return {};
  }

  String _stripMarkdown(String text) {
    return text.replaceAll('```json', '').replaceAll('```', '').trim();
  }
}

class MockAiService implements AiService {
  @override
  Future<Map<String, dynamic>> getNextSteps(List<String> skills, List<String> interests) async {
    return {'suggestion': 'Portfolio focus', 'course': 'DSA', 'project': 'Finance Tracker'};
  }

  @override
  Future<List<Map<String, String>>> getCareerTrajectory(List<String> skills) async {
    return [{'stage': 'Early', 'role': 'Junior Dev'}, {'stage': 'Mid', 'role': 'Senior Dev'}];
  }

  @override
  Future<String> generateSummary(Map<String, dynamic> userData) async {
    return 'Ambitious student.';
  }

  @override
  Future<Map<String, dynamic>> getDetailedCareerPlan(Map<String, dynamic> userData, String targetCareer) async {
    return {"achievements": "Solid foundation!", "steps": [], "timeline": "5 weeks", "required_skills": []};
  }

  @override
  Future<Map<String, dynamic>> getSkillResources(String skill, String careerContext) async {
    return {"description": "Mastering $skill", "trainings": [], "youtube": [], "docs": []};
  }

  @override
  Future<Map<String, dynamic>> getCareerAnalysis(Map<String, dynamic> userData, String primaryInterest) async {
    return {"strengths": [], "opportunities": [], "closing_thought": "Success awaits!"};
  }

  @override
  Future<List<Map<String, dynamic>>> getNearbyRecommendations(Map<String, dynamic> userData, String category) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> generatePersonalPlan(String title, String description, List<String> currentSkills, {DateTime? targetCompletionDate}) async {
    return {"strengths": "Foundation", "negatives": "Time", "steps": [], "references": []};
  }

  @override
  Future<Map<String, dynamic>> validateSkillRelevance(String skill, String careerInterest) async {
    return {'is_relevant': true, 'connection_type': 'Direct', 'explanation': 'Highly relevant.'};
  }

  @override
  Future<String> getPersonalGuidance(String goal, String prompt, Map<String, dynamic> userData) async {
    return "Focus on practice.";
  }

  @override
  Future<String> getChatResponse(String userMessage, Map<String, dynamic> userData) async {
    return "Explore certifications.";
  }

  @override
  Future<Map<String, dynamic>> getTieredCollegeSuggestions(Map<String, dynamic> userData, {Map<String, dynamic>? preferences}) async {
    return {
      "safety": List.generate(10, (i) => {
        "name": "Safety College ${i + 1}",
        "location": "Location ${i + 1}",
        "match_percentage": 90 - i,
        "match_reason": "Strong alignment with GPA.",
        "how_to_achieve": "Maintain current grades.",
        "suitable_courses": ["CS"],
        "roadmap_impact": 3,
        "action_value": 5
      }),
      "match": List.generate(10, (i) => {
        "name": "Match College ${i + 1}",
        "location": "Location ${i + 1}",
        "match_percentage": 75 - i,
        "match_reason": "Profile fits average student.",
        "how_to_achieve": "Focus on extracurriculars.",
        "suitable_courses": ["CS"],
        "roadmap_impact": 4,
        "action_value": 5
      }),
      "reach": List.generate(10, (i) => {
        "name": "Reach College ${i + 1}",
        "location": "Location ${i + 1}",
        "match_percentage": 40 - i,
        "match_reason": "Highly competitive admission.",
        "how_to_achieve": "High SAT scores needed.",
        "suitable_courses": ["CS"],
        "roadmap_impact": 5,
        "action_value": 5
      }),
      "strengths": [],
      "weaknesses": [],
      "top_60_roadmap": []
    };
  }

  @override
  Future<Map<String, dynamic>> getSpecificCollegeAdvice(Map<String, dynamic> userData, String collegeName) async {
    return {
      "name": collegeName,
      "match_analysis": "Your profile shows significant potential for $collegeName. Your academic record is strong, and your specific interest in AI aligns with their current research priorities. However, $collegeName is highly selective, and you will need to differentiate yourself through your personal narrative.",
      "academic_strategy": "Prioritize AP Calculus BC and AP Physics to demonstrate maximum rigor. Aim for a 'Straight A' record in these specific subjects as they are highly weighted in $collegeName's CDS C9 section.",
      "action_plan": "1. Focus on a capstone AI project over the next 6 months. 2. Prepare for the August SAT to hit the 1550+ mark. 3. Secure a summer internship or research assistant position.",
      "chances": "Reach",
      "holistic_narrative": "Focus your application on the intersection of ethics and AI. Position yourself as a future leader who doesn't just build technology but understands its societal impact—a narrative that resonates deeply with $collegeName's mission.",
      "suggested_extracurriculars": ["Math Olympiad", "Student Council", "Volunteering at Tech Centers"],
      "cds_insight": "Extracurricular activities and character are rated 'Very Important' in their Basis for Selection (CDS C7)."
    };
  }
}
