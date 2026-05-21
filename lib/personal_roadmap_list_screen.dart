import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'personal_plan_detail_screen.dart';
import 'add_personal_roadmap_screen.dart';

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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('My Personal Goals', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFF10B981),
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : TabBarView(
                children: [
                  _buildRoadmapList('Active'),
                  _buildRoadmapList('In Progress'),
                  _buildRoadmapList('Completed'),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPersonalRoadmapScreen()),
          ).then((_) => _loadRoadmaps()),
          backgroundColor: const Color(0xFF10B981),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRoadmapList(String status) {
    final filteredRoadmaps = _roadmaps.where((r) {
      final String s = r['status'] ?? (r['isCompleted'] == true ? 'Completed' : 'Active');
      return s.toLowerCase() == status.toLowerCase();
    }).toList();

    if (filteredRoadmaps.isEmpty) {
      return _buildEmptyState(status);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredRoadmaps.length,
      itemBuilder: (context, index) {
        return _buildRoadmapCard(filteredRoadmaps[index]);
      },
    );
  }

  Widget _buildRoadmapCard(Map<String, dynamic> roadmap) {
    final String status = roadmap['status'] ?? (roadmap['isCompleted'] == true ? 'Completed' : 'Active');
    
    Color cardColor;
    Color iconColor;
    IconData iconData;

    switch (status) {
      case 'Completed':
        cardColor = const Color(0xFFF0FDF4); // Light Green
        iconColor = const Color(0xFF10B981);
        iconData = Icons.verified;
        break;
      case 'In Progress':
        cardColor = const Color(0xFFEFF6FF); // Light Blue
        iconColor = const Color(0xFF3B82F6);
        iconData = Icons.trending_up;
        break;
      default: // Active
        cardColor = const Color(0xFFFFF7ED); // Light Orange
        iconColor = Colors.orange;
        iconData = Icons.auto_awesome;
    }
    
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
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.05),
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
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
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
                      color: const Color(0xFF1E293B),
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
            Icon(Icons.arrow_forward_ios, size: 14, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_alt_1_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'No $status Goals',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Goals in this category will appear here.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
          ),
          if (status == 'Active') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPersonalRoadmapScreen()),
              ).then((_) => _loadRoadmaps()),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
