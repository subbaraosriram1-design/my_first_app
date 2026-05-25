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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          college['name'] ?? 'College',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          college['chances'] ?? 'Assessment available',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollegeDetailScreen(advice: college),
            ),
          );
          _fetchSavedColleges(); // Refresh list on return
        },
      ),
    );
  }
}
