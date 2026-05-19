import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'roadmap_screen.dart';
import 'ai_service.dart';
import 'career_plan_screen.dart';

class RoadmapViewScreen extends StatefulWidget {
  final String? targetCareer;
  final Color themeColor;
  const RoadmapViewScreen({super.key, this.targetCareer, this.themeColor = const Color(0xFF5B3FD8)});

  @override
  State<RoadmapViewScreen> createState() => _RoadmapViewScreenState();
}

class _RoadmapViewScreenState extends State<RoadmapViewScreen> {
  bool _isLoading = true;
  bool _isNewsLoading = false;
  bool _isValidating = false;
  Map<String, dynamic> _careerRoadmaps = {};
  Map<String, dynamic> _careerNews = {};
  Map<String, dynamic> _deletedSkills = {};
  String? _activeCareerInterest;
  final AiService _aiService = GroqAiService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoadmaps();
  }

  Future<void> _loadRoadmaps() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (mounted) {
        setState(() {
          _careerRoadmaps = Map<String, dynamic>.from(data?['careerRoadmaps'] ?? {});
          _careerNews = Map<String, dynamic>.from(data?['careerNews'] ?? {});
          _deletedSkills = Map<String, dynamic>.from(data?['deletedSkills'] ?? {});
          _activeCareerInterest = widget.targetCareer ?? data?['activeCareerInterest'];
        });

        if (_activeCareerInterest != null) {
          final cachedPlans = data?['careerPlans'] as Map<String, dynamic>?;
          if (cachedPlans == null || !cachedPlans.containsKey(_activeCareerInterest)) {
            // Auto generate plan if missing
            await _autoGeneratePlan(_activeCareerInterest!, data!);
          } else {
            setState(() => _isLoading = false);
            _fetchFreshNews(_activeCareerInterest!);
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _autoGeneratePlan(String career, Map<String, dynamic> userData) async {
    setState(() => _isLoading = true);
    try {
      final plan = await _aiService.getDetailedCareerPlan(userData, career);
      final userId = FirebaseService.instance.currentUserId!;
      
      final currentPlans = Map<String, dynamic>.from(userData['careerPlans'] ?? {});
      currentPlans[career] = plan;
      
      // Merge with existing roadmap, respecting deleted skills
      List<String> currentRoadmap = List<String>.from(_careerRoadmaps[career] ?? []);
      List<String> deletedList = List<String>.from(_deletedSkills[career] ?? []);
      
      final requiredSkills = (plan['required_skills'] as List?)
          ?.where((s) => s['already_mastered'] != true)
          .map((s) => s['name'] as String)
          .toList() ?? [];

      for (var skill in requiredSkills) {
        if (!currentRoadmap.contains(skill) && !deletedList.contains(skill)) {
          currentRoadmap.add(skill);
        }
      }
      _careerRoadmaps[career] = currentRoadmap;

      await FirebaseService.instance.saveResume(userId, {
        'careerPlans': currentPlans,
        'careerRoadmaps': _careerRoadmaps,
        if (plan['industry_news'] != null) 'careerNews': {career: plan['industry_news']}
      });

      if (mounted) {
        setState(() {
          _careerNews[career] = plan['industry_news'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error auto-generating plan: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addSkill(String career, String skill) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    List<String> currentSkills = List<String>.from(_careerRoadmaps[career] ?? []);
    if (!currentSkills.contains(skill)) {
      currentSkills.add(skill);
      _careerRoadmaps[career] = currentSkills;

      await FirebaseService.instance.saveResume(userId, {
        'careerRoadmaps': _careerRoadmaps,
      });
      _loadRoadmaps();
    }
  }

  Future<void> _validateAndAddSkill(String skill) async {
    if (skill.isEmpty || _activeCareerInterest == null) return;
    
    setState(() => _isValidating = true);
    
    try {
      final result = await _aiService.validateSkillRelevance(skill, _activeCareerInterest!);
      
      if (mounted) {
        setState(() => _isValidating = false);
        _searchController.clear();

        String selectedLevel = 'Basic';
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      result['is_relevant'] ? Icons.check_circle : Icons.info_outline,
                      color: result['is_relevant'] ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Text('AI Insight', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection: ${result['connection_type']}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: widget.themeColor),
                    ),
                    const SizedBox(height: 8),
                    Text(result['explanation'], style: GoogleFonts.poppins()),
                    const SizedBox(height: 24),
                    Text('Select Your Current Level:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLevel,
                          isExpanded: true,
                          items: ['Basic', 'Intermediate', 'Advanced'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                          onChanged: (val) => setDialogState(() => selectedLevel = val ?? 'Basic'),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addSkill(_activeCareerInterest!, '$skill ($selectedLevel)');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor, foregroundColor: Colors.white),
                    child: const Text('Add to Roadmap'),
                  ),
                ],
              );
            }
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isValidating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error validating skill')));
      }
    }
  }

  Future<void> _deleteSkill(String career, String skill) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    List<String> currentSkills = List<String>.from(_careerRoadmaps[career] ?? []);
    currentSkills.remove(skill);
    _careerRoadmaps[career] = currentSkills;

    List<String> deletedList = List<String>.from(_deletedSkills[career] ?? []);
    if (!deletedList.contains(skill)) {
      deletedList.add(skill);
    }
    _deletedSkills[career] = deletedList;

    await FirebaseService.instance.saveResume(userId, {
      'careerRoadmaps': _careerRoadmaps,
      'deletedSkills': _deletedSkills,
    });

    _loadRoadmaps();
  }

  Future<void> _fetchFreshNews(String career) async {
    setState(() => _isNewsLoading = true);
    try {
      final userId = FirebaseService.instance.currentUserId;
      if (userId == null) return;

      final userData = await FirebaseService.instance.getResume(userId);
      if (userData == null) return;

      // We only need the news part of the plan
      final plan = await _aiService.getDetailedCareerPlan(userData, career);
      
      if (mounted && plan['industry_news'] != null) {
        setState(() {
          _careerNews[career] = plan['industry_news'];
          _isNewsLoading = false;
        });

        // Save it to Firestore so it's cached but we just refreshed it
        await FirebaseService.instance.saveResume(userId, {'careerNews': _careerNews});
      }
    } catch (e) {
      debugPrint("Error refreshing news: $e");
      if (mounted) setState(() => _isNewsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Learning Roadmap', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
          : (_activeCareerInterest == null || _careerRoadmaps[_activeCareerInterest] == null)
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Fixed Career Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: _buildCareerHeader(
                        _activeCareerInterest!, 
                        List<String>.from(_careerRoadmaps[_activeCareerInterest] ?? [])
                      ),
                    ),
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: _buildSearchBar(),
                    ),
                    // Scrollable News and Skills
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildSkillsSection(
                              _activeCareerInterest!, 
                              List<String>.from(_careerRoadmaps[_activeCareerInterest] ?? [])
                            ),
                            const SizedBox(height: 32),
                            _buildTrendingNewsSection(_activeCareerInterest!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 14),
        onSubmitted: (value) => _validateAndAddSkill(value.trim()),
        decoration: InputDecoration(
          hintText: 'Search or add new course/skill...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: widget.themeColor),
          suffixIcon: _isValidating 
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: widget.themeColor,
                onPressed: () => _validateAndAddSkill(_searchController.text.trim()),
              ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCareerHeader(String career, List<String> skills) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService.instance.getResume(FirebaseService.instance.currentUserId!),
      builder: (context, snapshot) {
        int totalTargetSkills = 15; // Default fallback
        if (snapshot.hasData) {
          final targetAchievement = snapshot.data!['goals']?['targetAchievementLevel'] ?? 'Job';
          if (targetAchievement.toLowerCase().contains('job') || targetAchievement.toLowerCase().contains('elite')) {
            totalTargetSkills = 25;
          } else if (targetAchievement.toLowerCase().contains('abroad') || targetAchievement.toLowerCase().contains('international')) {
            totalTargetSkills = 20;
          }
        }
        
        final int skillsLeft = (totalTargetSkills - skills.length).clamp(0, totalTargetSkills);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.themeColor.withValues(alpha: 0.8), widget.themeColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: widget.themeColor.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.work_outline, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE FOCUS',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withAlpha(150), letterSpacing: 1.2),
                    ),
                    Text(
                      career,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                    child: Text('${skills.length} Skills', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CareerPlanScreen(targetCareer: career)),
                      ).then((_) => _loadRoadmaps());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '$skillsLeft Left',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillsSection(String career, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: widget.themeColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Your Learning Path',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: skills.length,
          itemBuilder: (context, skillIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildSkillChip(career, skills[skillIndex]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendingNewsSection(String career) {
    final news = _careerNews[career] as List?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.newspaper_outlined, color: Color(0xFF5B3FD8), size: 20),
            const SizedBox(width: 8),
            Text(
              'Trending in $career',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            const Spacer(),
            if (_isNewsLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5B3FD8)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (news == null || news.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Icon(Icons.auto_awesome, color: Colors.grey.shade300, size: 32),
                const SizedBox(height: 12),
                Text(
                  _isNewsLoading ? 'Fetching latest trends...' : 'No trends fetched yet.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(4)),
                          child: Text(item['date'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['impact'] ?? '',
                      style: GoogleFonts.poppins(color: Colors.white.withAlpha(200), fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              );
            },
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
            Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'No Roadmaps Yet',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Text(
              'Go to AI Insights -> What to do next to pick a career and start building your roadmap!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String career, String skill) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService.instance.getResume(FirebaseService.instance.currentUserId!),
      builder: (context, snapshot) {
        double percentage = 0;
        bool isAlreadyInProfile = false;
        
        if (snapshot.hasData) {
          final List<dynamic> profileSkills = snapshot.data!['skills'] ?? [];
          // Match base skill name even if it has level info
          isAlreadyInProfile = profileSkills.any((s) {
            final String skillStr = s.toString().toLowerCase();
            final String targetSkill = skill.toLowerCase();
            return skillStr == targetSkill || skillStr.startsWith('$targetSkill (');
          });

          final progress = snapshot.data!['resourceProgress'] ?? {};
          final skillProgress = progress[skill] ?? {};
          final completed = (skillProgress['completedResources'] as List?)?.length ?? 0;
          final total = (skillProgress['totalResources'] as int?) ?? 1;
          percentage = (completed / total).clamp(0.0, 1.0);
        }

        final Color primaryColor = isAlreadyInProfile ? const Color(0xFF8B5CF6) : widget.themeColor;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RoadmapScreen(skill: skill, careerContext: career)),
            ).then((_) => _loadRoadmaps());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isAlreadyInProfile ? primaryColor.withValues(alpha: 0.15) : Colors.grey.shade200, width: isAlreadyInProfile ? 2 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAlreadyInProfile) ...[
                  Icon(Icons.sync, color: primaryColor, size: 14),
                  const SizedBox(width: 8),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill,
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 100,
                      height: 4,
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade100,
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Skill', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to remove "$skill" from your $career roadmap?', style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteSkill(career, skill);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
