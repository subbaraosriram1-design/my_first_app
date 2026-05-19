import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'firebase_service.dart';

class ExamReminderScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  const ExamReminderScreen({super.key, this.existingData});

  @override
  State<ExamReminderScreen> createState() => _ExamReminderScreenState();
}

class _ExamReminderScreenState extends State<ExamReminderScreen> {
  final List<Map<String, dynamic>> _exams = [];
  late TextEditingController _courseController;
  late TextEditingController _subjectController;
  DateTime? _selectedDateTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _courseController = TextEditingController();
    _subjectController = TextEditingController();
    if (widget.existingData != null) {
      _courseController.text = widget.existingData?['course'] ?? '';
      _subjectController.text = widget.existingData?['subject'] ?? '';
      if (widget.existingData?['examDateTime'] != null) {
        _selectedDateTime = DateTime.tryParse(widget.existingData!['examDateTime']);
      }
    }
  }

  @override
  void dispose() {
    _courseController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addExamToList() {
    if (_courseController.text.isEmpty || _subjectController.text.isEmpty || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all exam fields')),
      );
      return;
    }

    setState(() {
      _exams.add({
        'course': _courseController.text,
        'subject': _subjectController.text,
        'dateTime': _selectedDateTime!.toIso8601String(),
      });
      _courseController.clear();
      _subjectController.clear();
      _selectedDateTime = null;
    });
  }

  Future<void> _saveExams() async {
    if (_exams.isEmpty && widget.existingData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exam')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = FirebaseService.instance.currentUserId;
      if (userId == null) throw Exception("User not logged in");

      final userData = await FirebaseService.instance.getResume(userId);
      List<dynamic> reminders = List.from(userData?['reminders'] ?? []);

      if (widget.existingData != null) {
        // Single update mode
        final reminderData = {
          'id': widget.existingData!['id'],
          'type': 'exam',
          'course': _courseController.text.isNotEmpty ? _courseController.text : widget.existingData!['course'],
          'subject': _subjectController.text.isNotEmpty ? _subjectController.text : widget.existingData!['subject'],
          'examDateTime': _selectedDateTime?.toIso8601String() ?? widget.existingData!['examDateTime'],
          'createdAt': widget.existingData!['createdAt'],
          'updatedAt': DateTime.now().toIso8601String(),
        };
        final index = reminders.indexWhere((r) => r['id'] == widget.existingData!['id']);
        if (index != -1) reminders[index] = reminderData;
      }

      for (var exam in _exams) {
        reminders.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString() + _exams.indexOf(exam).toString(),
          'type': 'exam',
          'course': exam['course'],
          'subject': exam['subject'],
          'examDateTime': exam['dateTime'],
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      await FirebaseService.instance.saveResume(userId, {'reminders': reminders});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam reminders set successfully!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Set Exams', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Exam Details',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldTitle('Course/Program'),
                    TextField(
                      controller: _courseController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _buildInputDecoration('e.g. Computer Science, Grade 10'),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldTitle('Subject'),
                    TextField(
                      controller: _subjectController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _buildInputDecoration('e.g. Mathematics, Biology'),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldTitle('Date & Time'),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDateTime == null
                                  ? 'Select date and time'
                                  : DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDateTime!),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _selectedDateTime == null ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addExamToList,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Exam to List'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_exams.isNotEmpty) ...[
                      Text(
                        'Exam List (${_exams.length})',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exams.length,
                        itemBuilder: (context, index) {
                          final exam = _exams[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text('${exam['subject']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${exam['course']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                                  Text(DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(exam['dateTime'])), style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.w500)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _exams.removeAt(index)),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveExams,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save All Exams', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }
}
