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
  Future<Map<String, dynamic>> getCollegeSuggestions(Map<String, dynamic> userData);
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
  Future<Map<String, dynamic>> getCollegeSuggestions(Map<String, dynamic> userData) async {
    try {
      final prompt = """
        User Profile: ${jsonEncode(userData)}
        
        Provide an EXTREMELY detailed analysis of the user's profile based on Top 50-60 US College admission standards.
        Return a JSON object with:
        1. "strengths": A list of objects with "title" and "detailed_explanation" (explain WHY this is a strength for Top 50-60 schools).
        2. "weaknesses": A list of objects with "title" and "detailed_explanation" (explain the impact of this gap and how it hurts Top 50-60 chances).
        3. "suggestions": A list of 5 suitable US colleges with "name", "location", "match_reason", "how_to_achieve", "suitable_courses", and "match_percentage".
        4. "top_60_roadmap": A list of 5-6 very specific, granular milestones needed to be competitive for Top 50-60 ranked institutions (e.g., specific GPA targets, extracurricular depth, and testing strategy).

        Return ONLY a raw JSON object. Do not include markdown code blocks or additional text.
      """;

      final result = await _callAi(prompt);
      if (result != null) {
        return json.decode(_stripMarkdown(result));
      }
    } catch (e) {
      print("Error in getCollegeSuggestions: $e");
    }
    return MockAiService().getCollegeSuggestions(userData);
  }

  @override
  Future<Map<String, dynamic>> getSpecificCollegeAdvice(Map<String, dynamic> userData, String collegeName) async {
    try {
      final prompt = """
        User Profile: ${jsonEncode(userData)}
        College: $collegeName
        Provide an exhaustive, multi-dimensional admission blueprint for $collegeName. 
        Meticulously reference the Common Data Set (CDS) for $collegeName.
        Return a JSON object with:
        - "name": $collegeName
        - "match_analysis": A deep, paragraph-length analysis of how their profile fits this specific institution.
        - "academic_strategy": Specific advice on course rigor, weighted vs unweighted GPA priorities, and standardized testing timing.
        - "action_plan": A comprehensive, step-by-step roadmap for the next 12-24 months.
        - "chances": (Reach/Match/Safety).
        - "holistic_narrative": How the user should position their unique "hook" or personal story in their application to this college.
        - "suggested_extracurriculars": High-impact activities that specifically align with this college's values.
        - "cds_insight": A critical data point from the most recent CDS.
        
        Return ONLY a raw JSON object. Do not include markdown code blocks or additional text.
      """;

      final result = await _callAi(prompt);
      if (result != null) {
        return json.decode(_stripMarkdown(result));
      }
    } catch (e) {
      print("Error in getSpecificCollegeAdvice: $e");
    }
    return MockAiService().getSpecificCollegeAdvice(userData, collegeName);
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
  Future<Map<String, dynamic>> getCollegeSuggestions(Map<String, dynamic> userData) async {
    return {
      "strengths": [
        {
          "title": "Strong weighted GPA (4.2)",
          "detailed_explanation": "A 4.2 weighted GPA places you in the top decile for many Top 50 schools. In the CDS Section C9, academic rigor and GPA are consistently rated as 'Very Important', making this your primary competitive anchor."
        },
        {
          "title": "STEM Extracurricular Depth",
          "detailed_explanation": "Your consistent involvement in AI and CS projects demonstrates 'Talent/Ability', a key holistic factor in CDS C7. This proves you have more than just grades; you have applied skills that Top 60 schools value for their incoming class diversity."
        }
      ],
      "weaknesses": [
        {
          "title": "Lack of National-Level Awards",
          "detailed_explanation": "While your local projects are strong, Top 50 colleges look for external validation. Without national awards (like AP Scholar with Distinction or Science Fair state wins), it's harder to stand out in the 'Exceptional Talent' category."
        },
        {
          "title": "Unweighted GPA Discrepancy",
          "detailed_explanation": "A significant gap between weighted and unweighted GPA can signal to admissions that you are excelling in APs but might have struggled in foundational courses. Schools like those in the Top 60 prioritize consistent high performance across all subjects."
        }
      ],
      "suggestions": [
        {
          "name": "Stanford University",
          "location": "Stanford, CA",
          "match_reason": "Stanford values high academic rigor and intellectual vitality. Your 4.2 GPA and AI focus align perfectly with their 'Very Important' criteria in CDS C7.",
          "how_to_achieve": "Maintain your GPA, lead an AI club, and aim for a 1560+ SAT to match their 75th percentile benchmarks.",
          "suitable_courses": ["Computer Science", "Artificial Intelligence", "Symbolic Systems"],
          "match_percentage": 95
        }
      ],
      "top_60_roadmap": [
        "Reach and maintain a 4.0 unweighted GPA in your junior year.",
        "Secure at least two leadership positions in major school organizations.",
        "Enter and place in a state or national-level competition relevant to your major.",
        "Complete 100+ hours of community service with a clear leadership impact.",
        "Achieve an SAT score of 1500+ or ACT of 34+ to be above the 50th percentile for Top 60 schools."
      ]
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
