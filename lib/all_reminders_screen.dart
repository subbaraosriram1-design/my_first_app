import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'firebase_service.dart';
import 'assignment_reminder_screen.dart';
import 'exam_reminder_screen.dart';
import 'general_reminder_screen.dart';
import 'reminder_detail_screen.dart';

class AllRemindersScreen extends StatefulWidget {
  const AllRemindersScreen({super.key});

  @override
  State<AllRemindersScreen> createState() => _AllRemindersScreenState();
}

class _AllRemindersScreenState extends State<AllRemindersScreen> {
  List<dynamic> _allReminders = [];
  List<dynamic> _filteredReminders = [];
  bool _isLoading = true;
  String _selectedType = 'All';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (mounted) {
        setState(() {
          _allReminders = List.from(data?['reminders'] ?? []);
          _applyFilters();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReminders = _allReminders.where((r) {
        final typeMatch = _selectedType == 'All' || r['type'] == _selectedType.toLowerCase();
        
        final query = _searchController.text.toLowerCase();
        bool searchMatch = true;
        if (query.isNotEmpty) {
          if (r['type'] == 'exam') {
            searchMatch = (r['subject'] ?? '').toLowerCase().contains(query) || 
                          (r['course'] ?? '').toLowerCase().contains(query);
          } else if (r['type'] == 'assignment') {
            searchMatch = (r['name'] ?? '').toLowerCase().contains(query) || 
                          (r['description'] ?? '').toLowerCase().contains(query);
          } else {
            searchMatch = (r['description'] ?? '').toLowerCase().contains(query) || 
                          (r['keyword'] ?? '').toLowerCase().contains(query);
          }
        }
        
        return typeMatch && searchMatch;
      }).toList();

      _filteredReminders.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
    });
  }

  Future<void> _deleteReminder(String id) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      setState(() => _isLoading = true);
      _allReminders.removeWhere((r) => r['id'] == id);
      await FirebaseService.instance.saveResume(userId, {'reminders': _allReminders});
      _applyFilters();
      setState(() => _isLoading = false);
    }
  }

  void _editReminder(Map<String, dynamic> r) async {
    Widget screen;
    if (r['type'] == 'exam') {
      screen = ExamReminderScreen(existingData: r);
    } else if (r['type'] == 'assignment') {
      screen = AssignmentReminderScreen(existingData: r);
    } else {
      screen = GeneralReminderScreen(existingData: r);
    }

    await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('All Reminders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 24, vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedType,
                      style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14),
                      items: ['All', 'Exam', 'Assignment', 'General'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedType = val!);
                        _applyFilters();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => _applyFilters(),
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by keyword, subject, name...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF10B981)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _filteredReminders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 24),
                        itemCount: _filteredReminders.length,
                        itemBuilder: (context, index) {
                          final r = _filteredReminders[index];
                          return _buildReminderCard(r);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> r) {
    Color typeColor = const Color(0xFF10B981);
    IconData icon = Icons.notifications;
    String title = '';
    String subtitle = '';
    String dateStr = '';

    if (r['type'] == 'exam') {
      typeColor = const Color(0xFF0F172A);
      icon = Icons.school_outlined;
      title = '${r['subject']}';
      subtitle = 'Course: ${r['course']}';
      dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(r['examDateTime']));
    } else if (r['type'] == 'assignment') {
      typeColor = const Color(0xFF059669);
      icon = Icons.assignment_outlined;
      title = '${r['name']}';
      subtitle = r['description'];
      dateStr = 'Due: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(r['submissionDateTime']))}';
    } else {
      typeColor = const Color(0xFF475569);
      icon = Icons.push_pin_outlined;
      title = r['keyword'] ?? 'General';
      subtitle = r['description'];
      dateStr = 'By: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(r['toBeDoneBy']))}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: typeColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B)))),
            if (r['isImportant'] == true)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('IMPORTANT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 8)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(dateStr, style: GoogleFonts.poppins(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                if (r['description'] != null) ...[
                  Text('Description', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text(r['description'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800)),
                  const SizedBox(height: 12),
                ],
                if (r['additionalDetails'] != null && r['additionalDetails'].toString().isNotEmpty) ...[
                  Text('Additional Info', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text(r['additionalDetails'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800)),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReminderDetailScreen(reminder: r))),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Details', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _editReminder(r),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteReminder(r['id']),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: Colors.red, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No reminders found',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
            if (_searchController.text.isNotEmpty || _selectedType != 'All')
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedType = 'All';
                    _applyFilters();
                  });
                },
                child: Text('Clear filters', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF10B981))),
              ),
          ],
        ),
      ),
    );
  }
}
