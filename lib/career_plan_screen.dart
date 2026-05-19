import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_service.dart';
import 'firebase_service.dart';
import 'roadmap_screen.dart';
import 'roadmap_view_screen.dart';

class CareerPlanScreen extends StatefulWidget {
  final String targetCareer;
  const CareerPlanScreen({super.key, required this.targetCareer});

  @override
  State<CareerPlanScreen> createState() => _CareerPlanScreenState();
}

class _CareerPlanScreenState extends State<CareerPlanScreen> {
  final AiService _aiService = GroqAiService();
  bool _isLoading = true;
  Map<String, dynamic>? _plan;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlan();
  }

  Future<void> _fetchPlan({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseService.instance.currentUserId;
      if (userId == null) throw Exception("User not logged in");

      final userData = await FirebaseService.instance.getResume(userId);
      if (userData == null) throw Exception("No profile data found");

      final cachedPlans = userData['careerPlans'] as Map<String, dynamic>?;
      Map<String, dynamic>? plan;

      if (!forceRefresh && cachedPlans != null && cachedPlans.containsKey(widget.targetCareer)) {
        plan = Map<String, dynamic>.from(cachedPlans[widget.targetCareer]);
      } else {
        plan = await _aiService.getDetailedCareerPlan(userData, widget.targetCareer);
        final currentPlans = Map<String, dynamic>.from(userData['careerPlans'] ?? {});
        currentPlans[widget.targetCareer] = plan;
        
        // AUTOMATICALLY add ALL skills to roadmap by default
        final Map<String, dynamic> careerRoadmaps = Map<String, dynamic>.from(userData['careerRoadmaps'] ?? {});
        final List<String> requiredSkills = (plan['required_skills'] as List?)
            ?.map((s) => s['name'].toString())
            .toList() ?? [];
        
        careerRoadmaps[widget.targetCareer] = requiredSkills;

        // Ensure career is in interests
        List<String> interests = List<String>.from(userData['careerInterests'] ?? []);
        if (!interests.contains(widget.targetCareer)) {
          interests.add(widget.targetCareer);
        }

        await FirebaseService.instance.saveResume(userId, {
          'careerPlans': currentPlans,
          'careerRoadmaps': careerRoadmaps,
          'careerInterests': interests,
        });
      }
      
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });

        if (plan['industry_news'] != null) {
          final currentNews = Map<String, dynamic>.from(userData['careerNews'] ?? {});
          currentNews[widget.targetCareer] = plan['industry_news'];
          await FirebaseService.instance.saveResume(userId, {'careerNews': currentNews});
        }
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

  Future<void> _addSkillToRoadmap(String skill) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final userData = await FirebaseService.instance.getResume(userId);
      Map<String, dynamic> careerRoadmaps = Map<String, dynamic>.from(userData?['careerRoadmaps'] ?? {});
      List<String> roadmap = List<String>.from(careerRoadmaps[widget.targetCareer] ?? []);
      
      if (!roadmap.contains(skill)) {
        roadmap.add(skill);
        careerRoadmaps[widget.targetCareer] = roadmap;
        
        final updateData = {'careerRoadmaps': careerRoadmaps};
        if (_plan != null && _plan!['industry_news'] != null) {
          updateData['careerNews'] = {widget.targetCareer: _plan!['industry_news']};
        }

        await FirebaseService.instance.saveResume(userId, updateData);
        if (mounted) {
          setState(() {}); 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fantastic choice! $skill has been added to your Roadmap!'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RoadmapScreen(skill: skill, careerContext: widget.targetCareer)),
        ).then((_) => setState(() {}));
      }
    }
  }

  Future<void> _setAsPrimaryFocus() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseService.instance.currentUserId;
      if (userId == null) return;

      await FirebaseService.instance.saveResume(userId, {
        'activeCareerInterest': widget.targetCareer,
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => RoadmapViewScreen(targetCareer: widget.targetCareer)),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService.instance.getResume(FirebaseService.instance.currentUserId!),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final careerRoadmaps = Map<String, dynamic>.from(userData?['careerRoadmaps'] ?? {});
        final activeRoadmap = List<String>.from(careerRoadmaps[widget.targetCareer] ?? []);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('Your Personalized Journey', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 16 : 18)),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
                onPressed: () => _fetchPlan(forceRefresh: true),
                tooltip: 'Refresh AI Plan',
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF10B981)),
                      const SizedBox(height: 20),
                      Text(
                        'AI is crafting your inspiring plan...',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : _error != null
                  ? Center(child: Text(_error!, style: GoogleFonts.poppins()))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTargetHeader(isSmallScreen),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _setAsPrimaryFocus,
                              icon: const Icon(Icons.star, color: Colors.white, size: 18),
                              label: Text('Set as Primary Focus', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildCurrentRoadmapSection(activeRoadmap), 
                          const SizedBox(height: 32),
                          _buildSection('Your Amazing Progress', _plan?['achievements'], Icons.star, Colors.orange, isSmallScreen),
                          const SizedBox(height: 24),
                          _buildSection('Exciting Next Steps', _plan?['gap_analysis'], Icons.lightbulb, const Color(0xFF10B981), isSmallScreen),
                          const SizedBox(height: 24),
                          _buildTimelineSection(isSmallScreen),
                          const SizedBox(height: 24),
                          _buildStepsSection(isSmallScreen),
                          const SizedBox(height: 32),
                          Text(
                            'Skills to Explore',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a skill to add it to your specialized roadmap.',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          _buildSkillsList(activeRoadmap, isSmallScreen),
                        ],
                      ),
                    ),
        );
      }
    );
  }

  Widget _buildCurrentRoadmapSection(List<String> currentSkills) {
    if (currentSkills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your ${widget.targetCareer} History',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currentSkills.map((skill) => Chip(
              label: Text(skill, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF065F46), fontWeight: FontWeight.w500)),
              backgroundColor: Colors.white,
              elevation: 0,
              side: const BorderSide(color: Color(0xFF10B981), width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsList(List<String> activeRoadmap, bool isSmallScreen) {
    final skills = _plan?['required_skills'] as List?;
    if (skills == null) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skillData = skills[index] as Map<String, dynamic>;
        final String skillName = skillData['name'] ?? 'Skill';
        final String justification = skillData['justification'] ?? '';
        final String userStatus = skillData['user_status'] ?? '';
        
        final bool isAlreadyInRoadmap = activeRoadmap.contains(skillName);
        final bool isAlreadyInProfile = skillData['already_in_profile'] == true;
        final bool isAlreadyMastered = skillData['already_mastered'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAlreadyInProfile ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.grey.shade100,
              width: isAlreadyInProfile ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: isAlreadyInProfile 
                  ? const Color(0xFF10B981).withValues(alpha: 0.1) 
                  : const Color(0xFF1E293B).withValues(alpha: 0.05),
              radius: 18,
              child: isAlreadyInProfile 
                  ? const Icon(Icons.check, color: Color(0xFF10B981), size: 16)
                  : Text('${index + 1}', style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            title: Row(
              children: [
                Expanded(child: Text(skillName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14))),
                if (isAlreadyInProfile)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('PRO', style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: userStatus.isNotEmpty 
                ? Text(userStatus, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.w500))
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text(
                      justification,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    if (isAlreadyMastered)
                      _buildStatusContainer('Mastered! No roadmap needed.', const Color(0xFF10B981))
                    else if (isAlreadyInRoadmap)
                      _buildStatusContainer(
                        isAlreadyInProfile ? 'In Profile (Continuing)' : 'Added to Roadmap', 
                        const Color(0xFF10B981)
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _addSkillToRoadmap(skillName),
                          icon: Icon(isAlreadyInProfile ? Icons.sync : Icons.add, size: 16),
                          label: Text(isAlreadyInProfile ? 'Sync & Continue' : 'Add to Roadmap', style: const TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusContainer(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetHeader(bool isSmallScreen) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.rocket_launch, color: Colors.white, size: isSmallScreen ? 24 : 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TARGET CAREER',
                      style: GoogleFonts.poppins(fontSize: 9, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    Text(
                      widget.targetCareer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false, arguments: 1);
            },
            icon: const Icon(Icons.map_outlined, size: 18),
            label: Text('View My Roadmap', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String? content, IconData icon, Color color, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title, 
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: color)
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content ?? 'Analyzing your potential...', 
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800, height: 1.6)
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Estimated Time:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(
            _plan?['timeline'] ?? 'N/A',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF10B981), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(bool isSmallScreen) {
    final steps = _plan?['steps'] as List?;
    if (steps == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommended Roadmap Steps', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ...steps.map((step) => _buildStepItem(step['title'], step['duration'])),
      ],
    );
  }

  Widget _buildStepItem(String? title, String? duration) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B))),
                if (duration != null)
                  Text('Duration: $duration', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
