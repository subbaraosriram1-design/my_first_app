import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recommendations_list_screen.dart';
import 'events_swipe_screen.dart';

class NearbyYouScreen extends StatelessWidget {
  const NearbyYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Nearby You', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore Local Opportunities',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalized recommendations based on your profile and interests.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            _buildCategoryButton(
              context,
              title: 'Jobs',
              icon: Icons.work,
              color: const Color(0xFF5B3FD8),
            ),
            const SizedBox(height: 16),
            _buildCategoryButton(
              context,
              title: 'Internships',
              icon: Icons.assignment,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 16),
            _buildCategoryButton(
              context,
              title: 'Courses / Coaching',
              icon: Icons.school,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildCategoryButton(
              context,
              title: 'Certifications',
              icon: Icons.verified,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildCategoryButton(
              context,
              title: 'Events and Activities',
              icon: Icons.event,
              color: Colors.pink,
              isEvent: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    bool isEvent = false,
  }) {
    return InkWell(
      onTap: () {
        if (isEvent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventsSwipeScreen(category: title),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecommendationsListScreen(category: title),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }
}
