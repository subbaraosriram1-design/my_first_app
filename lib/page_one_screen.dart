import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'ai_service.dart';

class PageOneScreen extends StatefulWidget {
  const PageOneScreen({super.key});

  @override
  State<PageOneScreen> createState() => _PageOneScreenState();
}

class _PageOneScreenState extends State<PageOneScreen> {
  final AiService _aiService = GroqAiService();
  Map<String, dynamic>? _recommendations;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAiRecommendations();
  }

  Future<void> _fetchAiRecommendations() async {
    try {
      final userId = FirebaseService.instance.currentUserId;
      if (userId == null) throw Exception("User not logged in");

      final userData = await FirebaseService.instance.getResume(userId);
      if (userData == null) throw Exception("No profile data found");

      List<String> skills = [];
      if (userData['skills'] is List) {
        skills = (userData['skills'] as List).map((s) {
          if (s is Map) return s['name']?.toString() ?? s['skill']?.toString() ?? '';
          return s.toString();
        }).where((s) => s.isNotEmpty).toList();
      }

      List<String> interests = [];
      if (userData['hobbies'] is List) {
        interests = (userData['hobbies'] as List).map((e) => e.toString()).toList();
      }
      
      if (userData['careerInterests'] is List) {
        interests.addAll((userData['careerInterests'] as List).map((e) => e.toString()));
      }

      if (skills.isEmpty && interests.isEmpty) {
        skills = ['Software Development', 'Problem Solving'];
        interests = ['Technology', 'AI'];
      }

      final result = await _aiService.getNextSteps(skills, interests);
      
      if (mounted) {
        setState(() {
          _recommendations = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Next Steps', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF5B3FD8)),
                  const SizedBox(height: 20),
                  Text(
                    'Grok AI is analyzing your profile...',
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _fetchAiRecommendations();
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildSectionCard(
                        'General Suggestion',
                        _recommendations?['suggestion'] ?? 'No suggestion available.',
                        Icons.lightbulb_outline,
                        const Color(0xFF5B3FD8),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        'Recommended Course',
                        _recommendations?['course'] ?? 'No course recommended.',
                        Icons.school_outlined,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        'Project Idea',
                        _recommendations?['project'] ?? 'No project idea available.',
                        Icons.code,
                        const Color(0xFFF97316),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personalized for You',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your unique combination of skills and interests.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, String content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 15,
              height: 1.5,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
