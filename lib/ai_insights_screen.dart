import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'career_selection_screen.dart';
import 'page_two_screen.dart';
import 'nearby_you_screen.dart';
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
      setState(() {
        _isAnalysisLoading = true;
        _activeInterest = interest;
      });
      
      await FirebaseService.instance.saveResume(userId, {'activeCareerInterest': interest});
      
      final userData = await FirebaseService.instance.getResume(userId);

      if (mounted) {
        if (userData != null) {
          // Fetch both analysis AND initial roadmap plan (to cache news/sync/skills)
          await Future.wait([
            _fetchCareerAnalysis(userData, interest),
            _triggerRoadmapCreation(userData, interest),
          ]);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Focus updated! Your analysis and roadmap are now optimized for $interest.'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false, arguments: 1);
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _triggerRoadmapCreation(Map<String, dynamic> userData, String career) async {
    try {
      // 1. Generate the detailed plan
      final plan = await _aiService.getDetailedCareerPlan(userData, career);
      
      final Map<String, dynamic> updateData = {};
      
      // 2. Cache the full plan for instant loading in CareerPlanScreen
      final currentPlans = Map<String, dynamic>.from(userData['careerPlans'] ?? {});
      currentPlans[career] = plan;
      updateData['careerPlans'] = currentPlans;

      // 3. Update Industry News
      if (plan['industry_news'] != null) {
        final currentNews = Map<String, dynamic>.from(userData['careerNews'] ?? {});
        currentNews[career] = plan['industry_news'];
        updateData['careerNews'] = currentNews;
      }
      
      // 4. Automatically update the Roadmap with recommended skills (Merge, don't overwrite)
      if (plan['required_skills'] != null) {
        final List<dynamic> suggestedSkills = plan['required_skills'] is List ? plan['required_skills'] : [];
        final Map<String, dynamic> careerRoadmaps = Map<String, dynamic>.from(userData['careerRoadmaps'] ?? {});
        final Map<String, dynamic> deletedSkills = Map<String, dynamic>.from(userData['deletedSkills'] ?? {});
        
        List<String> currentRoadmap = List<String>.from(careerRoadmaps[career] ?? []);
        List<String> deletedList = List<String>.from(deletedSkills[career] ?? []);

        final List<String> newSkillNames = suggestedSkills
            .whereType<Map>()
            .where((s) => s['already_mastered'] != true)
            .map((s) => s['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        for (var skill in newSkillNames) {
          if (!currentRoadmap.contains(skill) && !deletedList.contains(skill)) {
            currentRoadmap.add(skill);
          }
        }
            
        careerRoadmaps[career] = currentRoadmap;
        updateData['careerRoadmaps'] = careerRoadmaps;
      }

      // 5. Save everything to Firestore
      if (updateData.isNotEmpty) {
        await FirebaseService.instance.saveResume(FirebaseService.instance.currentUserId!, updateData);
      }
    } catch (e) {
      debugPrint("Roadmap creation background task failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('AI Insights', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 16 : 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Career Intelligence',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Powered by Grok AI to help you navigate your professional journey.',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildPrimarySkillCard(isSmallScreen),
                  const SizedBox(height: 24),
                  _buildAnalysisSection(isSmallScreen),
                  const SizedBox(height: 32),
                  _buildInsightCard(
                    context,
                    title: 'What to do next',
                    description: 'Personalized course and project recommendations based on your skills.',
                    icon: Icons.auto_awesome,
                    isSmallScreen: isSmallScreen,
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
                  const SizedBox(height: 16),
                  _buildInsightCard(
                    context,
                    title: 'Career Trajectory',
                    description: 'Visualize your potential career path and growth stages.',
                    icon: Icons.trending_up,
                    isSmallScreen: isSmallScreen,
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
                  const SizedBox(height: 20),
                  _buildInsightCard(
                    context,
                    title: 'Nearby You',
                    description: 'AI-generated jobs, internships, events, and more near your location.',
                    icon: Icons.location_on,
                    isSmallScreen: isSmallScreen,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NearbyYouScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPrimarySkillCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
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
                  fontSize: isSmallScreen ? 14 : 16,
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
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(
                    'Change',
                    style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isChangingFocus) ...[
            Text(
              _activeInterest ?? 'No primary interest set',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your roadmap and analysis are tailored to this path.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withAlpha(150)),
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
                  hint: Text('Select focus', style: GoogleFonts.poppins(color: Colors.white.withAlpha(150), fontSize: 13)),
                  iconEnabledColor: Colors.white,
                  items: _interests.map((interest) {
                    return DropdownMenuItem<String>(
                      value: interest,
                      child: Text(interest, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(bool isSmallScreen) {
    if (_isAnalysisLoading) {
      return Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            Text('Analyzing your profile...', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      );
    }

    if (_careerAnalysis == null) return const SizedBox.shrink();

    // Safe casting for strengths and opportunities
    List<Map<String, dynamic>> strengths = [];
    if (_careerAnalysis!['strengths'] is List) {
      strengths = (_careerAnalysis!['strengths'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    List<Map<String, dynamic>> opportunities = [];
    if (_careerAnalysis!['opportunities'] is List) {
      opportunities = (_careerAnalysis!['opportunities'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personalized Analysis',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildAnalysisCategory(
          title: 'Your Strengths',
          items: strengths,
          icon: Icons.check_circle,
          color: const Color(0xFF10B981),
          isSmallScreen: isSmallScreen,
        ),
        const SizedBox(height: 24),
        _buildAnalysisCategory(
          title: 'Opportunities to Shine',
          items: opportunities,
          icon: Icons.lightbulb,
          color: Colors.orange,
          isSmallScreen: isSmallScreen,
        ),
        if (_careerAnalysis!['closing_thought'] != null) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(30)),
            ),
            child: Text(
              _careerAnalysis!['closing_thought'].toString(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF065F46),
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
    required bool isSmallScreen,
  }) {
    final bool isStrength = color == const Color(0xFF10B981);
    final Color bgColor = isStrength ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
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
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _ExpandableAnalysisCard(item: item, color: color)),
      ],
    );
  }
}

class _ExpandableAnalysisCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Color color;

  const _ExpandableAnalysisCard({required this.item, required this.color});

  @override
  State<_ExpandableAnalysisCard> createState() => _ExpandableAnalysisCardState();
}

class _ExpandableAnalysisCardState extends State<_ExpandableAnalysisCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isStrength = widget.color == const Color(0xFF10B981);
    final Color bgColor = isStrength ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isExpanded ? widget.color.withValues(alpha: 0.2) : Colors.grey.shade100, width: _isExpanded ? 1.5 : 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
          title: Text(
            widget.item['title'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          iconColor: widget.color,
          collapsedIconColor: Colors.grey.shade400,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item['description'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildInsightCard(
  BuildContext context, {
  required String title,
  required String description,
  required IconData icon,
  required Gradient gradient,
  required VoidCallback onTap,
  required bool isSmallScreen,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
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
            child: Icon(icon, color: Colors.white, size: isSmallScreen ? 24 : 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 13,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white.withAlpha(150), size: 14),
        ],
      ),
    ),
  );
}
