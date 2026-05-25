import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_service.dart';
import 'firebase_service.dart';
import 'college_detail_screen.dart';
import 'saved_colleges_screen.dart';

class CollegeSuggestionsScreen extends StatefulWidget {
  const CollegeSuggestionsScreen({super.key});

  @override
  State<CollegeSuggestionsScreen> createState() => _CollegeSuggestionsScreenState();
}

class _CollegeSuggestionsScreenState extends State<CollegeSuggestionsScreen> {
  final AiService _aiService = GroqAiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];
  List<dynamic> _strengths = [];
  List<dynamic> _weaknesses = [];
  List<dynamic> _top60Roadmap = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final userData = await FirebaseService.instance.getResume(userId);
      if (userData != null) {
        try {
          final data = await _aiService.getCollegeSuggestions(userData);
          if (mounted) {
            setState(() {
              _suggestions = data['suggestions'] ?? [];
              _strengths = data['strengths'] ?? [];
              _weaknesses = data['weaknesses'] ?? [];
              _top60Roadmap = data['top_60_roadmap'] ?? [];
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error fetching suggestions: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _searchSpecificCollege() async {
    final collegeName = _searchController.text.trim();
    if (collegeName.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final userData = await FirebaseService.instance.getResume(userId);
      if (userData != null) {
        try {
          final advice = await _aiService.getSpecificCollegeAdvice(userData, collegeName);
          if (mounted) {
            setState(() => _isSearching = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CollegeDetailScreen(advice: advice),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isSearching = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error searching college: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'College Suggestions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined, color: Color(0xFF5B3FD8)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SavedCollegesScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAnalysisSection(),
                      const SizedBox(height: 24),
                      _buildTop60Section(),
                      const SizedBox(height: 24),
                      if (_isSearching)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: CircularProgressIndicator(color: Color(0xFF5B3FD8)),
                          ),
                        ),
                      Text(
                        'Tailored Suggestions',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._suggestions.map((college) => _buildCollegeCard(college as Map<String, dynamic>)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deep Profile Analysis',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on Top 50-60 Admission Standards',
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          _buildAnalysisRow('Competitive Strengths', _strengths, Icons.check_circle, Colors.green),
          const Divider(height: 40),
          _buildAnalysisRow('Strategic Gaps', _weaknesses, Icons.warning_amber_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String title, List<dynamic> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) {
          final data = item as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(left: 28, bottom: 8),
              title: Text(
                data['title'] ?? '',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
              ),
              leading: const Icon(Icons.arrow_right, color: Color(0xFF64748B)),
              children: [
                Text(
                  data['detailed_explanation'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569), height: 1.5),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTop60Section() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: const Color(0xFFF1F5F9),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(
          'Top 50-60 Admission Roadmap',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
        ),
        subtitle: Text(
          'Specific milestones for elite institutions',
          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                ..._top60Roadmap.map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified, color: Color(0xFF5B3FD8), size: 16),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              req.toString(),
                              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF334155), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search specific college (e.g. Harvard)',
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF5B3FD8)),
            onPressed: _searchSpecificCollege,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
        onSubmitted: (_) => _searchSpecificCollege(),
      ),
    );
  }

  Widget _buildCollegeCard(Map<String, dynamic> college) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(5),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    college['name'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    college['location'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${college['match_percentage']}% Match',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildSectionTitle('Why this matches'),
                const SizedBox(height: 4),
                Text(
                  college['match_reason'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF334155), height: 1.5),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('How to achieve'),
                const SizedBox(height: 4),
                Text(
                  college['how_to_achieve'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF334155), height: 1.5),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Suitable Courses'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (college['suitable_courses'] as List? ?? []).map((course) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        course.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
    );
  }
}
