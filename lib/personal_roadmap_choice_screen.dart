import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_personal_roadmap_screen.dart';
import 'personal_roadmap_list_screen.dart';

class PersonalRoadmapChoiceScreen extends StatelessWidget {
  const PersonalRoadmapChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Personal Roadmaps', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChoiceCard(
              context,
              title: 'Add New',
              description: 'Create a new personal growth goal and get an AI plan.',
              icon: Icons.add_circle_outline,
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPersonalRoadmapScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _buildChoiceCard(
              context,
              title: 'See Added Ones',
              description: 'View and manage your existing personal roadmaps.',
              icon: Icons.list_alt,
              color: const Color(0xFF065F46),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PersonalRoadmapListScreen()),
              ),
            ),
          ],
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
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
