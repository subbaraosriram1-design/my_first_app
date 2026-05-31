import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'career_roadmap_list_screen.dart';
import 'personal_roadmap_choice_screen.dart';
import 'saved_colleges_screen.dart';

class RoadmapChoiceScreen extends StatelessWidget {
  const RoadmapChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Roadmaps', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Path',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your professional and personal growth roadmaps.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              _buildChoiceCard(
                context,
                title: 'Career Roadmaps',
                description: 'Focus on your professional skills and career goals.',
                icon: Icons.work_outline,
                color: const Color(0xFF5B3FD8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CareerRoadmapListScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _buildChoiceCard(
                context,
                title: 'Personal Roadmaps',
                description: 'Track your personal projects, hobbies, and life goals.',
                icon: Icons.person_outline,
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PersonalRoadmapChoiceScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _buildChoiceCard(
                context,
                title: 'College Roadmaps',
                description: 'Track your saved colleges and admission strategies.',
                icon: Icons.school_outlined,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SavedCollegesScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 16),
          ],
        ),
      ),
    );
  }
}
