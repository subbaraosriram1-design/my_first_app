import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';

class CollegePreferencesScreen extends StatefulWidget {
  const CollegePreferencesScreen({super.key});

  @override
  State<CollegePreferencesScreen> createState() => _CollegePreferencesScreenState();
}

class _CollegePreferencesScreenState extends State<CollegePreferencesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Preferences State
  String _effortLevel = 'Medium';
  String _distanceRange = 'No Preference';
  final List<String> _selectedSubjects = [];
  String _selectiveness = 'No Preference';
  String _financialAid = 'Medium Importance';
  String _campusSetting = 'No Preference';

  final List<String> _subjectsList = [
    'Computer Science', 'Artificial Intelligence', 'Data Science', 
    'Medicine', 'Law', 'Business Administration', 'Mechanical Engineering',
    'Psychology', 'Fine Arts', 'Economics', 'Architecture', 'Biology'
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final prefs = await FirebaseService.instance.getCollegePreferences(userId);
      if (prefs != null && mounted) {
        setState(() {
          _effortLevel = prefs['effortLevel'] ?? 'Medium';
          _distanceRange = prefs['distanceRange'] ?? 'No Preference';
          _selectedSubjects.clear();
          _selectedSubjects.addAll(List<String>.from(prefs['subjects'] ?? []));
          _selectiveness = prefs['selectiveness'] ?? 'No Preference';
          _financialAid = prefs['financialAid'] ?? 'Medium Importance';
          _campusSetting = prefs['campusSetting'] ?? 'No Preference';
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    setState(() => _isSaving = true);
    
    final prefs = {
      'effortLevel': _effortLevel,
      'distanceRange': _distanceRange,
      'subjects': _selectedSubjects,
      'selectiveness': _selectiveness,
      'financialAid': _financialAid,
      'campusSetting': _campusSetting,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await FirebaseService.instance.saveCollegePreferences(userId, prefs);
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved! Your suggestions will update.')),
      );
      Navigator.pop(context, true); // Return true to indicate change
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Search Preferences', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Effort & Commitment', 'How hard do you want to work for admission?'),
            _buildChoiceChipGroup(['Low', 'Medium', 'High'], _effortLevel, (val) => setState(() => _effortLevel = val)),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Distance Range', 'Preferred distance from your location?'),
            _buildChoiceChipGroup(['< 50km', '< 200km', '< 1000km', 'No Preference'], _distanceRange, (val) => setState(() => _distanceRange = val)),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Subjects of Interest', 'Select up to 3 major areas'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subjectsList.map((subject) {
                final isSelected = _selectedSubjects.contains(subject);
                return FilterChip(
                  label: Text(subject, style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        if (_selectedSubjects.length < 3) _selectedSubjects.add(subject);
                      } else {
                        _selectedSubjects.remove(subject);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF5B3FD8),
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade50,
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Admission Selectiveness', 'What type of institutions?'),
            _buildChoiceChipGroup(['Selective', 'Moderately Selective', 'Open Enrollment', 'No Preference'], _selectiveness, (val) => setState(() => _selectiveness = val)),

            const SizedBox(height: 32),
            _buildSectionHeader('Financial Aid Importance', 'How critical is funding?'),
            _buildChoiceChipGroup(['Critical', 'Medium Importance', 'Not a Priority'], _financialAid, (val) => setState(() => _financialAid = val)),

            const SizedBox(height: 32),
            _buildSectionHeader('Campus Setting', 'Where do you see yourself?'),
            _buildChoiceChipGroup(['Urban', 'Suburban', 'Rural', 'No Preference'], _campusSetting, (val) => setState(() => _campusSetting = val)),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3FD8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Save Preferences', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildChoiceChipGroup(List<String> options, String selectedValue, Function(String) onSelected) {
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final isSelected = selectedValue == opt;
        return ChoiceChip(
          label: Text(opt, style: GoogleFonts.poppins(fontSize: 13, color: isSelected ? Colors.white : Colors.black87)),
          selected: isSelected,
          onSelected: (val) { if (val) onSelected(opt); },
          selectedColor: const Color(0xFF5B3FD8),
          backgroundColor: Colors.grey.shade50,
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }
}
