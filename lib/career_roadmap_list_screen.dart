import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'roadmap_view_screen.dart';

class CareerRoadmapListScreen extends StatefulWidget {
  const CareerRoadmapListScreen({super.key});

  @override
  State<CareerRoadmapListScreen> createState() => _CareerRoadmapListScreenState();
}

class _CareerRoadmapListScreenState extends State<CareerRoadmapListScreen> {
  bool _isLoading = true;
  List<String> _careers = [];
  Map<String, dynamic> _resumeData = {};
  final List<Color> _lightColors = [
    const Color(0xFFF0F9FF), // Light Blue
    const Color(0xFFF0FDF4), // Light Green
    const Color(0xFFFFF7ED), // Light Orange
    const Color(0xFFFEF2F2), // Light Red
    const Color(0xFFF5F3FF), // Light Purple
    const Color(0xFFFFF1F2), // Light Pink
    const Color(0xFFECFDF5), // Light Emerald
    const Color(0xFFFFFBEB), // Light Amber
  ];

  final List<Color> _accentColors = [
    const Color(0xFF0EA5E9),
    const Color(0xFF22C55E),
    const Color(0xFFF97316),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFFF43F5E),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (mounted) {
        setState(() {
          _resumeData = data ?? {};
          _careers = List<String>.from(_resumeData['careerInterests'] ?? []);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCareer(String career) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);
    
    List<String> updatedCareers = List<String>.from(_careers);
    updatedCareers.remove(career);
    
    await FirebaseService.instance.saveResume(userId, {
      'careerInterests': updatedCareers,
    });
    
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Career Roadmaps', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
          : _careers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _careers.length,
                  itemBuilder: (context, index) {
                    final career = _careers[index];
                    final colorIndex = index % _lightColors.length;
                    return _buildCareerCard(career, _lightColors[colorIndex], _accentColors[colorIndex]);
                  },
                ),
    );
  }

  Widget _buildCareerCard(String career, Color bgColor, Color accentColor) {
    final careerPlans = _resumeData['careerPlans'] ?? {};
    final plan = careerPlans[career];
    
    // Skills required by AI plan
    final requiredSkillsRaw = plan != null ? (plan['required_skills'] as List?) : [];
    final requiredNames = requiredSkillsRaw?.map((s) => s['name'].toString()).toList() ?? [];
    
    // Skills currently in the roadmap (Required + Added - Deleted)
    final roadmaps = _resumeData['careerRoadmaps'] ?? {};
    final currentSkills = List<String>.from(roadmaps[career] ?? []);
    
    // Skills deleted by user
    final deletedMap = _resumeData['deletedSkills'] ?? {};
    final deletedSkills = List<String>.from(deletedMap[career] ?? []);

    final progress = _resumeData['resourceProgress'] ?? {};
    final profileSkills = _resumeData['skills'] ?? [];
    
    // Metrics calculation
    int completedCount = 0;
    for (var skill in currentSkills) {
      // Check if the skill itself is in profile (marked as mastered or has level info)
      bool isMastered = profileSkills.any((s) {
        final String skillStr = s.toString().toLowerCase();
        final String targetSkill = skill.toLowerCase();
        return skillStr == targetSkill || skillStr.startsWith('$targetSkill (');
      });
      
      if (isMastered) {
        completedCount++;
      } else {
        // Fallback to resource check
        final skillProgress = progress[skill] ?? {};
        final completedResources = (skillProgress['completedResources'] as List?)?.length ?? 0;
        final totalResources = (skillProgress['totalResources'] as int?) ?? 0;
        
        if (totalResources > 0 && completedResources >= totalResources) {
          completedCount++;
        }
      }
    }

    int requiredCount = requiredNames.length;
    int addedCount = currentSkills.where((s) => !requiredNames.contains(s)).length;
    int deletedCount = deletedSkills.length;

    double progressPercent = currentSkills.isEmpty ? 0.0 : (completedCount / currentSkills.length).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RoadmapViewScreen(targetCareer: career, themeColor: accentColor)),
      ).then((_) => _loadData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.rocket_launch, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    career,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Roadmap?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        content: Text('This will remove "$career" from your interests. You can add it back in your profile.', style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteCareer(career);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric('Required', requiredCount, Colors.blue),
                _buildMetric('Completed', completedCount, Colors.green),
                _buildMetric('Added', addedCount, Colors.orange),
                _buildMetric('Deleted', deletedCount, Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Career Progression',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
                Text(
                  '${(progressPercent * 100).toInt()}%',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: accentColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'No Careers Selected',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Text(
              'Go to Profile -> Edit to select career interests.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
