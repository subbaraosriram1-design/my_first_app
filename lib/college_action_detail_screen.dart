import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'target_step_detail_screen.dart';

class CollegeActionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> college;
  const CollegeActionDetailScreen({super.key, required this.college});

  @override
  State<CollegeActionDetailScreen> createState() => _CollegeActionDetailScreenState();
}

class _CollegeActionDetailScreenState extends State<CollegeActionDetailScreen> {
  Map<String, dynamic> _currentRoadmap = {};
  late Color _primaryColor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _primaryColor = _getPrimaryColor(widget.college['name'] ?? '');
    _loadRoadmap();
  }

  void _loadRoadmap() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final savedColleges = await FirebaseService.instance.getSavedColleges(userId);
      final updatedCollege = savedColleges.firstWhere(
        (c) => c['name'] == widget.college['name'],
        orElse: () => widget.college,
      );
      if (mounted) {
        setState(() {
          _currentRoadmap = Map<String, dynamic>.from(updatedCollege['roadmapActions'] ?? {});
          _isLoading = false;
        });
      }
    }
  }

  Color _getPrimaryColor(String name) {
    final int hash = name.hashCode;
    final List<Color> primaries = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF059669), // Emerald
      const Color(0xFFDC2626), // Red
      const Color(0xFF2563EB), // Blue
      const Color(0xFFD97706), // Amber
      const Color(0xFF7C3AED), // Violet
      const Color(0xFFBE185D), // Pink
      const Color(0xFF0891B2), // Cyan
    ];
    return primaries[hash.abs() % primaries.length];
  }

  Future<void> _updateAction(String title, bool isCompleted) async {
    final userId = FirebaseService.instance.currentUserId;
    final collegeName = widget.college['name'] ?? '';
    if (userId != null) {
      await FirebaseService.instance.updateCollegeRoadmapAction(
        userId, 
        collegeName, 
        title, 
        true, 
        isCompleted: isCompleted,
      );
      _loadRoadmap();
    }
  }

  Future<void> _deleteAction(String title) async {
    final userId = FirebaseService.instance.currentUserId;
    final collegeName = widget.college['name'] ?? '';
    if (userId != null) {
      await FirebaseService.instance.updateCollegeRoadmapAction(
        userId, 
        collegeName, 
        title, 
        false,
      );
      _loadRoadmap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _currentRoadmap.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.college['name'] ?? 'College Roadmap',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Admission Targets',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete these targets to improve your profile for this institution.',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: actions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: actions.length,
                          itemBuilder: (context, index) {
                            final action = actions[index];
                            return _buildActionCard(action);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rtl_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No active targets',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add targets from the College Details page.',
            style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final String title = action['title'] ?? '';
    final bool isCompleted = action['isCompleted'] ?? false;
    final String? suggestion = action['suggestion'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TargetStepDetailScreen(
              collegeName: widget.college['name'] ?? 'College',
              actionTitle: title,
              themeColor: _primaryColor,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _updateAction(title, !isCompleted),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.radio_button_unchecked,
                        size: 14,
                        color: isCompleted ? Colors.white : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteAction(title),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'AI Strategy',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                suggestion ?? 'Tap to view specialized action plan for this target.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
