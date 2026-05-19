import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'personal_plan_detail_screen.dart';

class PersonalRoadmapListScreen extends StatefulWidget {
  const PersonalRoadmapListScreen({super.key});

  @override
  State<PersonalRoadmapListScreen> createState() => _PersonalRoadmapListScreenState();
}

class _PersonalRoadmapListScreenState extends State<PersonalRoadmapListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _roadmaps = [];

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
        final Map<String, dynamic> personalRoadmaps = Map<String, dynamic>.from(data?['personalRoadmaps'] ?? {});
        setState(() {
          _roadmaps = personalRoadmaps.values.map((e) => Map<String, dynamic>.from(e)).toList();
          _roadmaps.sort((a, b) => b['updatedAt'].compareTo(a['updatedAt']));
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
        title: Text('My Personal Goals', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _roadmaps.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _roadmaps.length,
                  itemBuilder: (context, index) {
                    return _buildRoadmapCard(_roadmaps[index]);
                  },
                ),
    );
  }

  Widget _buildRoadmapCard(Map<String, dynamic> roadmap) {
    final bool isCompleted = roadmap['isCompleted'] ?? false;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalPlanDetailScreen(roadmapData: roadmap),
        ),
      ).then((_) => _loadRoadmaps()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4), // Very light green
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.auto_awesome, 
                color: const Color(0xFF10B981), 
                size: 24
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roadmap['title'] ?? 'Untitled',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF065F46),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roadmap['description'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_alt_1_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'No Personal Goals Yet',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add New" to start your personal growth journey.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
