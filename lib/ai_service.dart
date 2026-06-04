import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  Future<Map<String, dynamic>> getTargetActionPlan(String collegeName, String actionTitle, Map<String, dynamic> userData);
  Future<List<Map<String, dynamic>>> searchCollegesByName(String query);
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
      debugPrint("Error: AI API Key not found.");
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
                         "Never be demotivating. "
                         "IMPORTANT: When JSON is requested, return ONLY valid JSON. "
                         "Ensure all strings are properly closed and all brackets match. "
                         "Do not include any text before or after the JSON block."
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
      debugPrint("AI API Call Exception: $e");
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
      debugPrint("Error in getNextSteps: $e");
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
      debugPrint("Error in getCareerTrajectory: $e");
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
      debugPrint("Error in getDetailedCareerPlan: $e");
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
      debugPrint("Error in getSkillResources: $e");
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
      debugPrint("Error in getCareerAnalysis: $e");
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
      debugPrint("Error in getNearbyRecommendations: $category: $e");
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
      debugPrint("Error in generatePersonalPlan: $e");
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
      debugPrint("Error in validateSkillRelevance: $e");
    }
    return MockAiService().validateSkillRelevance(skill, careerInterest);
  }

  @override
  Future<String> getPersonalGuidance(String goal, String prompt, Map<String, dynamic> userData) async {
    try {
      final result = await _callAi("Topic: $goal. Query: $prompt. Profile: ${jsonEncode(userData)}");
      return result ?? "No guidance available.";
    } catch (e) {
      debugPrint("Error in getPersonalGuidance: $e");
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
      debugPrint("Error in getChatResponse: $e");
      return "An error occurred.";
    }
  }

  @override
  Future<Map<String, dynamic>> getTieredCollegeSuggestions(Map<String, dynamic> userData, {Map<String, dynamic>? preferences}) async {
    try {
      final trimmedProfile = _trimUserData(userData);
      final prefString = preferences != null ? "User Search Preferences: ${jsonEncode(preferences)}" : "";
      final prompt = """
        User Profile: ${jsonEncode(trimmedProfile)}
        $prefString
        
        Provide a tiered analysis of US colleges (5 per tier). 
        Tiers:
        1. "Safety/Easy": 5 colleges well above 75th percentile.
        2. "Match/Moderate": 5 colleges between 25-75th percentile.
        3. "Reach/Hard": 5 elite colleges at/below 25th percentile.

        Prioritize colleges matching 'subjects', 'distanceRange', or 'campusSetting'.
        
        CRITICAL: Use REAL college names and locations. 

        Return JSON with keys "safety", "match", "reach" (5 each), "strengths", "weaknesses", "top_60_roadmap".
        Format for each college: "name", "location", "match_percentage", "match_reason", "how_to_achieve", "suitable_courses" (list), "roadmap_impact", "action_value".
      """;

      final result = await _callAi(prompt);
      if (result != null) {
        final cleanText = _stripMarkdown(result);
        final decoded = json.decode(cleanText);
        if (decoded is Map<String, dynamic>) {
          // Ensure all required keys are present even if AI misses some
          return {
            "safety": decoded['safety'] ?? [],
            "match": decoded['match'] ?? [],
            "reach": decoded['reach'] ?? [],
            "strengths": decoded['strengths'] ?? [],
            "weaknesses": decoded['weaknesses'] ?? [],
            "top_60_roadmap": decoded['top_60_roadmap'] ?? [],
          };
        }
      }
    } catch (e) {
      debugPrint("Error in getTieredCollegeSuggestions: $e");
      rethrow;
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getSpecificCollegeAdvice(Map<String, dynamic> userData, String collegeName) async {
    try {
      final prompt = """
        User Profile: ${jsonEncode(userData)}
        College: $collegeName
        Analyze admission probability based on $collegeName's Common Data Set (CDS) and holistic review process.
        Return JSON with:
        - "name", "match_analysis", "academic_strategy", "action_plan", "chances" (Reach/Match/Safety).
        - "base_percentage": (Initial % based on profile).
        - "avg_gpa", "avg_sat", "avg_act": (Specific to $collegeName).
        - "extracurricular_strategy": (Detailed advice on which activities $collegeName values most, e.g. leadership, research, service).
        - "extracurricular_weight": (High/Medium/Low - how much they value non-academics).
        - "suggested_extracurriculars": List of objects with "title", "suggestion", and "resource_link" (Provide a real helpful URL like Khan Academy, Coursera, or official research portals for each. The suggestion should explain HOW this specific activity helps for $collegeName).
        - "action_value": (E.g. 5) % increase for each completed action.
        - "holistic_narrative", "cds_insight".
        - "financial_aid_hint": (Briefly mention their aid policy, e.g. need-blind).
        
        CRITICAL: Ensure every single field is filled with high-quality, specific advice. Provide valid URLs for resource links.
      """;
      final result = await _callAi(prompt);
      if (result != null) return json.decode(_stripMarkdown(result));
    } catch (e) {
      debugPrint("Error in getSpecificCollegeAdvice: $e");
      rethrow;
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getTargetActionPlan(String collegeName, String actionTitle, Map<String, dynamic> userData) async {
    return {
      "title": actionTitle,
      "overview": "Detailed strategy for $actionTitle at $collegeName.",
      "steps": ["Step 1: Research requirements", "Step 2: Create a timeline", "Step 3: Execute and document"],
      "google_search_link": "https://www.google.com/search?q=$actionTitle+for+$collegeName",
      "youtube_search_link": "https://www.youtube.com/results?search_query=$actionTitle+guide"
    };
  }

  @override
  Future<List<Map<String, dynamic>>> searchCollegesByName(String query) async {
    try {
      final prompt = """
        Find colleges related to the search query: "$query".
        Return a JSON list of objects, each containing:
        - "name": Full name of the college.
        - "location": City, State.
        Return at most 5 relevant results.
        Return ONLY raw JSON.
      """;
      final result = await _callAi(prompt);
      if (result != null) {
        final List<dynamic> decoded = json.decode(_stripMarkdown(result));
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (e) {
      debugPrint("Error in searchCollegesByName: $e");
      rethrow;
    }
    return [];
  }

  String _stripMarkdown(String text) {
    String clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return _sanitizeJson(clean);
  }

  /// Attempts to fix common JSON issues like unterminated strings or missing brackets
  String _sanitizeJson(String jsonString) {
    if (jsonString.isEmpty) return "{}";
    
    String sanitized = jsonString;

    // Fix 1: Unterminated string at the end of the JSON
    // If the string ends with a non-quote character and is inside a quote block
    bool inQuote = false;
    for (int i = 0; i < sanitized.length; i++) {
      if (sanitized[i] == '"' && (i == 0 || sanitized[i - 1] != '\\')) {
        inQuote = !inQuote;
      }
    }
    if (inQuote) {
      sanitized += '"';
    }

    // Fix 2: Missing closing brackets/braces
    int braceCount = 0;
    int bracketCount = 0;
    inQuote = false;
    for (int i = 0; i < sanitized.length; i++) {
      if (sanitized[i] == '"' && (i == 0 || sanitized[i - 1] != '\\')) {
        inQuote = !inQuote;
      }
      if (!inQuote) {
        if (sanitized[i] == '{') braceCount++;
        if (sanitized[i] == '}') braceCount--;
        if (sanitized[i] == '[') bracketCount++;
        if (sanitized[i] == ']') bracketCount--;
      }
    }

    while (braceCount > 0) {
      sanitized += '}';
      braceCount--;
    }
    while (bracketCount > 0) {
      sanitized += ']';
      bracketCount--;
    }

    return sanitized;
  }

  Map<String, dynamic> _trimUserData(Map<String, dynamic> userData) {
    return {
      'fullName': userData['fullName'],
      'weightedGpa': userData['weightedGpa'],
      'satScoreRange': userData['satScoreRange'],
      'actScoreRange': userData['actScoreRange'],
      'skills': (userData['skills'] as List?)?.take(5).toList(),
      'careerInterests': (userData['careerInterests'] as List?)?.take(3).toList(),
      'notableAchievements': (userData['notableAchievements'] as List?)?.take(3).toList(),
    };
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
      "safety": [
        {
          "name": "Rutgers University",
          "location": "New Brunswick, NJ",
          "match_percentage": 88,
          "match_reason": "GPA is well above average for admitted students.",
          "how_to_achieve": "Maintain current academic standing.",
          "suitable_courses": ["Computer Science", "Engineering"],
          "roadmap_impact": 3,
          "action_value": 5
        },
        {
          "name": "University of Maryland",
          "location": "College Park, MD",
          "match_percentage": 85,
          "match_reason": "Strong alignment with extracurricular profile.",
          "how_to_achieve": "Submit a strong early action application.",
          "suitable_courses": ["Data Science", "Cybersecurity"],
          "roadmap_impact": 3,
          "action_value": 5
        },
      ],
      "match": [
        {
          "name": "University of Michigan",
          "location": "Ann Arbor, MI",
          "match_percentage": 72,
          "match_reason": "GPA and SAT scores are within the 50th percentile.",
          "how_to_achieve": "Focus on leadership roles in clubs.",
          "suitable_courses": ["Business Administration", "Informatics"],
          "roadmap_impact": 4,
          "action_value": 5
        },
        {
          "name": "Georgia Institute of Technology",
          "location": "Atlanta, GA",
          "match_percentage": 68,
          "match_reason": "Excellent match for STEM-focused profile.",
          "how_to_achieve": "Highlight technical projects in essays.",
          "suitable_courses": ["Aerospace Engineering", "AI"],
          "roadmap_impact": 4,
          "action_value": 5
        },
      ],
      "reach": [
        {
          "name": "Stanford University",
          "location": "Stanford, CA",
          "match_percentage": 35,
          "match_reason": "Highly selective; profile is competitive but below 75th percentile.",
          "how_to_achieve": "Achieve exceptional SAT scores and unique projects.",
          "suitable_courses": ["Symbolic Systems", "CS"],
          "roadmap_impact": 5,
          "action_value": 5
        },
        {
          "name": "Harvard University",
          "location": "Cambridge, MA",
          "match_percentage": 30,
          "match_reason": "Elite institution requiring exceptional holistic narrative.",
          "how_to_achieve": "Demonstrate national-level impact in extracurriculars.",
          "suitable_courses": ["Applied Math", "Economics"],
          "roadmap_impact": 5,
          "action_value": 5
        },
      ],
      "strengths": [
        {"title": "Strong Academic Foundation", "detailed_explanation": "Your GPA demonstrates consistent rigor across core subjects."}
      ],
      "weaknesses": [
        {"title": "Limited Research Experience", "detailed_explanation": "Elite colleges look for independent research or high-impact projects."}
      ],
      "top_60_roadmap": [
        "Complete at least 3 AP courses in junior year",
        "Secure a leadership position in a major student organization",
        "Begin work on a significant independent research project"
      ]
    };
  }

  @override
  Future<Map<String, dynamic>> getSpecificCollegeAdvice(Map<String, dynamic> userData, String collegeName) async {
    return {
      "name": collegeName,
      "match_analysis": "Your profile shows significant potential for $collegeName. Your academic record is strong, and your interest in AI aligns with their research priorities.",
      "academic_strategy": "Prioritize AP Calculus BC and AP Physics to demonstrate maximum rigor. Aim for 'Straight As' in these subjects.",
      "action_plan": "1. Focus on a capstone AI project. 2. Prepare for the SAT to hit the 1550+ mark. 3. Secure a summer internship.",
      "chances": "Reach",
      "holistic_narrative": "Focus your application on the intersection of ethics and AI. Positioning yourself as a future leader who understands societal impact.",
      "suggested_extracurriculars": [
        {
          "title": "Math Olympiad", 
          "suggestion": "Participating in high-level math competitions demonstrates the quantitative rigor $collegeName looks for in STEM applicants.",
          "resource_link": "https://www.maa.org/math-competitions"
        },
        {
          "title": "Student Council", 
          "suggestion": "Leadership roles are critical for $collegeName's holistic review. This shows you can lead and influence your community.",
          "resource_link": "https://www.natstuco.org/"
        },
        {
          "title": "AI Research Project", 
          "suggestion": "Independent research projects show intellectual curiosity and initiative, setting you apart from other high-achieving students.",
          "resource_link": "https://www.edx.org/course/artificial-intelligence-ai"
        }
      ],
      "avg_gpa": 3.9,
      "avg_sat": 1520,
      "avg_act": 34,
      "extracurricular_strategy": "This college values leadership and independent research highly. Focus on showing initiative.",
      "extracurricular_weight": "High",
      "financial_aid_hint": "Need-blind for domestic students, meets 100% of demonstrated need.",
      "cds_insight": "Extracurricular activities and character are rated 'Very Important' in their Basis for Selection (CDS C7)."
    };
  }

  @override
  Future<Map<String, dynamic>> getTargetActionPlan(String collegeName, String actionTitle, Map<String, dynamic> userData) async {
    return {
      "title": actionTitle,
      "overview": "Detailed strategy for $actionTitle at $collegeName.",
      "steps": ["Step 1: Research requirements", "Step 2: Create a timeline", "Step 3: Execute and document"],
      "google_search_link": "https://www.google.com/search?q=$actionTitle+for+$collegeName",
      "youtube_search_link": "https://www.youtube.com/results?search_query=$actionTitle+guide"
    };
  }

  @override
  Future<List<Map<String, dynamic>>> searchCollegesByName(String query) async {
    return [
      {"name": "$query University", "location": "New York, NY"},
      {"name": "Institute of $query", "location": "Boston, MA"},
    ];
  }
}
