import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';

class CollegeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> advice;
  const CollegeDetailScreen({super.key, required this.advice});

  @override
  State<CollegeDetailScreen> createState() => _CollegeDetailScreenState();
}

class _CollegeDetailScreenState extends State<CollegeDetailScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final saved = await FirebaseService.instance.getSavedColleges(userId);
      if (mounted) {
        setState(() {
          _isSaved = saved.any((c) => c['name'] == widget.advice['name']);
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    if (_isSaved) {
      await FirebaseService.instance.removeSavedCollege(userId, widget.advice['name']);
    } else {
      await FirebaseService.instance.saveCollege(userId, widget.advice);
    }

    if (mounted) {
      setState(() {
        _isSaved = !_isSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isSaved ? 'College saved!' : 'College removed from saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.advice['name'] ?? 'College Detail',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
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
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_outline,
              color: _isSaved ? const Color(0xFF5B3FD8) : const Color(0xFF64748B),
            ),
            onPressed: _toggleSave,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChancesBadge(),
            const SizedBox(height: 24),
            _buildDetailedSection('Comprehensive Match Analysis', widget.advice['match_analysis'], Icons.analytics_outlined, const Color(0xFF5B3FD8)),
            const SizedBox(height: 20),
            if (widget.advice['cds_insight'] != null) ...[
              _buildDetailedSection('CDS Key Insight', widget.advice['cds_insight'], Icons.fact_check_outlined, const Color(0xFF10B981)),
              const SizedBox(height: 20),
            ],
            _buildDetailedSection('Academic Strategy & Rigor', widget.advice['academic_strategy'], Icons.menu_book_outlined, const Color(0xFF3B82F6)),
            const SizedBox(height: 20),
            _buildDetailedSection('Admission Roadmap (Next 12-24 Months)', widget.advice['action_plan'], Icons.assignment_outlined, const Color(0xFFF59E0B)),
            const SizedBox(height: 20),
            _buildDetailedSection('Holistic Narrative & Positioning', widget.advice['holistic_narrative'], Icons.record_voice_over_outlined, const Color(0xFFEC4899)),
            const SizedBox(height: 20),
            _buildSuggestedActivities(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChancesBadge() {
    final String chances = widget.advice['chances'] ?? 'Assessment';
    Color color = const Color(0xFF64748B);
    if (chances.toLowerCase().contains('reach')) color = const Color(0xFFEF4444);
    if (chances.toLowerCase().contains('match')) color = const Color(0xFF10B981);
    if (chances.toLowerCase().contains('safety')) color = const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            'Admission Chances: $chances',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedSection(String title, String? content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content ?? 'No details available.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedActivities() {
    final List<dynamic> activities = widget.advice['suggested_extracurriculars'] ?? [];
    if (activities.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 12),
              Text(
                'Target Extracurriculars',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: activities.map((activity) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: Text(
                  activity.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
