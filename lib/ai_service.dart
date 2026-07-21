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
  Future<String> generateHtmlResume(String base64Image, Map<String, dynamic> userData);
  Future<Map<String, dynamic>> analyzeDocxTemplate(String text);
  Future<Map<String, dynamic>> analyzeAndFillTemplate(String base64Image, Map<String, dynamic> userData);
}

/// Implementation using Groq
class GroqAiService implements AiService {
  
  Future<String?> _callAi(String prompt, {String? base64Image}) async {
    String? apiKey;

    if (ApiConfig.useHardcodedKey) {
      apiKey = ApiConfig.apiKey;
    } else {
      apiKey = await FirebaseService.instance.getGrokApiKey(); 
    }
    
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("Error: AI API Key not found.");
      return null;
    }

    try {
      final List<Map<String, dynamic>> userMessageContent = [
        {"type": "text", "text": prompt}
      ];

      if (base64Image != null) {
        userMessageContent.add({
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,$base64Image"
          }
        });
      }

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
              "content": "You are a professional resume designer and career consultant. "
                         "When an image is provided, it is a template for reference. "
                         "Analyze its layout, fonts, and style precisely. "
                         "Return only valid JSON or HTML as requested. "
                         "Do not include any text before or after the code block."
            },
            {"role": "user", "content": userMessageContent}
          ],
          "temperature": 0.1, // Lower temperature for more precise layout recreation
        }),
      ).timeout(const Duration(seconds: 45));

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
      if (result != null) {
        final decoded = json.decode(_stripMarkdown(result));
        if (decoded is Map<String, dynamic>) {
          return {
            'achievements': decoded['achievements']?.toString() ?? '',
            'gap_analysis': decoded['gap_analysis']?.toString() ?? '',
            'steps': decoded['steps'] is List ? decoded['steps'] : [],
            'timeline': decoded['timeline']?.toString() ?? '',
            'industry_news': decoded['industry_news'] is List ? decoded['industry_news'] : [],
            'required_skills': decoded['required_skills'] is List ? decoded['required_skills'] : [],
          };
        }
      }
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
      final prompt = "Analyze user profile for $primaryInterest. Return JSON with 'strengths' and 'opportunities' lists (each item has 'title' and 'description' keys), and a 'closing_thought' string.";
      final result = await _callAi(prompt);
      if (result != null) {
        final decoded = json.decode(_stripMarkdown(result));
        if (decoded is Map<String, dynamic>) {
          return {
            'strengths': decoded['strengths'] is List ? decoded['strengths'] : [],
            'opportunities': decoded['opportunities'] is List ? decoded['opportunities'] : [],
            'closing_thought': decoded['closing_thought']?.toString() ?? '',
          };
        }
      }
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
      final String contextPrompt = goal == "Resume Optimization" 
          ? "$prompt\nCRITICAL: Return ONLY the optimized text. Do not include labels like 'Result:', 'Optimized Summary:', or any introductory/concluding remarks. Just the text itself."
          : "Topic: $goal. Query: $prompt. Profile: ${jsonEncode(userData)}";
          
      final result = await _callAi(contextPrompt);
      return result?.trim() ?? "No guidance available.";
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
        Return JSON with fields like name, chances, match_analysis, etc.
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
      "steps": ["Step 1: Research requirements", "Step 2: Create a timeline"],
      "google_search_link": "https://www.google.com/search?q=$actionTitle+for+$collegeName"
    };
  }

  @override
  Future<List<Map<String, dynamic>>> searchCollegesByName(String query) async {
    try {
      final prompt = "Search colleges for $query. Return JSON list with name and location.";
      final result = await _callAi(prompt);
      if (result != null) {
        final List<dynamic> decoded = json.decode(_stripMarkdown(result));
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (e) {
      debugPrint("Error in searchCollegesByName: $e");
    }
    return [];
  }

  @override
  Future<String> generateHtmlResume(String base64Image, Map<String, dynamic> userData) async {
    try {
      final prompt = """
        ACT AS A SENIOR WEB DEVELOPER & RESUME DESIGNER.
        
        TASK:
        I have attached an image of a resume template. Analyze its structure, fonts, colors, and layout.
        Recreate this design perfectly using clean HTML and CSS.
        
        Fill the design with this user data:
        ${jsonEncode(userData)}

        CONSTRAINTS:
        1. Output ONLY a single HTML file with internal CSS.
        2. DO NOT use background images; recreate the layout with HTML/CSS.
        3. Match the visual hierarchy of the attached template exactly.
        4. If user data is missing a section that exists in the template, generate professional placeholders.
        5. Output only the code.
        6. Create same style in provided in attachment
      """;
      
      final result = await _callAi(prompt, base64Image: base64Image);
      return _extractHtml(result ?? "<html><body lang='en'>Error generating resume</body></html>");
    } catch (e) {
      debugPrint("Error in generateHtmlResume: $e");
      return "<html><body lang='en'>Exception: $e</body></html>";
    }
  }

  String _extractHtml(String text) {
    if (text.contains("<!DOCTYPE html>") || text.contains("<html")) {
      final start = text.indexOf("<!DOCTYPE html>");
      final startAlt = text.indexOf("<html");
      final startIndex = (start != -1 && (start < startAlt || startAlt == -1)) ? start : startAlt;
      
      final end = text.lastIndexOf("</html>");
      if (startIndex != -1 && end != -1) {
        return text.substring(startIndex, end + 7);
      }
    }
    return text.replaceAll("```html", "").replaceAll("```", "").trim();
  }

  @override
  Future<Map<String, dynamic>> analyzeDocxTemplate(String text) async {
    try {
      final prompt = """
        Identify placeholders (like [NAME], [EMAIL], etc.) in this text:
        $text
        Return ONLY a JSON mapping of field names to the exact placeholders found.
      """;
      final result = await _callAi(prompt);
      if (result != null) return json.decode(_stripMarkdown(result));
    } catch (e) {
      debugPrint("Error in analyzeDocxTemplate: $e");
    }
    return {
      "fullName": "[NAME]",
      "email": "[EMAIL]",
      "phone": "[PHONE]"
    };
  }

  @override
  Future<Map<String, dynamic>> analyzeAndFillTemplate(String base64Image, Map<String, dynamic> userData) async {
    return {};
  }

  String _stripMarkdown(String text) {
    String clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return _sanitizeJson(clean);
  }

  String _sanitizeJson(String jsonString) {
    if (jsonString.isEmpty) return "{}";
    String sanitized = jsonString;
    bool inQuote = false;
    for (int i = 0; i < sanitized.length; i++) {
      if (sanitized[i] == '"' && (i == 0 || sanitized[i - 1] != '\\')) inQuote = !inQuote;
    }
    if (inQuote) sanitized += '"';
    int braceCount = 0;
    int bracketCount = 0;
    inQuote = false;
    for (int i = 0; i < sanitized.length; i++) {
      if (sanitized[i] == '"' && (i == 0 || sanitized[i - 1] != '\\')) inQuote = !inQuote;
      if (!inQuote) {
        if (sanitized[i] == '{') braceCount++;
        if (sanitized[i] == '}') braceCount--;
        if (sanitized[i] == '[') bracketCount++;
        if (sanitized[i] == ']') bracketCount--;
      }
    }
    while (braceCount > 0) { sanitized += '}'; braceCount--; }
    while (bracketCount > 0) { sanitized += ']'; bracketCount--; }
    return sanitized;
  }

  Map<String, dynamic> _trimUserData(Map<String, dynamic> userData) {
    return {
      'fullName': userData['fullName'],
      'weightedGpa': userData['weightedGpa'],
      'skills': (userData['skills'] as List?)?.take(5).toList(),
    };
  }
}

class MockAiService implements AiService {
  @override
  Future<Map<String, dynamic>> getNextSteps(List<String> skills, List<String> interests) async => {};
  @override
  Future<List<Map<String, String>>> getCareerTrajectory(List<String> skills) async => [];
  @override
  Future<String> generateSummary(Map<String, dynamic> userData) async => "";
  @override
  Future<Map<String, dynamic>> getDetailedCareerPlan(Map<String, dynamic> userData, String targetCareer) async => {};
  @override
  Future<Map<String, dynamic>> getSkillResources(String skill, String careerContext) async => {};
  @override
  Future<Map<String, dynamic>> getCareerAnalysis(Map<String, dynamic> userData, String primaryInterest) async => {};
  @override
  Future<List<Map<String, dynamic>>> getNearbyRecommendations(Map<String, dynamic> userData, String category) async => [];
  @override
  Future<Map<String, dynamic>> generatePersonalPlan(String title, String description, List<String> currentSkills, {DateTime? targetCompletionDate}) async => {};
  @override
  Future<Map<String, dynamic>> validateSkillRelevance(String skill, String careerInterest) async => {};
  @override
  Future<String> getPersonalGuidance(String goal, String prompt, Map<String, dynamic> userData) async => "";
  @override
  Future<String> getChatResponse(String userMessage, Map<String, dynamic> userData) async => "";
  @override
  Future<Map<String, dynamic>> getTieredCollegeSuggestions(Map<String, dynamic> userData, {Map<String, dynamic>? preferences}) async => {};
  @override
  Future<Map<String, dynamic>> getSpecificCollegeAdvice(Map<String, dynamic> userData, String collegeName) async => {};
  @override
  Future<Map<String, dynamic>> getTargetActionPlan(String collegeName, String actionTitle, Map<String, dynamic> userData) async => {};
  @override
  Future<List<Map<String, dynamic>>> searchCollegesByName(String query) async => [];
  @override
  Future<Map<String, dynamic>> analyzeAndFillTemplate(String base64Image, Map<String, dynamic> userData) async => {};
  @override
  Future<Map<String, dynamic>> analyzeDocxTemplate(String text) async => {};
  @override
  Future<String> generateHtmlResume(String base64Image, Map<String, dynamic> userData) async => "";
}
