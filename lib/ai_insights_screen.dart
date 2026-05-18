import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'career_selection_screen.dart';
import 'page_two_screen.dart';
import 'firebase_service.dart';
import 'ai_service.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  final AiService _aiService = GroqAiService();
  List<String> _interests = [];
  String? _activeInterest;
  String? _tempSelectedInterest;
  bool _isLoading = true;
  bool _isAnalysisLoading = false;
  bool _isChangingFocus = false;
  Map<String, dynamic>? _careerAnalysis;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (mounted) {
        setState(() {
          _interests = List<String>.from(data?['careerInterests'] ?? []);
          _activeInterest = data?['activeCareerInterest'];
          _isLoading = false;
        });

        if (_activeInterest != null && data != null) {
          _fetchCareerAnalysis(data, _activeInterest!);
        }
      }
    }
  }

  Future<void> _fetchCareerAnalysis(Map<String, dynamic> userData, String interest) async {
    setState(() => _isAnalysisLoading = true);
    try {
      final analysis = await _aiService.getCareerAnalysis(userData, interest);
      if (mounted) {
        setState(() {
          _careerAnalysis = analysis;
          _isAnalysisLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching analysis: $e");
      if (mounted) setState(() => _isAnalysisLoading = false);
    }
  }

  Future<void> _updatePrimaryInterest(String interest) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      setState(() => _isLoading = true);
      await FirebaseService.instance.saveResume(userId, {'activeCareerInterest': interest});
      
      final userData = await FirebaseService.instance.getResume(userId);

      if (mounted) {
        setState(() {
          _activeInterest = interest;
          _isLoading = false;
        });
        
        if (userData != null) {
          _fetchCareerAnalysis(userData, interest);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Primary interest updated to $interest'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('AI Insights', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Career Intelligence',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Powered by Grok AI to help you navigate your professional journey.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildPrimarySkillCard(),
                  const SizedBox(height: 24),
                  _buildAnalysisSection(),
                  const SizedBox(height: 32),
                  _buildInsightCard(
                    context,
                    title: 'What to do next',
                    description: 'Personalized course and project recommendations based on your skills.',
                    icon: Icons.auto_awesome,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CareerSelectionScreen()),
                    ).then((_) => _loadUserData()),
                  ),
                  const SizedBox(height: 20),
                  _buildInsightCard(
                    context,
                    title: 'Career Trajectory',
                    description: 'Visualize your potential career path and growth stages.',
                    icon: Icons.trending_up,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PageTwoScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPrimarySkillCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Primary Focus',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (!_isChangingFocus)
                TextButton(
                  onPressed: () => setState(() {
                    _isChangingFocus = true;
                    _tempSelectedInterest = _activeInterest;
                  }),
                  child: Text(
                    'Change',
                    style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isChangingFocus) ...[
            Text(
              _activeInterest ?? 'No primary interest set',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your roadmap and analysis are tailored to this path.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withAlpha(150)),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(40)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  value: _interests.contains(_tempSelectedInterest) ? _tempSelectedInterest : null,
                  hint: Text('Select focus', style: GoogleFonts.poppins(color: Colors.white.withAlpha(150))),
                  iconEnabledColor: Colors.white,
                  items: _interests.map((interest) {
                    return DropdownMenuItem<String>(
                      value: interest,
                      child: Text(interest, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _tempSelectedInterest = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isChangingFocus = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _tempSelectedInterest == null
                        ? null
                        : () {
                            _updatePrimaryInterest(_tempSelectedInterest!);
                            setState(() => _isChangingFocus = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    if (_isAnalysisLoading) {
      return Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF5B3FD8)),
            const SizedBox(height: 16),
            Text('Analyzing your profile...', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    if (_careerAnalysis == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personalized Analysis',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildAnalysisCategory(
          title: 'Your Strengths',
          items: List<Map<String, dynamic>>.from(_careerAnalysis!['strengths'] ?? []),
          icon: Icons.check_circle,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 24),
        _buildAnalysisCategory(
          title: 'Opportunities to Shine',
          items: List<Map<String, dynamic>>.from(_careerAnalysis!['opportunities'] ?? []),
          icon: Icons.lightbulb,
          color: Colors.orange,
        ),
        if (_careerAnalysis!['closing_thought'] != null) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF5B3FD8).withAlpha(10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF5B3FD8).withAlpha(30)),
            ),
            child: Text(
              _careerAnalysis!['closing_thought'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5B3FD8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalysisCategory({
    required String title,
    required List<Map<String, dynamic>> items,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withAlpha(150), size: 16),
          ],
        ),
      ),
    );
  }
}
