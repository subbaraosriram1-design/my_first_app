import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'college_detail_screen.dart';

class CollegeRoadmapViewScreen extends StatefulWidget {
  const CollegeRoadmapViewScreen({super.key});

  @override
  State<CollegeRoadmapViewScreen> createState() => _CollegeRoadmapViewScreenState();
}

class _CollegeRoadmapViewScreenState extends State<CollegeRoadmapViewScreen> {
  List<Map<String, dynamic>> _savedColleges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedColleges();
  }

  Future<void> _fetchSavedColleges() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final saved = await FirebaseService.instance.getSavedColleges(userId);
      if (mounted) {
        setState(() {
          _savedColleges = saved;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Deep College Roadmap',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _savedColleges.isEmpty
              ? _buildEmptyState()
              : _buildMainRoadmap(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_motion_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'No College Roadmaps',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Text(
              'Save colleges from the College Suggestions screen to see their deep roadmap actions here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainRoadmap() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _savedColleges.length,
      itemBuilder: (context, index) {
        final college = _savedColleges[index];
        final actions = Map<String, dynamic>.from(college['roadmapActions'] ?? {});
        final completedCount = actions.values.where((a) => a['isCompleted'] == true).length;
        final totalCount = actions.length;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.school_rounded, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            college['name'] ?? 'College',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$completedCount of $totalCount actions completed',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CollegeDetailScreen(advice: college)),
                      ).then((_) => _fetchSavedColleges()),
                    ),
                  ],
                ),
              ),
              if (totalCount > 0) ...[
                const Divider(height: 1),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actions.length > 3 ? 3 : actions.length,
                  itemBuilder: (context, i) {
                    final action = actions.values.toList()[i];
                    final isDone = action['isCompleted'] == true;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isDone ? const Color(0xFF10B981) : Colors.grey.shade300,
                        size: 20,
                      ),
                      title: Text(
                        action['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
                if (totalCount > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 70, bottom: 16),
                    child: Text(
                      '+ ${totalCount - 3} more actions',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6366F1), fontWeight: FontWeight.w600),
                    ),
                  ),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    'No actions added to this roadmap yet.',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
