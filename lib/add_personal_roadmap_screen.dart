import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'ai_service.dart';
import 'firebase_service.dart';
import 'personal_plan_detail_screen.dart';

class AddPersonalRoadmapScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const AddPersonalRoadmapScreen({super.key, this.initialData});

  @override
  State<AddPersonalRoadmapScreen> createState() => _AddPersonalRoadmapScreenState();
}

class _AddPersonalRoadmapScreenState extends State<AddPersonalRoadmapScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  final AiService _aiService = GroqAiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _descController.text = widget.initialData!['description'] ?? '';
      if (widget.initialData!['targetDate'] != null) {
        _selectedDate = DateTime.tryParse(widget.initialData!['targetDate']);
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = FirebaseService.instance.currentUserId!;
      final userData = await FirebaseService.instance.getResume(userId);
      final List<String> skills = List<String>.from(userData?['skills'] ?? []);

      final plan = await _aiService.generatePersonalPlan(
        _titleController.text.trim(),
        _descController.text.trim(),
        skills,
        targetCompletionDate: _selectedDate,
      );

      final roadmapData = {
        'id': widget.initialData?['id'],
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'plan': plan,
        'targetDate': _selectedDate?.toIso8601String(),
        'status': widget.initialData?['status'] ?? 'Active',
        'isCompleted': widget.initialData?['isCompleted'] ?? false,
        'createdAt': widget.initialData?['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await FirebaseService.instance.savePersonalRoadmap(userId, roadmapData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalPlanDetailScreen(roadmapData: roadmapData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'Add Personal Goal' : 'Edit Personal Goal', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What do you want to achieve?',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Describe your personal project or goal. AI will craft a unique plan for you.',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Title', Icons.emoji_events_outlined),
                    validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descController,
                    maxLines: 5,
                    decoration: _inputDecoration('Description', Icons.description_outlined),
                    validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Target Completion Date',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate == null 
                                ? 'Select completion date' 
                                : DateFormat('MMMM dd, yyyy').format(_selectedDate!),
                            style: GoogleFonts.poppins(
                              color: _selectedDate == null ? Colors.grey.shade600 : const Color(0xFF1E293B),
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _generatePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Set Plan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF10B981))),
    );
  }
}
