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

  @override
  Future<Map<String, dynamic>> getDetailedCareerPlan(Map<String, dynamic> userData, String targetCareer) async {
    try {
      final String weeklyCommitment = userData['activityPreferences']?['weeklyTimeCommitment'] ?? '1hr default';
      final String targetAchievement = userData['goals']?['targetAchievementLevel'] ?? 'Job';
      
      // Determine number of skills based on target achievement
      int skillCount = 15;
      if (targetAchievement.toLowerCase().contains('job') || targetAchievement.toLowerCase().contains('elite')) {
        skillCount = 25;
      } else if (targetAchievement.toLowerCase().contains('abroad') || targetAchievement.toLowerCase().contains('international')) {
        skillCount = 20;
      }

      final prompt = """
        User Profile: ${jsonEncode(userData)}
        Target Career: $targetCareer
        Weekly Time Commitment: $weeklyCommitment
        Target Achievement Level: $targetAchievement

        Act as an expert career advisor. Analyze the user's projects, skills, and certifications.
        
        CRITICAL GUIDELINES:
        1. Be EXTREMELY polite, positive, and encouraging.
        2. Specifically PRAISE the user for their existing certifications and projects.
        3. For the skills list, provide EXACTLY $skillCount skills relevant to $targetCareer.
        4. RELEVANCE CHECK: Only suggest skills that are actually needed for $targetCareer. If a user has a certification in an unrelated area (e.g., C for Web Development), do not force its inclusion in the roadmap unless it's genuinely useful as a foundation.
        5. PROFILE MATCHING: If a suggested skill is ALREADY in the user's "skills" list (${userData['skills']}), mark "already_in_profile": true.
        6. EXCLUSION RULE: If the user ALREADY has an "Advanced" certification or significant project experience in a suggested skill, DO NOT show an "Add to Roadmap" button for it in the final output (mark "already_mastered": true).
        7. For EACH skill, provide a "justification" explaining why it's crucial for this specific career path.
        8. Return ONLY a valid JSON object.
        
        JSON Structure:
        {
          "achievements": "Summary...",
          "gap_analysis": "Next steps...",
          "steps": [{"title": "Step title", "duration": "Duration"}],
          "timeline": "Total weeks",
          "industry_news": [
            {
              "title": "Brand New Tool/Tech Name",
              "impact": "Explain exactly what is new and why it is a game-changer...",
              "date": "Trending Now"
            }
          ],
          "required_skills": [
            {
              "name": "Skill Name",
              "justification": "Why this skill is important...",
              "already_mastered": false,
              "already_in_profile": false,
              "user_status": "Status update..."
            }
          ]
        }

        AI INSTRUCTIONS FOR NEWS:
        Focus exclusively on 'The Cutting Edge':
        - What brand new libraries, frameworks, or tools were released in the last few months?
        - What emerging technologies (like new AI models or hardware) are currently disrupting this career?
        - Avoid general career advice or generic industry updates.
        - Give the user a 'First Look' at the absolute latest innovations they need to know about.
      """;

      final result = await _callAi(prompt);
      if (result != null) {
        return json.decode(_stripMarkdown(result));
      }
    } catch (e) {
      print("Error in getDetailedCareerPlan: $e");
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getSkillResources(String skill, String careerContext) async {
    try {
      final prompt = """
        Skill: $skill
        Career Context: $careerContext

        Provide a comprehensive list of learning resources for this skill at three levels: Basic, Intermediate, and Advanced.
        Provide at least 5-10 high-quality links for each level where possible.
        
        Return ONLY a raw JSON object with:
        "description": Brief overview of the skill.
        "levels": {
          "Basic": {
            "trainings": [{"title": "Course Name", "link": "url"}],
            "youtube": [{"title": "Video Name", "link": "url"}],
            "docs": [{"title": "Documentation Name", "link": "url"}]
          },
          "Intermediate": { ... },
          "Advanced": { ... }
        }
      """;

      final result = await _callAi(prompt);
      if (result != null) {
        return json.decode(_stripMarkdown(result));
      }
    } catch (e) {
      print("Error in getSkillResources: $e");
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getCareerAnalysis(Map<String, dynamic> userData, String primaryInterest) async {
    try {
      final prompt = """
        User Profile: ${jsonEncode(userData)}
        Primary Career Interest: $primaryInterest

        Act as a supportive and motivating career coach. Analyze the user's current profile in the context of their goal to become a $primaryInterest.

        CRITICAL GUIDELINES:
        1. Be EXTREMELY positive, encouraging, and inspiring.
        2. SKILL GAP ANALYSIS: 
           - Look at userData['skills'] and userData['resourceProgress'].
           - Identify which skills they have already MASTERED or are currently in their profile.
           - Identify which skills they need to IMPROVE or ACQUIRE for $primaryInterest.
        3. Frame "Weaknesses" as "Exciting Growth Milestones" or "Areas to Shine". Never use negative language.
        4. Identify 3-4 "Strengths" where the user is already doing great based on their profile skills.
        5. Identify 3-4 "Areas to Shine" that represent the next steps in their roadmap.
        6. Return ONLY a valid JSON object.

        JSON Structure:
        {
          "strengths": [
            {"title": "Skill/Area Name", "description": "Explain how their existing skill in this area gives them a head start..."}
          ],
          "opportunities": [
            {"title": "Target Skill", "description": "Encouraging explanation of how mastering this specific skill from their roadmap will complete their profile..."}
          ],
          "closing_thought": "A final motivating sentence personalized to $primaryInterest."
        }
      """;

      final result = await _callAi(prompt);
      if (result != null) {
        return json.decode(_stripMarkdown(result));
      }
    } catch (e) {
      print("Error in getCareerAnalysis: $e");
    }
    return MockAiService().getCareerAnalysis(userData, primaryInterest);
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

  @override
  Future<Map<String, dynamic>> getDetailedCareerPlan(Map<String, dynamic> userData, String targetCareer) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      "achievements": "You have a fantastic foundation! It's wonderful that you've already explored several projects. Your dedication is truly inspiring!",
      "gap_analysis": "To reach your goal of being a $targetCareer, we have some exciting new skills to dive into together!",
      "industry_news": [
        {
          "title": "Rise of Generative AI",
          "impact": "New opportunities for developers to integrate AI into existing workflows.",
          "date": "Trending"
        },
        {
          "title": "Remote Work Standards",
          "impact": "Global companies are formalizing long-term hybrid structures.",
          "date": "Recent"
        }
      ],
      "steps": [
        {"title": "Complete specialized certification", "duration": "2 weeks"},
        {"title": "Build a portfolio project", "duration": "3 weeks"}
      ],
      "timeline": "5 weeks",
      "required_skills": [
        {
          "name": "Flutter",
          "justification": "Leading framework for cross-platform apps.",
          "already_mastered": false,
          "already_in_profile": false,
          "user_status": ""
        },
        {
          "name": "Problem Solving",
          "justification": "Essential for any high-level career.",
          "already_mastered": true,
          "already_in_profile": true,
          "user_status": "Your work on previous projects shows you're a natural!"
        }
      ]
    };
  }

  @override
  Future<Map<String, dynamic>> getSkillResources(String skill, String careerContext) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      "description": "Mastering $skill is a brilliant move for your journey towards becoming a $careerContext!",
      "trainings": [{"title": "$skill Mastery Course", "link": "https://udemy.com"}],
      "youtube": [{"title": "$skill Explained simply", "link": "https://youtube.com"}],
      "docs": [{"title": "Official $skill Documentation", "link": "https://docs.com"}]
    };
  }

  @override
  Future<Map<String, dynamic>> getCareerAnalysis(Map<String, dynamic> userData, String primaryInterest) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      "strengths": [
        {"title": "Foundational Knowledge", "description": "You have a solid start in your journey!"},
        {"title": "Dedication", "description": "Your commitment to learning is truly inspiring!"}
      ],
      "opportunities": [
        {"title": "Practical Projects", "description": "Building more things will make you shine even brighter!"},
        {"title": "Networking", "description": "Connecting with others will open up amazing new doors!"}
      ],
      "closing_thought": "You have everything it takes to succeed as a $primaryInterest!"
    };
  }
}
