import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai_service.dart';
import 'firebase_service.dart';

class TargetStepDetailScreen extends StatefulWidget {
  final String collegeName;
  final String actionTitle;
  final Color themeColor;

  const TargetStepDetailScreen({
    super.key,
    required this.collegeName,
    required this.actionTitle,
    required this.themeColor,
  });

  @override
  State<TargetStepDetailScreen> createState() => _TargetStepDetailScreenState();
}

class _TargetStepDetailScreenState extends State<TargetStepDetailScreen> {
  final AiService _aiService = GroqAiService();
  bool _isLoading = true;
  Map<String, dynamic>? _plan;

  @override
  void initState() {
    super.initState();
    _fetchActionPlan();
  }

  Future<void> _fetchActionPlan() async {
    try {
      final userId = FirebaseService.instance.currentUserId;
      Map<String, dynamic> userData = {};
      if (userId != null) {
        userData = await FirebaseService.instance.getResume(userId) ?? {};
      }

      final plan = await _aiService.getTargetActionPlan(
        widget.collegeName,
        widget.actionTitle,
        userData,
      );

      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Action Plan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.themeColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildStepsSection(),
                  const SizedBox(height: 32),
                  _buildResourcesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.themeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.themeColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.actionTitle,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.themeColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _plan?['overview'] ?? 'Detailed roadmap for your admission success.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    final List<dynamic> steps = _plan?['steps'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_list_bulleted_rounded, color: widget.themeColor, size: 22),
            const SizedBox(width: 12),
            Text(
              'What you have to do',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.themeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  step.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Resources',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildResourceButton(
          'Search on Google',
          Icons.search,
          const Color(0xFF4285F4),
          _plan?['google_search_link'],
        ),
        const SizedBox(height: 12),
        _buildResourceButton(
          'Watch on YouTube',
          Icons.play_circle_fill_rounded,
          const Color(0xFFFF0000),
          _plan?['youtube_search_link'],
        ),
      ],
    );
  }

  Widget _buildResourceButton(String label, IconData icon, Color color, String? url) {
    return InkWell(
      onTap: () async {
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.open_in_new_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
