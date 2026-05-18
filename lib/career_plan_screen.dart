import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_service.dart';
import 'firebase_service.dart';
import 'roadmap_screen.dart';

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

  Future<void> _fetchPlan() async {
    try {
      final userId = FirebaseService.instance.currentUserId;
      if (userId == null) throw Exception("User not logged in");

      final userData = await FirebaseService.instance.getResume(userId);
      if (userData == null) throw Exception("No profile data found");

      final plan = await _aiService.getDetailedCareerPlan(userData, widget.targetCareer);
      
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });

        // AUTO-SAVE news when plan is generated to ensure it shows in Roadmap tab
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
      
      // Structure: { "Software Engineer": ["Flutter", "Dart"], "Data Scientist": ["Python"] }
      Map<String, dynamic> careerRoadmaps = Map<String, dynamic>.from(userData?['careerRoadmaps'] ?? {});
      List<String> roadmap = List<String>.from(careerRoadmaps[widget.targetCareer] ?? []);
      
      if (!roadmap.contains(skill)) {
        roadmap.add(skill);
        careerRoadmaps[widget.targetCareer] = roadmap;
        
        // Also save the trending news for the active career so it shows in the Roadmap tab
        final updateData = {
          'careerRoadmaps': careerRoadmaps,
        };
        
        if (_plan != null && _plan!['industry_news'] != null) {
          updateData['careerNews'] = {
            widget.targetCareer: _plan!['industry_news']
          };
        }

        await FirebaseService.instance.saveResume(userId, updateData);
        if (mounted) {
          setState(() {}); // Refresh to reflect "Added to Roadmap"
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fantastic choice! $skill has been added to your ${widget.targetCareer} Roadmap!'),
              backgroundColor: const Color(0xFF10B981),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService.instance.getResume(FirebaseService.instance.currentUserId!),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final careerRoadmaps = Map<String, dynamic>.from(userData?['careerRoadmaps'] ?? {});
        final activeRoadmap = List<String>.from(careerRoadmaps[widget.targetCareer] ?? []);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('Your Personalized Journey', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF5B3FD8)),
                      const SizedBox(height: 20),
                      Text(
                        'AI is crafting your inspiring plan...',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : _error != null
                  ? Center(child: Text(_error!))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTargetHeader(),
                          const SizedBox(height: 32),
                          _buildCurrentRoadmapSection(activeRoadmap), 
                          const SizedBox(height: 32),
                          _buildSection('Your Amazing Progress', _plan?['achievements'], Icons.star, Colors.orange),
                          const SizedBox(height: 24),
                          _buildSection('Exciting Next Steps', _plan?['gap_analysis'], Icons.lightbulb, const Color(0xFF5B3FD8)),
                          const SizedBox(height: 24),
                          _buildTimelineSection(),
                          const SizedBox(height: 24),
                          _buildStepsSection(),
                          const SizedBox(height: 32),
                          Text(
                            'Skills to Explore',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a skill to add it to your specialized roadmap.',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          _buildSkillsList(activeRoadmap),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withAlpha(30)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currentSkills.map((skill) => Chip(
              label: Text(skill, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF065F46))),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF10B981)),
              onDeleted: () async {
                // Optional: Allow deleting from history
              },
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsList(List<String> activeRoadmap) {
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
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAlreadyInProfile ? const Color(0xFF8B5CF6).withAlpha(40) : Colors.grey.shade100,
              width: isAlreadyInProfile ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: CircleAvatar(
              backgroundColor: isAlreadyInProfile 
                  ? const Color(0xFF8B5CF6).withAlpha(20) 
                  : const Color(0xFF5B3FD8).withAlpha(10),
              child: isAlreadyInProfile 
                  ? const Icon(Icons.sync, color: Color(0xFF8B5CF6), size: 18)
                  : Text('${index + 1}', style: const TextStyle(color: Color(0xFF5B3FD8), fontWeight: FontWeight.bold)),
            ),
            title: Row(
              children: [
                Expanded(child: Text(skillName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15))),
                if (isAlreadyInProfile)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withAlpha(20), borderRadius: BorderRadius.circular(4)),
                    child: Text('In Profile', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: userStatus.isNotEmpty 
                ? Text(userStatus, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.w500))
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      justification,
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    if (isAlreadyMastered)
                      _buildStatusContainer('Mastered! No roadmap needed.', const Color(0xFF10B981))
                    else if (isAlreadyInRoadmap)
                      _buildStatusContainer(
                        isAlreadyInProfile ? 'Already in Profile (Continuing)' : 'Added to Roadmap', 
                        isAlreadyInProfile ? const Color(0xFF8B5CF6) : const Color(0xFF5B3FD8)
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _addSkillToRoadmap(skillName),
                          icon: Icon(isAlreadyInProfile ? Icons.sync : Icons.add, size: 18),
                          label: Text(isAlreadyInProfile ? 'Sync & Continue' : 'Add to Roadmap'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAlreadyInProfile ? const Color(0xFF8B5CF6) : const Color(0xFF5B3FD8),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 13, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 10)),
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
                child: const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TARGET CAREER',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withAlpha(180), fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    Text(
                      widget.targetCareer,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
            icon: const Icon(Icons.map_outlined, size: 20),
            label: Text('View My Learning Roadmap', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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

  Widget _buildSection(String title, String? content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                title, 
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color)
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content ?? 'Analyzing your great potential...', 
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade800, height: 1.6)
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Estimated Time:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Text(
            _plan?['timeline'] ?? 'N/A',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF5B3FD8), fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    final steps = _plan?['steps'] as List?;
    if (steps == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommended Roadmap Steps', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
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
            child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title ?? '', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                if (duration != null)
                  Text('Duration: $duration', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
