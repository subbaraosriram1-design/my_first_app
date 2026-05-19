import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assignment_reminder_screen.dart';
import 'exam_reminder_screen.dart';
import 'general_reminder_screen.dart';
import 'all_reminders_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Reminders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stay on Top of Your Goals',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your academic and personal tasks with ease.',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14, 
                color: Colors.grey.shade600
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionCard(
              context,
              title: 'See all reminders',
              description: 'View, search, and manage all your tasks in one place.',
              icon: Icons.list_alt_rounded,
              color: const Color(0xFF10B981), // Emerald Green
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllRemindersScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              title: 'Set exam',
              description: 'Schedule your upcoming exams and subjects.',
              icon: Icons.school_outlined,
              color: const Color(0xFF0F172A), // Dark Slate
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExamReminderScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              title: 'Set assignment',
              description: 'Keep track of your project and homework deadlines.',
              icon: Icons.assignment_outlined,
              color: const Color(0xFF059669), // Darker Green
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AssignmentReminderScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              title: 'General',
              description: 'Add custom reminders for any other task.',
              icon: Icons.push_pin_outlined,
              color: const Color(0xFF334155), // Slate Gray
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GeneralReminderScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: isSmallScreen ? 24 : 28),
            ),
            SizedBox(width: isSmallScreen ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 11 : 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 14),
          ],
        ),
      ),
    );
  }
}
