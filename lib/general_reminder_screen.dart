import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'firebase_service.dart';

class GeneralReminderScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  const GeneralReminderScreen({super.key, this.existingData});

  @override
  State<GeneralReminderScreen> createState() => _GeneralReminderScreenState();
}

class _GeneralReminderScreenState extends State<GeneralReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _keywordController;
  DateTime? _selectedDateTime;
  bool _isImportant = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.existingData?['description']);
    _keywordController = TextEditingController(text: widget.existingData?['keyword']);
    _isImportant = widget.existingData?['isImportant'] ?? false;
    if (widget.existingData?['toBeDoneBy'] != null) {
      _selectedDateTime = DateTime.tryParse(widget.existingData!['toBeDoneBy']);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _keywordController.dispose();
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

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select "to be done by" date and time')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = FirebaseService.instance.currentUserId;
      if (userId == null) throw Exception("User not logged in");

      final reminderData = {
        'id': widget.existingData?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'general',
        'description': _descriptionController.text,
        'keyword': _keywordController.text,
        'toBeDoneBy': _selectedDateTime!.toIso8601String(),
        'isImportant': _isImportant,
        'createdAt': widget.existingData?['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'attachments': widget.existingData?['attachments'] ?? [],
      };

      final userData = await FirebaseService.instance.getResume(userId);
      List<dynamic> reminders = List.from(userData?['reminders'] ?? []);
      
      if (widget.existingData != null) {
        final index = reminders.indexWhere((r) => r['id'] == widget.existingData!['id']);
        if (index != -1) {
          reminders[index] = reminderData;
        } else {
          reminders.add(reminderData);
        }
      } else {
        reminders.add(reminderData);
      }

      await FirebaseService.instance.saveResume(userId, {'reminders': reminders});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('General reminder set successfully!'),
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
        title: Text('General Reminder', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldTitle('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: _buildInputDecoration('What needs to be done?'),
                  validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 20),
                _buildFieldTitle('Keyword'),
                TextFormField(
                  controller: _keywordController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: _buildInputDecoration('e.g. Shopping, Meeting, Personal'),
                  validator: (v) => v!.isEmpty ? 'Please enter a keyword' : null,
                ),
                const SizedBox(height: 20),
                _buildFieldTitle('To be done by'),
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
                        const Icon(Icons.alarm, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDateTime == null
                              ? 'Select deadline'
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
                const SizedBox(height: 20),
                _buildFieldTitle('Attachments'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.grey, size: 18),
                      const SizedBox(width: 12),
                      Text('Add attachments', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                      const Spacer(),
                      const Icon(Icons.add_circle_outline, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isImportant ? Colors.red.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isImportant ? Colors.red.withValues(alpha: 0.2) : Colors.grey.shade200),
                  ),
                  child: CheckboxListTile(
                    title: Text('Mark as Important', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _isImportant ? Colors.red : const Color(0xFF1E293B))),
                    value: _isImportant,
                    activeColor: Colors.red,
                    onChanged: (val) => setState(() => _isImportant = val ?? false),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    controlAffinity: ListTileControlAffinity.leading,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Save Reminder', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
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
