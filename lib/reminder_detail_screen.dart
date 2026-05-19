import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'assignment_reminder_screen.dart';
import 'exam_reminder_screen.dart';
import 'general_reminder_screen.dart';

class ReminderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> reminder;

  const ReminderDetailScreen({super.key, required this.reminder});

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  late Map<String, dynamic> _currentReminder;

  @override
  void initState() {
    super.initState();
    _currentReminder = widget.reminder;
  }

  void _editReminder() async {
    Widget screen;
    if (_currentReminder['type'] == 'exam') {
      screen = ExamReminderScreen(existingData: _currentReminder);
    } else if (_currentReminder['type'] == 'assignment') {
      screen = AssignmentReminderScreen(existingData: _currentReminder);
    } else {
      screen = GeneralReminderScreen(existingData: _currentReminder);
    }

    await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    // Ideally we should reload from Firestore here if we want to reflect changes immediately
    // For now, let's assume the user might want to see the updated details.
    // If they saved, they'll likely go back to the list anyway.
    // But let's try to reload if possible.
  }

  @override
  Widget build(BuildContext context) {
    final type = _currentReminder['type'];
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Reminder Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF10B981)),
            onPressed: _editReminder,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _getTitle(_currentReminder),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type.toString().toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildDetailRow('Date & Time', _getDateStr(_currentReminder), Icons.calendar_today, color),
            if (_currentReminder['course'] != null) _buildDetailRow('Course', _currentReminder['course'], Icons.school_outlined, color),
            if (_currentReminder['description'] != null) _buildDetailRow('Description', _currentReminder['description'], Icons.description_outlined, color),
            if (_currentReminder['additionalDetails'] != null && _currentReminder['additionalDetails'].toString().isNotEmpty)
              _buildDetailRow('Additional Info', _currentReminder['additionalDetails'], Icons.info_outline, color),
            if (_currentReminder['isImportant'] == true)
              _buildDetailRow('Priority', 'High Importance', Icons.priority_high, Colors.red),
            const SizedBox(height: 24),
            _buildDetailRow('Created On', DateFormat('MMM dd, yyyy').format(DateTime.parse(_currentReminder['createdAt'])), Icons.history, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF1E293B), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type == 'exam') return const Color(0xFF0F172A);
    if (type == 'assignment') return const Color(0xFF059669);
    return const Color(0xFF475569);
  }

  IconData _getTypeIcon(String type) {
    if (type == 'exam') return Icons.school_outlined;
    if (type == 'assignment') return Icons.assignment_outlined;
    return Icons.push_pin_outlined;
  }

  String _getTitle(Map<String, dynamic> r) {
    if (r['type'] == 'exam') return r['subject'] ?? 'Exam';
    if (r['type'] == 'assignment') return r['name'] ?? 'Assignment';
    return r['keyword'] ?? 'General Task';
  }

  String _getDateStr(Map<String, dynamic> r) {
    String dateRaw = '';
    if (r['type'] == 'exam') {
      dateRaw = r['examDateTime'];
    } else if (r['type'] == 'assignment') {
      dateRaw = r['submissionDateTime'];
    } else {
      dateRaw = r['toBeDoneBy'];
    }
    
    return DateFormat('EEEE, MMM dd, yyyy - hh:mm a').format(DateTime.parse(dateRaw));
  }
}
