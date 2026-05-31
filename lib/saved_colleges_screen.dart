import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'college_detail_screen.dart';
import 'college_preferences_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Saved Colleges',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF5B3FD8)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CollegePreferencesScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
          : _savedColleges.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _savedColleges.length,
                  itemBuilder: (context, index) {
                    final college = _savedColleges[index];
                    return _buildCollegeCard(college);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No colleges saved yet.',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeCard(Map<String, dynamic> college) {
    final Map<String, dynamic> roadmapActions = Map<String, dynamic>.from(college['roadmapActions'] ?? {});
    final List<Map<String, dynamic>> activeActions = roadmapActions.values.cast<Map<String, dynamic>>().toList();
    
    // Calculate dynamic percentage
    int basePercentage = int.tryParse(college['match_percentage']?.toString() ?? '0') ?? 0;
    if (basePercentage == 0) basePercentage = int.tryParse(college['base_percentage']?.toString() ?? '0') ?? 0;
    
    int actionValue = int.tryParse(college['action_value']?.toString() ?? '5') ?? 5;
    int completedCount = activeActions.where((a) => a['isCompleted'] == true).length;
    int currentPercentage = (basePercentage + (completedCount * actionValue)).clamp(0, 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              college['name'] ?? 'College',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  college['chances'] ?? 'Assessment',
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: currentPercentage >= 80 ? Colors.green.withAlpha(20) : const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$currentPercentage% Admission Chance',
                    style: GoogleFonts.poppins(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      color: currentPercentage >= 80 ? Colors.green : const Color(0xFF0284C7)
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CollegeDetailScreen(advice: college),
                ),
              );
              _fetchSavedColleges(); 
            },
          ),
          // Progress Bar for Admission
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: currentPercentage / 100,
                backgroundColor: Colors.grey.shade100,
                color: currentPercentage >= 80 ? Colors.green : const Color(0xFF5B3FD8),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (activeActions.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.playlist_add_check, color: Color(0xFF5B3FD8), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Targeted Actions',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...activeActions.map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final userId = FirebaseService.instance.currentUserId;
                            if (userId != null) {
                              await FirebaseService.instance.updateCollegeRoadmapAction(
                                userId,
                                college['name'],
                                action['title'],
                                true,
                                isCompleted: !(action['isCompleted'] ?? false),
                              );
                              _fetchSavedColleges();
                            }
                          },
                          child: Icon(
                            (action['isCompleted'] ?? false) ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 18,
                            color: (action['isCompleted'] ?? false) ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: (action['isCompleted'] ?? false) ? Colors.grey : const Color(0xFF334155),
                              decoration: (action['isCompleted'] ?? false) ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent),
                          onPressed: () async {
                            final userId = FirebaseService.instance.currentUserId;
                            if (userId != null) {
                              await FirebaseService.instance.updateCollegeRoadmapAction(
                                userId,
                                college['name'],
                                action['title'],
                                false,
                              );
                              _fetchSavedColleges();
                            }
                          },
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
