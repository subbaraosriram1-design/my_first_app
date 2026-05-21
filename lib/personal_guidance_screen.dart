import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_service.dart';
import 'firebase_service.dart';

class PersonalGuidanceScreen extends StatefulWidget {
  const PersonalGuidanceScreen({super.key});

  @override
  State<PersonalGuidanceScreen> createState() => _PersonalGuidanceScreenState();
}

class _PersonalGuidanceScreenState extends State<PersonalGuidanceScreen> {
  final AiService _aiService = GroqAiService();
  bool _isLoading = false;
  String? _guidanceContent;
  String? _selectedGoal;

  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Get Good Scores',
      'icon': Icons.grade,
      'color': const Color(0xFF6366F1),
      'prompt': 'Provide detailed AI strategies, study techniques, and resource suggestions for a student aiming to achieve top scores in their upcoming academic exams.'
    },
    {
      'title': 'College Admission',
      'icon': Icons.account_balance,
      'color': const Color(0xFF10B981),
      'prompt': 'Provide a comprehensive AI guide on the college admission process, including application tips, essay strategies, and how to build a strong candidate profile.'
    },
    {
      'title': 'Choose Best Course',
      'icon': Icons.menu_book,
      'color': const Color(0xFFF59E0B),
      'prompt': 'Help a student choose the best academic course or major based on future market trends, career stability, and personal growth potential.'
    },
    {
      'title': 'Professional Skills',
      'icon': Icons.handyman,
      'color': const Color(0xFFEC4899),
      'prompt': 'Identify and explain the top professional and soft skills required in the current job market, and provide advice on how to master them effectively.'
    },
  ];

  Future<void> _getGuidance(String goal, String prompt) async {
    setState(() {
      _isLoading = true;
      _selectedGoal = goal;
      _guidanceContent = null;
    });

    try {
      final userId = FirebaseService.instance.currentUserId;
      final userData = await FirebaseService.instance.getResume(userId ?? "");
      
      final response = await _aiService.getPersonalGuidance(goal, prompt, userData ?? {});
      
      if (mounted) {
        setState(() {
          _guidanceContent = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _guidanceContent = "Error fetching guidance: $e";
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
        title: Text('Personal Guidance', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
        : _guidanceContent != null 
          ? _buildGuidanceView()
          : _buildGoalSelection(),
    );
  }

  Widget _buildGoalSelection() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return GestureDetector(
          onTap: () => _getGuidance(goal['title'], goal['prompt']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: goal['color'].withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: goal['color'].withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goal['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(goal['icon'], color: goal['color'], size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    goal['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuidanceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _guidanceContent = null),
              ),
              Text(
                _selectedGoal!,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              _guidanceContent!,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.6, color: const Color(0xFF334155)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => setState(() => _guidanceContent = null),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back to Goals', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
