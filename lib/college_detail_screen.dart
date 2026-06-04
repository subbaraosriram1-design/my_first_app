import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_service.dart';

class CollegeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> advice;
  const CollegeDetailScreen({super.key, required this.advice});

  @override
  State<CollegeDetailScreen> createState() => _CollegeDetailScreenState();
}

class _CollegeDetailScreenState extends State<CollegeDetailScreen> with TickerProviderStateMixin {
  bool _isSaved = false;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  late AnimationController _fadeController;
  final TextEditingController _customTargetController = TextEditingController();
  Color _primaryColor = const Color(0xFF6366F1);
  Color _secondaryColor = const Color(0xFF8B5CF6);
  Color _accentColor = const Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _generateCollegeColors();
    _checkIfSaved();
    _loadUserProfile();
    _fadeController.forward();
  }

  void _generateCollegeColors() {
    final String name = widget.advice['name'] ?? 'College';
    final int hash = name.hashCode;
    
    // List of sophisticated color palettes
    final List<List<Color>> palettes = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFFEC4899)], // Indigo/Pink
      [const Color(0xFF059669), const Color(0xFF10B981), const Color(0xFF34D399)], // Emerald/Green
      [const Color(0xFFDC2626), const Color(0xFFEF4444), const Color(0xFFF87171)], // Red
      [const Color(0xFF2563EB), const Color(0xFF3B82F6), const Color(0xFF60A5FA)], // Blue
      [const Color(0xFFD97706), const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // Amber/Gold
      [const Color(0xFF7C3AED), const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], // Violet
      [const Color(0xFFBE185D), const Color(0xFFDB2777), const Color(0xFFF472B6)], // Pink
      [const Color(0xFF0891B2), const Color(0xFF06B6D4), const Color(0xFF22D3EE)], // Cyan
    ];
    
    final int index = hash.abs() % palettes.length;
    _primaryColor = palettes[index][0];
    _secondaryColor = palettes[index][1];
    _accentColor = palettes[index][2];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _customTargetController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final profile = await FirebaseService.instance.getResume(userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } else {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _checkIfSaved() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final saved = await FirebaseService.instance.getSavedColleges(userId);
      if (mounted) {
        setState(() {
          _isSaved = saved.any((c) => c['name'] == widget.advice['name']);
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    if (_isSaved) {
      await FirebaseService.instance.removeSavedCollege(userId, widget.advice['name']);
    } else {
      await FirebaseService.instance.saveCollege(userId, widget.advice);
    }

    if (mounted) {
      setState(() {
        _isSaved = !_isSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'College saved to your roadmap!' : 'Removed from saved.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChancesBadge(),
                    const SizedBox(height: 24),
                    _buildInteractiveSection(
                      'Match Analysis',
                      widget.advice['match_analysis'],
                      Icons.insights_rounded,
                      _primaryColor,
                    ),
                    const SizedBox(height: 20),
                    _buildVisualDatasetSection(),
                    const SizedBox(height: 20),
                    _buildInteractiveSection(
                      'Extracurricular Strategy',
                      widget.advice['extracurricular_strategy'],
                      Icons.stars_rounded,
                      const Color(0xFFF59E0B),
                      subtitle: 'How they value non-academic factors',
                      extra: _buildECWeightBadge(),
                    ),
                    const SizedBox(height: 20),
                    if (widget.advice['cds_insight'] != null) ...[
                      _buildInteractiveSection(
                        'Expert Admission Insight',
                        widget.advice['cds_insight'],
                        Icons.lightbulb_outline_rounded,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildInteractiveSection(
                      'Academic Rigor Plan',
                      widget.advice['academic_strategy'],
                      Icons.school_rounded,
                      _secondaryColor,
                    ),
                    const SizedBox(height: 20),
                    _buildInteractiveSection(
                      'Positioning & Narrative',
                      widget.advice['holistic_narrative'],
                      Icons.record_voice_over_rounded,
                      _accentColor,
                    ),
                    const SizedBox(height: 20),
                    if (widget.advice['financial_aid_hint'] != null) ...[
                      _buildInteractiveSection(
                        'Financial Aid Context',
                        widget.advice['financial_aid_hint'],
                        Icons.payments_outlined,
                        const Color(0xFF06B6D4),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildInteractiveSection(
                      '24-Month Action Plan',
                      widget.advice['action_plan'],
                      Icons.calendar_today_rounded,
                      _primaryColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 20),
                    _buildRoadmapSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          widget.advice['name'] ?? 'College Detail',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryColor, _secondaryColor, _accentColor],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            color: Colors.white,
          ),
          onPressed: _toggleSave,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChancesBadge() {
    final String chances = widget.advice['chances'] ?? 'Analyzing...';
    final Map<String, dynamic> roadmapActions = Map<String, dynamic>.from(widget.advice['roadmapActions'] ?? {});
    final int completedCount = roadmapActions.values.where((a) => a['isCompleted'] == true).length;
    final int basePercentage = int.tryParse(widget.advice['base_percentage']?.toString() ?? widget.advice['match_percentage']?.toString() ?? '0') ?? 0;
    final int actionValue = int.tryParse(widget.advice['action_value']?.toString() ?? '5') ?? 5;
    final int currentPercentage = (basePercentage + (completedCount * actionValue)).clamp(0, 100);

    Color color = const Color(0xFF6366F1);
    if (chances.toLowerCase().contains('reach')) color = const Color(0xFFEF4444);
    if (chances.toLowerCase().contains('match')) color = const Color(0xFF10B981);
    if (chances.toLowerCase().contains('safety')) color = const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admissions Status', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  Text(
                    chances,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: currentPercentage / 100,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$currentPercentage%',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          if (completedCount > 0) ...[
            const Divider(height: 30),
            Row(
              children: [
                const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Raised by ${completedCount * actionValue}% through roadmap progress',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildECWeightBadge() {
    final weight = widget.advice['extracurricular_weight']?.toString() ?? 'Medium';
    Color color = Colors.orange;
    if (weight.toLowerCase().contains('high')) color = Colors.redAccent;
    if (weight.toLowerCase().contains('low')) color = Colors.blueAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Value: $weight',
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildVisualDatasetSection() {
    if (_isLoadingProfile) return const Center(child: CircularProgressIndicator());

    final collegeGpa = double.tryParse(widget.advice['avg_gpa']?.toString() ?? '3.8') ?? 3.8;
    final collegeSat = int.tryParse(widget.advice['avg_sat']?.toString() ?? '1450') ?? 1450;
    final collegeAct = int.tryParse(widget.advice['avg_act']?.toString() ?? '32') ?? 32;

    final userGpa = double.tryParse(_userProfile?['weightedGpa']?.toString() ?? '0.0') ?? 0.0;
    
    int userSat = 0;
    final satRange = _userProfile?['satScoreRange']?.toString() ?? '';
    if (satRange.contains('-')) {
      userSat = int.tryParse(satRange.split('-').last) ?? 0;
    } else if (satRange.contains('+')) {
      userSat = int.tryParse(satRange.replaceAll('+', '')) ?? 0;
    }

    int userAct = 0;
    final actRange = _userProfile?['actScoreRange']?.toString() ?? '';
    if (actRange.contains('-')) {
      userAct = int.tryParse(actRange.split('-').last) ?? 0;
    } else if (actRange.contains('+')) {
      userAct = int.tryParse(actRange.replaceAll('+', '')) ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: _primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Admission Benchmark',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressComparison('GPA', userGpa, collegeGpa, 4.0),
          const SizedBox(height: 20),
          _buildProgressComparison('SAT', userSat.toDouble(), collegeSat.toDouble(), 1600),
          const SizedBox(height: 20),
          _buildProgressComparison('ACT', userAct.toDouble(), collegeAct.toDouble(), 36),
        ],
      ),
    );
  }

  Widget _buildProgressComparison(String label, double user, double college, double max) {
    bool isAhead = user >= college;
    final color = isAhead ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(
              'Target: $college',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              height: 12,
              width: (user / max) * 300, // Normalized
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          user == 0 ? 'Score not in profile' : 'Your profile: $user',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveSection(String title, String? content, IconData icon, Color color, {String? subtitle, Widget? extra}) {
    // Generate helpful tip if content is missing
    final displayContent = (content == null || content.isEmpty || content.contains('No details available'))
        ? 'Expert analysis is processing. Pro-tip: Elite institutions like ${widget.advice['name'] ?? 'this college'} look for demonstrated interest and rigorous course selection in your intended major.'
        : content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    if (subtitle != null)
                      Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              extra ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            displayContent,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF334155),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseService.instance.getSavedColleges(FirebaseService.instance.currentUserId ?? ""),
      builder: (context, snapshot) {
        final Map<String, dynamic> currentRoadmap = snapshot.hasData 
          ? (snapshot.data!.firstWhere((c) => c['name'] == widget.advice['name'], orElse: () => {})['roadmapActions'] ?? {})
          : {};

        final List<dynamic> aiSuggestions = widget.advice['suggested_extracurriculars'] ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 60),
            Row(
              children: [
                Icon(Icons.map_rounded, color: _primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Roadmap Analysis & Strategy',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your personalized path to admission at ${widget.advice['name']}. Complete targets to increase your chances.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildTargetCategory(
              'Your Active Targets',
              currentRoadmap.values.toList(),
              true,
              currentRoadmap,
            ),
            const SizedBox(height: 20),
            _buildTargetCategory(
              'AI Recommended Milestones',
              aiSuggestions.where((s) {
                final title = s is Map ? (s['title'] ?? '') : s.toString();
                return !currentRoadmap.containsKey(title);
              }).toList(),
              false,
              currentRoadmap,
            ),
            const SizedBox(height: 20),
            _buildCustomTargetInput(),
          ],
        );
      },
    );
  }

  Widget _buildTargetCategory(String title, List<dynamic> items, bool isActive, Map<String, dynamic> currentRoadmap) {
    if (items.isEmpty && !isActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: isActive ? null : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: isActive 
          ? [BoxShadow(color: _primaryColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))] 
          : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isActive ? Icons.rocket_launch_rounded : Icons.auto_awesome_rounded, 
                    color: isActive ? const Color(0xFFF59E0B) : _primaryColor, 
                    size: 22
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: isActive ? Colors.white : const Color(0xFF1E293B)
                    ),
                  ),
                ],
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${items.length} Active',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No active targets yet.',
                  style: GoogleFonts.poppins(color: isActive ? Colors.white38 : Colors.grey, fontSize: 13),
                ),
              ),
            ),
          ...items.map((item) => _buildTargetItem(item, isActive, currentRoadmap)),
        ],
      ),
    );
  }

  Widget _buildTargetItem(dynamic item, bool isActive, Map<String, dynamic> currentRoadmap) {
    final String title = item is Map ? (item['title'] ?? '') : item.toString();
    final String? suggestion = item is Map ? item['suggestion'] : null;
    final String? link = item is Map ? item['resource_link'] : null;
    final bool isCompleted = isActive && (item is Map && (item['isCompleted'] == true));
    final bool isAdded = currentRoadmap.containsKey(title);

    final Color itemColor = isActive 
        ? (isCompleted ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.9))
        : const Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive 
            ? (isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05))
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
              ? (isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1))
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: isActive 
            ? GestureDetector(
                onTap: () async {
                  final userId = FirebaseService.instance.currentUserId;
                  final collegeName = widget.advice['name']?.toString() ?? 'Unknown College';
                  if (userId != null) {
                    await FirebaseService.instance.updateCollegeRoadmapAction(
                      userId, collegeName, title, true, isCompleted: !isCompleted,
                    );
                    setState(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                    border: Border.all(color: isCompleted ? const Color(0xFF10B981) : Colors.white24),
                  ),
                  child: Icon(
                    Icons.check,
                    color: isCompleted ? Colors.white : Colors.white24,
                    size: 16,
                  ),
                ),
              )
            : Icon(Icons.add_task_rounded, color: _primaryColor.withValues(alpha: 0.5), size: 20),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: itemColor,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          trailing: InkWell(
            onTap: () async {
              final userId = FirebaseService.instance.currentUserId;
              final collegeName = widget.advice['name']?.toString() ?? 'Unknown College';
              if (userId != null) {
                if (!isAdded) {
                  // Adding from AI suggestions
                  await FirebaseService.instance.updateCollegeRoadmapAction(
                    userId, collegeName, title, true,
                    actionData: item is Map ? Map<String, dynamic>.from(item) : null,
                  );
                } else {
                  // Removing from active
                  await FirebaseService.instance.updateCollegeRoadmapAction(
                    userId, collegeName, title, false,
                  );
                }
                setState(() {});
              }
            },
            child: Icon(
              isAdded ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
              color: isAdded 
                  ? (isActive ? Colors.white.withValues(alpha: 0.54) : Colors.redAccent)
                  : (isActive ? Colors.white : _primaryColor),
              size: 22,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  Text(
                    suggestion ?? 'This target helps build a competitive profile for ${widget.advice['name']} by demonstrating your commitment and relevant skills.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isActive ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                  if (link != null && link.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(link);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withValues(alpha: 0.1) : _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded, size: 14, color: isActive ? Colors.white : _primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Expert Resource',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : _primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTargetInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'Set Custom Target',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTargetController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Visit campus, Contact alum...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.24), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () async {
                  final text = _customTargetController.text.trim();
                  if (text.isEmpty) return;
                  
                  final userId = FirebaseService.instance.currentUserId;
                  final collegeName = widget.advice['name']?.toString() ?? 'Unknown College';
                  if (userId != null) {
                    await FirebaseService.instance.updateCollegeRoadmapAction(
                      userId, collegeName, text, true,
                    );
                    _customTargetController.clear();
                    setState(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _accentColor.withValues(alpha: 0.3), blurRadius: 10)],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
