import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_service.dart';
import 'firebase_service.dart';
import 'college_detail_screen.dart';
import 'saved_colleges_screen.dart';
import 'tailored_suggestions_page.dart';
import 'college_preferences_screen.dart';

class CollegeSuggestionsScreen extends StatefulWidget {
  const CollegeSuggestionsScreen({super.key});

  @override
  State<CollegeSuggestionsScreen> createState() => _CollegeSuggestionsScreenState();
}

class _CollegeSuggestionsScreenState extends State<CollegeSuggestionsScreen> with SingleTickerProviderStateMixin {
  final AiService _aiService = GroqAiService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _gradientController;
  List<dynamic> _safetySuggestions = [];
  List<dynamic> _matchSuggestions = [];
  List<dynamic> _reachSuggestions = [];
  List<dynamic> _strengths = [];
  List<dynamic> _weaknesses = [];
  List<dynamic> _top60Roadmap = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _fetchSuggestions();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final userData = await FirebaseService.instance.getResume(userId);
      final preferences = await FirebaseService.instance.getCollegePreferences(userId);
      
      if (userData != null) {
        try {
          final data = await _aiService.getTieredCollegeSuggestions(userData, preferences: preferences);
          if (mounted) {
            setState(() {
              _safetySuggestions = data['safety'] ?? [];
              _matchSuggestions = data['match'] ?? [];
              _reachSuggestions = data['reach'] ?? [];
              _strengths = data['strengths'] ?? [];
              _weaknesses = data['weaknesses'] ?? [];
              _top60Roadmap = data['top_60_roadmap'] ?? [];
              _isLoading = false;
            });
            
            if (_safetySuggestions.isEmpty && _matchSuggestions.isEmpty && _reachSuggestions.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI returned no college suggestions. Please check your profile/preferences.')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('AI Intelligence Error: $e'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _searchSpecificCollege() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await _aiService.searchCollegesByName(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        if (results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No colleges found with that name.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching colleges: $e')),
        );
      }
    }
  }

  Future<void> _navigateToCollegeDetail(String collegeName) async {
    setState(() => _isSearching = true);
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
              SnackBar(content: Text('Error fetching college details: $e')),
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
          'College Intelligence',
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
            icon: const Icon(Icons.tune, color: Color(0xFF5B3FD8)),
            tooltip: 'Search Preferences',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CollegePreferencesScreen()),
              );
              if (result == true) {
                setState(() => _isLoading = true);
                _fetchSuggestions();
              }
            },
          ),
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
          if (_searchResults.isNotEmpty) _buildSearchResultsList(),
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
                      _buildTailoredListPreview(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTailoredListPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    Color(0xFF5B3FD8),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                    Color(0xFF5B3FD8),
                  ],
                  stops: [
                    0.0,
                    _gradientController.value,
                    _gradientController.value + 0.3 > 1.0 ? 1.0 : _gradientController.value + 0.3,
                    1.0,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B3FD8).withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tiered Suggestions',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TailoredSuggestionsPage(tieredSuggestions: {
                          'safety': _safetySuggestions,
                          'match': _matchSuggestions,
                          'reach': _reachSuggestions,
                        }),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(50),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'View 30 Matches',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildTierPreview('Reach (Top Difficulty)', _reachSuggestions),
        const SizedBox(height: 16),
        _buildTierPreview('Match (Moderate)', _matchSuggestions),
        const SizedBox(height: 16),
        _buildTierPreview('Safety (Easy)', _safetySuggestions),
      ],
    );
  }

  Widget _buildTierPreview(String title, List<dynamic> colleges) {
    if (colleges.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        const SizedBox(height: 8),
        ...colleges.take(2).map((college) {
          if (college is! Map<String, dynamic>) return const SizedBox.shrink();
          return _buildCollegeCard(college);
        }),
      ],
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
          if (item is! Map<String, dynamic>) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            );
          }
          final data = item;
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
            icon: Icon(_searchResults.isNotEmpty ? Icons.close : Icons.send, color: const Color(0xFF5B3FD8)),
            onPressed: () {
              if (_searchResults.isNotEmpty) {
                setState(() {
                  _searchResults = [];
                  _searchController.clear();
                });
              } else {
                _searchSpecificCollege();
              }
            },
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

  Widget _buildSearchResultsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final college = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.school_outlined, color: Color(0xFF5B3FD8)),
            title: Text(
              college['name'] ?? '',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              college['location'] ?? '',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
            onTap: () {
              _navigateToCollegeDetail(college['name']);
              setState(() => _searchResults = []);
            },
          );
        },
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
