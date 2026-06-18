import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'college_action_detail_screen.dart';

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

  Future<void> _deleteCollege(String name) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      await FirebaseService.instance.removeSavedCollege(userId, name);
      _fetchSavedColleges();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Real College Roadmap',
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
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _savedColleges.length,
                  itemBuilder: (context, index) {
                    final college = _savedColleges[index];
                    return _buildCollegeListTile(college);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No roadmaps created yet.',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'Save colleges to see their roadmaps here.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeListTile(Map<String, dynamic> college) {
    final String name = college['name'] ?? 'College';
    final String location = college['location'] ?? 'Unknown Location';
    final String chances = college['chances'] ?? 'Match';
    final Color primaryColor = _getPrimaryColor(name);

    final Map<String, dynamic> roadmapActions = Map<String, dynamic>.from(college['roadmapActions'] ?? {});
    int basePercentage = int.tryParse(college['base_percentage']?.toString() ?? college['match_percentage']?.toString() ?? '0') ?? 0;
    int actionValue = int.tryParse(college['action_value']?.toString() ?? '5') ?? 5;
    int completedCount = roadmapActions.values.where((a) => a['isCompleted'] == true).length;
    int currentPercentage = (basePercentage + (completedCount * actionValue)).clamp(0, 100);

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
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollegeActionDetailScreen(college: college),
            ),
          );
          _fetchSavedColleges();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.account_balance_rounded, color: primaryColor),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    chances,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$currentPercentage% Match',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              onPressed: () => _showDeleteConfirmation(name),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Roadmap?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('This will remove "$name" from your college roadmaps.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCollege(name);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
