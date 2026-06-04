import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'college_detail_screen.dart';

class SavedCollegesScreen extends StatefulWidget {
  const SavedCollegesScreen({super.key});

  @override
  State<SavedCollegesScreen> createState() => _SavedCollegesScreenState();
}

class _SavedCollegesScreenState extends State<SavedCollegesScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Your College Roadmap',
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
                    return _buildModernCollegeCard(college);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 48, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            'No targets set yet.',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by saving colleges from the intelligence screen.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernCollegeCard(Map<String, dynamic> college) {
    final String name = college['name'] ?? 'College';
    final String location = college['location'] ?? 'Unknown Location';
    final Color primaryColor = _getPrimaryColor(name);

    final Map<String, dynamic> roadmapActions = Map<String, dynamic>.from(college['roadmapActions'] ?? {});
    int basePercentage = int.tryParse(college['base_percentage']?.toString() ?? college['match_percentage']?.toString() ?? '0') ?? 0;
    int actionValue = int.tryParse(college['action_value']?.toString() ?? '5') ?? 5;
    int completedCount = roadmapActions.values.where((a) => a['isCompleted'] == true).length;
    int currentPercentage = (basePercentage + (completedCount * actionValue)).clamp(0, 100);

    Color chanceColor = Colors.redAccent;
    String statusText = 'Reach';
    if (currentPercentage >= 70) {
      chanceColor = const Color(0xFF10B981);
      statusText = 'Likely';
    } else if (currentPercentage >= 40) {
      chanceColor = Colors.orangeAccent;
      statusText = 'Possible';
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollegeDetailScreen(advice: college),
          ),
        );
        _fetchSavedColleges();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.account_balance_rounded, color: primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          location,
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: chanceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: chanceColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.track_changes_rounded, size: 14, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${roadmapActions.length} Targets Active',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '$currentPercentage% Chance',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: chanceColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: currentPercentage / 100,
                            backgroundColor: chanceColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(chanceColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
