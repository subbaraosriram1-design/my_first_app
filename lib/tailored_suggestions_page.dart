import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'college_detail_screen.dart';

class TailoredSuggestionsPage extends StatefulWidget {
  final Map<String, dynamic> tieredSuggestions;
  const TailoredSuggestionsPage({super.key, required this.tieredSuggestions});

  @override
  State<TailoredSuggestionsPage> createState() => _TailoredSuggestionsPageState();
}

class _TailoredSuggestionsPageState extends State<TailoredSuggestionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _savedCollegeNames = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedStatus();
  }

  Future<void> _loadSavedStatus() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final saved = await FirebaseService.instance.getSavedColleges(userId);
      if (mounted) {
        setState(() {
          for (var c in saved) {
            final name = c['name'];
            if (name != null) {
              _savedCollegeNames.add(name.toString());
            }
          }
        });
      }
    }
  }

  Future<void> _toggleSave(Map<String, dynamic> college) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    final name = college['name']?.toString() ?? 'Unknown College';
    final isSaved = _savedCollegeNames.contains(name);

    if (isSaved) {
      await FirebaseService.instance.removeSavedCollege(userId, name);
      _savedCollegeNames.remove(name);
    } else {
      await FirebaseService.instance.saveCollege(userId, college);
      _savedCollegeNames.add(name);
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSaved ? 'Removed from saved' : 'College saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Tiered College Matches',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5B3FD8),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF5B3FD8),
          tabs: const [
            Tab(text: 'Safety (10)'),
            Tab(text: 'Match (10)'),
            Tab(text: 'Reach (10)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTierList(widget.tieredSuggestions['safety'] ?? []),
          _buildTierList(widget.tieredSuggestions['match'] ?? []),
          _buildTierList(widget.tieredSuggestions['reach'] ?? []),
        ],
      ),
    );
  }

  Widget _buildTierList(List<dynamic> colleges) {
    if (colleges.isEmpty) {
      return const Center(child: Text('No suggestions in this category.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: colleges.length,
      itemBuilder: (context, index) {
        final college = colleges[index] as Map<String, dynamic>;
        final isSaved = _savedCollegeNames.contains(college['name']);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  college['name'] ?? '',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(college['location'] ?? ''),
                trailing: IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: isSaved ? const Color(0xFF5B3FD8) : Colors.grey,
                  ),
                  onPressed: () => _toggleSave(college),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CollegeDetailScreen(advice: college),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${college['match_percentage']}% Initial Chance',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CollegeDetailScreen(advice: college),
                        ),
                      ),
                      child: Text('View Admission Blueprint', style: GoogleFonts.poppins(color: const Color(0xFF5B3FD8), fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
