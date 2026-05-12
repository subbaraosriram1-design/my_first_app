import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';

class Experience {
  String jobTitle;
  String company;
  DateTime? startDate;
  DateTime? endDate;

  Experience({
    this.jobTitle = '',
    this.company = '',
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'jobTitle': jobTitle,
        'company': company,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
        jobTitle: json['jobTitle'] ?? '',
        company: json['company'] ?? '',
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      );
}

class Certification {
  String name;
  String skill;

  Certification({
    this.name = '',
    this.skill = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'skill': skill,
      };

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        name: json['name'] ?? '',
        skill: json['skill'] ?? '',
      );
}

class Education {
  String school;
  String degree;
  String startYear;
  String endYear;
  String additionalInfo;

  Education({
    this.school = '',
    this.degree = '',
    this.startYear = '',
    this.endYear = '',
    this.additionalInfo = '',
  });

  Map<String, dynamic> toJson() => {
        'school': school,
        'degree': degree,
        'startYear': startYear,
        'endYear': endYear,
        'additionalInfo': additionalInfo,
      };

  factory Education.fromJson(Map<String, dynamic> json) => Education(
        school: json['school'] ?? '',
        degree: json['degree'] ?? '',
        startYear: json['startYear'] ?? '',
        endYear: json['endYear'] ?? '',
        additionalInfo: json['additionalInfo'] ?? '',
      );
}

class TestScore {
  String testName;
  String score;
  String date;

  TestScore({this.testName = '', this.score = '', this.date = ''});

  Map<String, dynamic> toJson() => {
        'testName': testName,
        'score': score,
        'date': date,
      };

  factory TestScore.fromJson(Map<String, dynamic> json) => TestScore(
        testName: json['testName'] ?? '',
        score: json['score'] ?? '',
        date: json['date'] ?? '',
      );
}

class ResumeBuilderPage extends StatefulWidget {
  final String username;
  const ResumeBuilderPage({super.key, required this.username});

  @override
  State<ResumeBuilderPage> createState() => _ResumeBuilderPageState();
}

class _ResumeBuilderPageState extends State<ResumeBuilderPage> {
  int _currentStep = 0;
  final int _totalSteps = 6;
  final List<String> _pickedFiles = [];
  final List<Experience> _experiences = [];
  final List<Education> _educationList = [];
  final List<String> _skills = [];
  final List<String> _hobbies = [];
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
  final _hobbyController = TextEditingController();
  final _certNameController = TextEditingController();
  final _testNameController = TextEditingController();
  final _testScoreController = TextEditingController();
  String? _selectedSkillForCert;

  @override
  void initState() {
    super.initState();
    _loadResumeData();
  }

  Future<void> _loadResumeData() async {
    final data = await FirebaseService.instance.getResume(widget.username);
    if (data != null) {
      setState(() {
        _nameController.text = data['fullName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _taglineController.text = data['tagline'] ?? '';
        _summaryController.text = data['summary'] ?? '';
        
        if (data['educationList'] != null && data['educationList'] is List) {
          _educationList.addAll((data['educationList'] as List).map((e) => Education.fromJson(e as Map<String, dynamic>)));
        } else if (data['education'] != null && data['education'] is String && data['education'].isNotEmpty) {
          _educationList.add(Education(school: data['education']));
        }
        
        _profileImageBase64 = data['profileImage'];
        
        if (data['experience'] != null && data['experience'] is List) {
           _experiences.addAll((data['experience'] as List).map((e) => Experience.fromJson(e as Map<String, dynamic>)));
        }
        
        if (data['skills'] != null && data['skills'] is List) {
          _skills.addAll((data['skills'] as List).map((e) => e.toString()));
        }

        if (data['hobbies'] != null && data['hobbies'] is List) {
          _hobbies.addAll((data['hobbies'] as List).map((e) => e.toString()));
        }

        if (data['certifications'] != null && data['certifications'] is List) {
          _certifications.addAll((data['certifications'] as List).map((e) => Certification.fromJson(e as Map<String, dynamic>)));
        }

        if (data['testScores'] != null && data['testScores'] is List) {
          _testScores.addAll((data['testScores'] as List).map((e) => TestScore.fromJson(e as Map<String, dynamic>)));
        }

        if (data['fileNames'] != null && data['fileNames'] is List) {
          _pickedFiles.addAll((data['fileNames'] as List).map((e) => e.toString()));
        }
      });
    }
    
    if (_experiences.isEmpty) {
      _experiences.add(Experience());
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveResumeData() async {
    final data = {
      'fullName': _nameController.text,
      'email': _emailController.text,
      'tagline': _taglineController.text,
      'summary': _summaryController.text,
      'educationList': _educationList.map((e) => e.toJson()).toList(),
      'profileImage': _profileImageBase64,
      'experience': _experiences.map((e) => e.toJson()).toList(),
      'skills': _skills,
      'hobbies': _hobbies,
      'certifications': _certifications.map((c) => c.toJson()).toList(),
      'testScores': _testScores.map((t) => t.toJson()).toList(),
      'fileNames': _pickedFiles,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await FirebaseService.instance.saveResume(widget.username, data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume synced to cloud!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _pickedFiles.addAll(result.files.map((file) => file.name));
      });
    }
  }

  Future<void> _pickProfileImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      if (kIsWeb) {
        if (result.files.single.bytes != null) {
          setState(() {
            _profileImageBase64 = base64Encode(result.files.single.bytes!);
          });
        }
      } else {
         if (result.files.single.path != null) {
           final bytes = await io.File(result.files.single.path!).readAsBytes();
           setState(() {
             _profileImageBase64 = base64Encode(bytes);
           });
         }
      }
    }
  }

  void _addExperience() {
    setState(() {
      _experiences.add(Experience());
    });
  }

  void _removeExperience(int index) {
    setState(() {
      _experiences.removeAt(index);
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

  void _addHobby() {
    final hobby = _hobbyController.text.trim();
    if (hobby.isNotEmpty && !_hobbies.contains(hobby)) {
      setState(() {
        _hobbies.add(hobby);
        _hobbyController.clear();
      });
    }
  }

  void _addCertification() {
    final name = _certNameController.text.trim();
    if (name.isNotEmpty && _selectedSkillForCert != null) {
      setState(() {
        _certifications.add(Certification(name: name, skill: _selectedSkillForCert!));
        _certNameController.clear();
        _selectedSkillForCert = null;
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
          degree: _degreeController.text.trim(),
          startYear: _startYearController.text.trim(),
          endYear: _endYearController.text.trim(),
          additionalInfo: _additionalInfoController.text.trim(),
        ));
        _schoolController.clear();
        _degreeController.clear();
        _startYearController.clear();
        _endYearController.clear();
        _additionalInfoController.clear();
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _experiences[index].startDate = picked;
        } else {
          _experiences[index].endDate = picked;
        }
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
        title: Text(
          'Cloud Resume Builder',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _previousStep,
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          const SizedBox(height: 16),
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    double progress = (_currentStep + 1) / _totalSteps;
    return Container(
      width: double.infinity,
      height: 6,
      color: Colors.grey.shade100,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(3),
              bottomRight: Radius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    String stepLabel = 'Step ${_currentStep + 1}/$_totalSteps';
    if (_currentStep == 0) stepLabel = 'Starting Page';
    if (_currentStep == _totalSteps - 1) stepLabel = 'Last Page';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            stepLabel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            _getStepTitle(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5B3FD8),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Personal Info';
      case 1: return 'Education';
      case 2: return 'Experience';
      case 3: return 'Skills & Hobbies';
      case 4: return 'Test Scores';
      case 5: return 'Finish Up';
      default: return '';
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B3FD8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            _currentStep == _totalSteps - 1 ? 'Sync to Cloud' : 'Continue',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0: return _buildPersonalInfoStep();
      case 1: return _buildEducationStep();
      case 2: return _buildExperienceStep();
      case 3: return _buildSkillsHobbiesStep();
      case 4: return _buildTestScoresStep();
      case 5: return _buildCertificationsStep();
      default: return Container();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickProfileImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFF8F7FF),
            backgroundImage: _profileImageBase64 != null
                ? MemoryImage(base64Decode(_profileImageBase64!))
                : null,
            child: _profileImageBase64 == null
                ? const Icon(Icons.add_a_photo_outlined, size: 30, color: Color(0xFF5B3FD8))
                : null,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(_nameController, 'Full Name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(_emailController, 'Contact Email', Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(_taglineController, 'Tagline', Icons.label_outline),
        const SizedBox(height: 16),
        _buildTextField(_summaryController, 'Professional Summary', Icons.description_outlined, maxLines: 4),
      ],
    );
  }

  Widget _buildEducationStep() {
    return Column(
      children: [
        _buildTextField(_schoolController, 'School / Institution', Icons.school_outlined),
        const SizedBox(height: 16),
        _buildTextField(_degreeController, 'Degree / Class', Icons.workspace_premium_outlined),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_startYearController, 'Start Year', Icons.calendar_today_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_endYearController, 'End Year', Icons.calendar_today_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(_additionalInfoController, 'Additional Info (e.g. 9th - 12th)', Icons.info_outline),
        const SizedBox(height: 16),
        _buildActionButton('Add Education', Icons.add, _addEducation),
        const SizedBox(height: 24),
        ..._educationList.map((edu) => _buildCard(
          title: edu.school,
          subtitle: '${edu.degree} | ${edu.startYear} - ${edu.endYear}',
          onDelete: () => setState(() => _educationList.remove(edu)),
        )),
      ],
    );
  }

  Widget _buildExperienceStep() {
    return Column(
      children: [
        ..._experiences.asMap().entries.map((entry) {
          int idx = entry.key;
          Experience exp = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Experience ${idx + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    if (_experiences.length > 1)
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeExperience(idx)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(null, 'Job Title', Icons.work_outline, initialValue: exp.jobTitle, onChanged: (v) => exp.jobTitle = v),
                const SizedBox(height: 12),
                _buildTextField(null, 'Company', Icons.business_outlined, initialValue: exp.company, onChanged: (v) => exp.company = v),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(exp.startDate == null ? 'Start' : DateFormat('MMM yyy').format(exp.startDate!)),
                        onPressed: () => _selectDate(context, true, idx),
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(exp.endDate == null ? 'End' : DateFormat('MMM yyy').format(exp.endDate!)),
                        onPressed: () => _selectDate(context, false, idx),
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        _buildActionButton('Add Experience', Icons.work_outline, _addExperience),
      ],
    );
  }

  Widget _buildSkillsHobbiesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skills', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTextField(_skillController, 'Skill name', Icons.bolt_outlined)),
            const SizedBox(width: 8),
            _buildSmallAddButton(_addSkill),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _skills.map((skill) => Chip(
            label: Text(skill),
            onDeleted: () => setState(() => _skills.remove(skill)),
            backgroundColor: const Color(0xFF5B3FD8).withOpacity(0.1),
            side: BorderSide.none,
          )).toList(),
        ),
        const SizedBox(height: 32),
        Text('Hobbies', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTextField(_hobbyController, 'Hobby name', Icons.favorite_outline)),
            const SizedBox(width: 8),
            _buildSmallAddButton(_addHobby),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _hobbies.map((hobby) => Chip(
            label: Text(hobby),
            onDeleted: () => setState(() => _hobbies.remove(hobby)),
            backgroundColor: Colors.orange.withOpacity(0.1),
            side: BorderSide.none,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTestScoresStep() {
    return Column(
      children: [
        _buildTextField(_testNameController, 'Test Name (e.g. GED)', Icons.assignment_outlined),
        const SizedBox(height: 16),
        _buildTextField(_testScoreController, 'Score', Icons.grade_outlined),
        const SizedBox(height: 16),
        _buildActionButton('Add Test Score', Icons.add, _addTestScore),
        const SizedBox(height: 24),
        ..._testScores.map((test) => _buildCard(
          title: test.testName,
          subtitle: 'Score: ${test.score}',
          onDelete: () => setState(() => _testScores.remove(test)),
        )),
      ],
    );
  }

  Widget _buildCertificationsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_certNameController, 'Cert Name', Icons.workspace_premium_outlined),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedSkillForCert,
          hint: Text('Link to skill', style: GoogleFonts.poppins()),
          decoration: _getInputDecoration('', Icons.link_outlined),
          items: _skills.map((skill) => DropdownMenuItem(value: skill, child: Text(skill))).toList(),
          onChanged: (val) => setState(() => _selectedSkillForCert = val),
        ),
        const SizedBox(height: 16),
        _buildActionButton('Add Certification', Icons.add, _addCertification),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          children: _certifications.map((cert) => Chip(
            label: Text('${cert.name} (${cert.skill})'),
            onDeleted: () => setState(() => _certifications.remove(cert)),
          )).toList(),
        ),
        const Divider(height: 48),
        Text('Documents', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildActionButton('Upload Files', Icons.upload_file_outlined, _pickFiles),
        const SizedBox(height: 12),
        ..._pickedFiles.map((name) => ListTile(
          leading: const Icon(Icons.file_present_outlined),
          title: Text(name, style: GoogleFonts.poppins(fontSize: 14)),
          trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _pickedFiles.remove(name))),
        )),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildTextField(TextEditingController? controller, String label, IconData icon, {int maxLines = 1, String? initialValue, Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _getInputDecoration(label, icon),
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF5B3FD8), size: 20),
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5B3FD8),
          side: const BorderSide(color: Color(0xFF5B3FD8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
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
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: onDelete),
      ),
    );
  }
}
