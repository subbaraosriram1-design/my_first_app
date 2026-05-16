import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'firebase_service.dart';
import 'models.dart';

class ResumeBuilderPage extends StatefulWidget {
  final String username;
  const ResumeBuilderPage({super.key, required this.username});

  @override
  State<ResumeBuilderPage> createState() => _ResumeBuilderPageState();
}

class _ResumeBuilderPageState extends State<ResumeBuilderPage> {
  int _currentStep = 0;
  final int _totalSteps = 6;
  final List<Project> _projects = [];
  final List<Education> _educationList = [];
  final List<String> _skills = [];
  final List<String> _studentInterests = [];
  final List<Certification> _certifications = [];
  final List<TestScore> _testScores = [];
  String? _profileImageBase64;
  bool _isLoading = true;

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _taglineController = TextEditingController();
  final _summaryController = TextEditingController();
  final _schoolController = TextEditingController();
  final _degreeController = TextEditingController();
  final _startYearController = TextEditingController();
  final _endYearController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _skillController = TextEditingController();
  final _studentInterestController = TextEditingController();
  final _certNameController = TextEditingController();
  final _testNameController = TextEditingController();
  final _testScoreController = TextEditingController();

  String? _selectedSkillForCert;
  final List<String> _certLevels = ['Basic', 'Intermediate', 'Advanced'];
  String _selectedCertLevel = 'Basic';

  @override
  void initState() {
    super.initState();
    _loadResumeData();
  }

  Future<void> _loadResumeData() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (data != null) {
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _taglineController.text = data['tagline'] ?? '';
          _summaryController.text = data['summary'] ?? '';
          _profileImageBase64 = data['profileImage'];

          if (data['projects'] != null) {
            _projects.clear();
            _projects.addAll((data['projects'] as List).map((p) => Project.fromJson(p as Map<String, dynamic>)));
          }
          if (data['educationList'] != null) {
            _educationList.clear();
            _educationList.addAll((data['educationList'] as List).map((e) => Education.fromJson(e as Map<String, dynamic>)));
          }
          if (data['skills'] != null) {
            _skills.clear();
            _skills.addAll(List<String>.from(data['skills']));
          }
          if (data['hobbies'] != null && data['hobbies'] is List) {
            _studentInterests.clear();
            _studentInterests.addAll((data['hobbies'] as List).map((e) => e.toString()));
          }
          if (data['certifications'] != null) {
            _certifications.clear();
            _certifications.addAll((data['certifications'] as List).map((c) => Certification.fromJson(c as Map<String, dynamic>)));
          }
          if (data['testScores'] != null) {
            _testScores.clear();
            _testScores.addAll((data['testScores'] as List).map((s) => TestScore.fromJson(s as Map<String, dynamic>)));
          }
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveResumeData() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      await FirebaseService.instance.saveResume(userId, {
        'fullName': _nameController.text,
        'email': _emailController.text,
        'tagline': _taglineController.text,
        'summary': _summaryController.text,
        'profileImage': _profileImageBase64,
        'projects': _projects.map((p) => p.toJson()).toList(),
        'educationList': _educationList.map((e) => e.toJson()).toList(),
        'skills': _skills,
        'hobbies': _studentInterests,
        'certifications': _certifications.map((c) => c.toJson()).toList(),
        'testScores': _testScores.map((s) => s.toJson()).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resume synced to cloud!')));
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      if (result.files.single.bytes != null) {
        setState(() {
          _profileImageBase64 = base64Encode(result.files.single.bytes!);
        });
      }
    }
  }

  void _addProject() {
    setState(() {
      _projects.add(Project());
    });
  }

  void _removeProject(int index) {
    setState(() {
      _projects.removeAt(index);
    });
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _addStudentInterest() {
    final interest = _studentInterestController.text.trim();
    if (interest.isNotEmpty && !_studentInterests.contains(interest)) {
      setState(() {
        _studentInterests.add(interest);
        _studentInterestController.clear();
      });
    }
  }

  void _addCertification() {
    final name = _certNameController.text.trim();
    if (name.isNotEmpty && _selectedSkillForCert != null) {
      setState(() {
        _certifications.add(Certification(
          name: name,
          skill: _selectedSkillForCert!,
          level: _selectedCertLevel,
        ));
        _certNameController.clear();
        _selectedSkillForCert = null;
        _selectedCertLevel = 'Basic';
      });
    }
  }

  void _addTestScore() {
    final name = _testNameController.text.trim();
    final score = _testScoreController.text.trim();
    if (name.isNotEmpty && score.isNotEmpty) {
      setState(() {
        _testScores.add(TestScore(testName: name, score: score, date: DateFormat('MMM yyyy').format(DateTime.now())));
        _testNameController.clear();
        _testScoreController.clear();
      });
    }
  }

  void _addEducation() {
    final school = _schoolController.text.trim();
    if (school.isNotEmpty) {
      setState(() {
        _educationList.add(Education(
          school: school,
          level: _degreeController.text,
          yearFrom: _startYearController.text,
          yearTo: _endYearController.text,
          additionalInfo: _additionalInfoController.text,
        ));
        _schoolController.clear();
        _degreeController.clear();
        _startYearController.clear();
        _endYearController.clear();
        _additionalInfoController.clear();
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _saveResumeData();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Cloud Resume Builder', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: _previousStep),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          const SizedBox(height: 16),
          _buildStepIndicator(),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _buildCurrentStepContent())),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 6,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (_currentStep + 1) / _totalSteps,
        child: Container(color: const Color(0xFF5B3FD8)),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Step ${_currentStep + 1} of $_totalSteps', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(_getStepTitle(), style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF5B3FD8), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Personal Info';
      case 1: return 'Education';
      case 2: return 'Projects';
      case 3: return 'Skills & Student Interests';
      case 4: return 'Test Scores';
      case 5: return 'Certifications';
      default: return '';
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(child: OutlinedButton(onPressed: _previousStep, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('Back', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)))),
            const SizedBox(width: 16),
          ],
          Expanded(child: ElevatedButton(onPressed: _nextStep, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B3FD8), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text(_currentStep == _totalSteps - 1 ? 'Finish' : 'Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)))),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0: return _buildPersonalInfoStep();
      case 1: return _buildEducationStep();
      case 2: return _buildProjectsStep();
      case 3: return _buildSkillsStudentInterestsStep();
      case 4: return _buildTestScoresStep();
      case 5: return _buildCertificationsStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickProfileImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: _profileImageBase64 != null ? MemoryImage(base64Decode(_profileImageBase64!)) : null,
            child: _profileImageBase64 == null ? const Icon(Icons.add_a_photo_outlined, size: 30, color: Color(0xFF5B3FD8)) : null,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(_nameController, 'Full Name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(_taglineController, 'Tagline', Icons.label_outline),
        const SizedBox(height: 16),
        _buildTextField(_emailController, 'Email', Icons.email),
        const SizedBox(height: 16),
        _buildTextField(_summaryController, 'Summary', Icons.description_outlined, maxLines: 3),
      ],
    );
  }

  Widget _buildEducationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._educationList.map((edu) => _buildCard(title: edu.school, subtitle: '${edu.degree} (${edu.startYear} - ${edu.endYear})', onDelete: () => setState(() => _educationList.remove(edu)))),
        const SizedBox(height: 16),
        _buildTextField(_schoolController, 'School/University', Icons.school_outlined),
        const SizedBox(height: 16),
        _buildTextField(_degreeController, 'Degree/Grade', Icons.workspace_premium_outlined),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _buildTextField(_startYearController, 'Start Year', Icons.calendar_today_outlined)), const SizedBox(width: 16), Expanded(child: _buildTextField(_endYearController, 'End Year', Icons.calendar_today_outlined))]),
        const SizedBox(height: 16),
        _buildTextField(_additionalInfoController, 'Additional Info', Icons.info_outline, maxLines: 2),
        const SizedBox(height: 16),
        _buildActionButton('Add Education', Icons.add, _addEducation),
      ],
    );
  }

  Widget _buildProjectsStep() {
    return Column(
      children: [
        ..._projects.asMap().entries.map((entry) {
          int idx = entry.key;
          Project project = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Project ${idx + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeProject(idx))]),
                const SizedBox(height: 16),
                _buildTextField(null, 'Project Title', Icons.title, initialValue: project.title, onChanged: (v) => project.title = v),
                const SizedBox(height: 16),
                _buildTextField(null, 'Description', Icons.description, maxLines: 3, initialValue: project.description, onChanged: (v) => project.description = v),
              ],
            ),
          );
        }),
        _buildActionButton('Add Project', Icons.add, _addProject),
      ],
    );
  }

  Widget _buildSkillsStudentInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skills', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _buildTextField(_skillController, 'Skill name', Icons.bolt_outlined)), const SizedBox(width: 8), _buildSmallAddButton(_addSkill)]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: _skills.map((skill) => Chip(label: Text(skill), onDeleted: () => setState(() => _skills.remove(skill)), backgroundColor: const Color(0xFF5B3FD8).withValues(alpha: 0.1), side: BorderSide.none)).toList()),
        const SizedBox(height: 32),
        Text('Student Interests', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _buildTextField(_studentInterestController, 'Interest name', Icons.star_border_outlined)), const SizedBox(width: 8), _buildSmallAddButton(_addStudentInterest)]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: _studentInterests.map((interest) => Chip(label: Text(interest), onDeleted: () => setState(() => _studentInterests.remove(interest)), backgroundColor: Colors.orange.withValues(alpha: 0.1), side: BorderSide.none)).toList()),
      ],
    );
  }

  Widget _buildTestScoresStep() {
    return Column(
      children: [
        ..._testScores.map((score) => _buildCard(title: score.testName, subtitle: 'Score: ${score.score}', onDelete: () => setState(() => _testScores.remove(score)))),
        const SizedBox(height: 16),
        _buildTextField(_testNameController, 'Test Name (e.g. GED)', Icons.assignment_outlined),
        const SizedBox(height: 16),
        _buildTextField(_testScoreController, 'Score', Icons.grade_outlined),
        const SizedBox(height: 16),
        _buildActionButton('Add Test Score', Icons.add, _addTestScore),
      ],
    );
  }

  Widget _buildCertificationsStep() {
    return Column(
      children: [
        ..._certifications.map((cert) => _buildCard(title: cert.name, subtitle: '${cert.skill} - ${cert.level}', onDelete: () => setState(() => _certifications.remove(cert)))),
        const SizedBox(height: 16),
        _buildTextField(_certNameController, 'Certification Name', Icons.verified_outlined),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedSkillForCert,
          hint: Text('Link to skill', style: GoogleFonts.poppins()),
          decoration: _getInputDecoration('', Icons.link),
          items: _skills.map((skill) => DropdownMenuItem(value: skill, child: Text(skill))).toList(),
          onChanged: (val) => setState(() => _selectedSkillForCert = val),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedCertLevel,
          decoration: _getInputDecoration('Level', Icons.layers_outlined),
          items: _certLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
          onChanged: (val) => setState(() => _selectedCertLevel = val ?? 'Basic'),
        ),
        const SizedBox(height: 24),
        _buildActionButton('Add Certification', Icons.add, _addCertification),
      ],
    );
  }

  Widget _buildTextField(TextEditingController? controller, String label, IconData icon, {int maxLines = 1, String? initialValue, Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _getInputDecoration(label, icon),
    );
  }

  InputDecoration _getInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF5B3FD8), size: 20),
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5B3FD8), width: 1.5)),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF5B3FD8), side: const BorderSide(color: Color(0xFF5B3FD8)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildSmallAddButton(VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF5B3FD8), borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: onPressed),
    );
  }

  Widget _buildCard({required String title, required String subtitle, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: onDelete),
      ),
    );
  }
}
