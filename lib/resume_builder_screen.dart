import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'firebase_service.dart';
import 'models.dart';
import 'ai_service.dart';
import 'resume_template_selection_screen.dart';

class ResumeBuilderPage extends StatefulWidget {
  const ResumeBuilderPage({super.key});

  @override
  State<ResumeBuilderPage> createState() => _ResumeBuilderPageState();
}

class _ResumeBuilderPageState extends State<ResumeBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isOptimizingSummary = false;
  bool _isOptimizingObjective = false;
  final AiService _aiService = GroqAiService();

  // Controllers for Personal Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _summaryController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();
  String? _profileImageBase64;

  // Lists for dynamic sections
  List<Education> _educationList = [];
  List<WorkExperience> _experienceList = [];
  List<Project> _projectList = [];
  List<Certification> _certificationList = [];
  List<String> _skills = [];
  List<String> _achievements = [];
  List<Language> _languages = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (data != null) {
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _objectiveController.text = data['objective'] ?? '';
          _summaryController.text = data['summary'] ?? '';
          _linkedinController.text = data['linkedin'] ?? '';
          _githubController.text = data['github'] ?? '';
          _portfolioController.text = data['portfolio'] ?? '';
          _profileImageBase64 = data['profileImage'];

          if (data['educationList'] is List) {
            _educationList = (data['educationList'] as List)
                .map((e) => Education.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }

          if (data['experienceList'] is List) {
            _experienceList = (data['experienceList'] as List)
                .map((e) => WorkExperience.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }

          if (data['projects'] is List) {
            _projectList = (data['projects'] as List)
                .map((e) => Project.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }

          if (data['certifications'] is List) {
            _certificationList = (data['certifications'] as List)
                .map((e) => Certification.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }

          if (data['skills'] is List) {
            _skills = (data['skills'] as List).map((e) => e.toString()).toList();
          }

          if (data['achievements'] is List) {
            _achievements = (data['achievements'] as List).map((e) => e.toString()).toList();
          }

          if (data['languages'] is List) {
            _languages = (data['languages'] as List)
                .map((e) => Language.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _optimizeField(TextEditingController controller, String fieldName, bool isSummary) async {
    if (controller.text.isEmpty) return;
    setState(() => isSummary ? _isOptimizingSummary = true : _isOptimizingObjective = true);
    try {
      final prompt = "Optimize this $fieldName for a resume to make it more impactful and professional: ${controller.text}. Return only the optimized text.";
      final optimized = await _aiService.getPersonalGuidance("Resume Optimization", prompt, {});
      setState(() {
        controller.text = optimized.trim();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI optimization failed: $e")));
      }
    } finally {
      setState(() => isSummary ? _isOptimizingSummary = false : _isOptimizingObjective = false);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint("Image Picker Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open image picker")),
        );
      }
    }
  }

  void _saveAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      setState(() => _isLoading = true);
      try {
        final updatedData = {
          'fullName': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'dob': _dobController.text,
          'objective': _objectiveController.text,
          'summary': _summaryController.text,
          'linkedin': _linkedinController.text,
          'github': _githubController.text,
          'portfolio': _portfolioController.text,
          'profileImage': _profileImageBase64,
          'educationList': _educationList.map((e) => e.toJson()).toList(),
          'experienceList': _experienceList.map((e) => e.toJson()).toList(),
          'projects': _projectList.map((e) => e.toJson()).toList(),
          'certifications': _certificationList.map((e) => e.toJson()).toList(),
          'skills': _skills,
          'achievements': _achievements,
          'languages': _languages.map((e) => e.toJson()).toList(),
        };

        await FirebaseService.instance.saveResume(userId, updatedData);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResumeTemplateSelectionPage(resumeData: updatedData),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().contains('quota') 
                ? 'Firebase Quota Exceeded. Please try again tomorrow or reduce image size.' 
                : 'Error saving: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8))));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Build Resume', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Personal Information'),
              _buildProfilePicker(),
              const SizedBox(height: 20),
              _buildTextField(_nameController, 'Full Name', Icons.person_outline),
              _buildTextField(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
              _buildTextField(_addressController, 'Address', Icons.location_on_outlined),
              _buildTextField(_dobController, 'Date of Birth', Icons.calendar_today_outlined),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Career Objective'),
              _buildTextField(
                _objectiveController, 
                'Short career objective...', 
                Icons.flag_outlined, 
                maxLines: 2,
                suffixIcon: IconButton(
                  icon: _isOptimizingObjective 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, color: Color(0xFF5B3FD8)),
                  onPressed: () => _optimizeField(_objectiveController, "career objective", false),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Professional Summary'),
              _buildTextField(
                _summaryController, 
                'Write a short professional summary...', 
                Icons.description_outlined, 
                maxLines: 4,
                suffixIcon: IconButton(
                  icon: _isOptimizingSummary 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, color: Color(0xFF5B3FD8)),
                  onPressed: () => _optimizeField(_summaryController, "professional summary", true),
                ),
              ),

              const SizedBox(height: 24),
              _buildDynamicSection<Education>(
                'Education',
                _educationList,
                (edu) => _buildEducationTile(edu),
                () => _addEducation(),
              ),

              const SizedBox(height: 24),
              _buildDynamicSection<WorkExperience>(
                'Work Experience / Internships',
                _experienceList,
                (exp) => _buildExperienceTile(exp),
                () => _addExperience(),
              ),

              const SizedBox(height: 24),
              _buildDynamicSection<Project>(
                'Projects',
                _projectList,
                (proj) => _buildProjectTile(proj),
                () => _addProject(),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Skills'),
              _buildSkillsChips(),

              const SizedBox(height: 24),
              _buildDynamicSection<Certification>(
                'Certifications',
                _certificationList,
                (cert) => _buildCertificationTile(cert),
                () => _addCertification(),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Social Links'),
              _buildTextField(_linkedinController, 'LinkedIn Profile URL', Icons.link),
              _buildTextField(_githubController, 'GitHub Profile URL', Icons.link),
              _buildTextField(_portfolioController, 'Portfolio Website URL', Icons.language),

              const SizedBox(height: 24),
              _buildSectionTitle('Additional Details'),
              _buildLanguagesSection(),
              const SizedBox(height: 12),
              _buildAchievementsSection(),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3FD8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Confirm Details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: _profileImageBase64 != null 
                ? MemoryImage(base64Decode(_profileImageBase64!)) 
                : null,
              child: _profileImageBase64 == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF5B3FD8), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        ),
      ),
    );
  }

  Widget _buildDynamicSection<T>(String title, List<T> items, Widget Function(T) buildTile, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(title),
            IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle_outline, color: Color(0xFF5B3FD8))),
          ],
        ),
        ...items.map((item) => buildTile(item)),
      ],
    );
  }

  Widget _buildEducationTile(Education edu) {
    return _buildCardTile(
      title: edu.school,
      subtitle: '${edu.level} | ${edu.yearFrom} - ${edu.yearTo}',
      onDelete: () => setState(() => _educationList.remove(edu)),
    );
  }

  Widget _buildExperienceTile(WorkExperience exp) {
    return _buildCardTile(
      title: exp.title,
      subtitle: '${exp.organization} | ${exp.startDate} - ${exp.endDate}',
      onDelete: () => setState(() => _experienceList.remove(exp)),
    );
  }

  Widget _buildProjectTile(Project proj) {
    return _buildCardTile(
      title: proj.title,
      subtitle: proj.description,
      onDelete: () => setState(() => _projectList.remove(proj)),
    );
  }

  Widget _buildCertificationTile(Certification cert) {
    return _buildCardTile(
      title: cert.name,
      subtitle: cert.skill,
      onDelete: () => setState(() => _certificationList.remove(cert)),
    );
  }

  Widget _buildCardTile({required String title, required String subtitle, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
        ],
      ),
    );
  }

  Widget _buildSkillsChips() {
    final TextEditingController skillCtrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField(skillCtrl, 'Add a skill...', Icons.bolt)),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (skillCtrl.text.isNotEmpty) {
                  setState(() {
                    _skills.add(skillCtrl.text.trim());
                    skillCtrl.clear();
                  });
                }
              }, 
              icon: const Icon(Icons.add_circle, color: Color(0xFF5B3FD8)),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: _skills.map((s) => Chip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            onDeleted: () => setState(() => _skills.remove(s)),
            deleteIconColor: Colors.redAccent,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(color: Colors.grey.shade200),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Languages', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            IconButton(
                onPressed: () {
                setState(() => _languages.add(Language(name: 'New Language', proficiency: 'Fluent')));
              }, 
              icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF5B3FD8)),
            ),
          ],
        ),
        ..._languages.map((l) => Row(
          children: [
            Expanded(child: TextFormField(initialValue: l.name, onChanged: (v) => l.name = v, style: const TextStyle(fontSize: 13))),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(initialValue: l.proficiency, onChanged: (v) => l.proficiency = v, style: const TextStyle(fontSize: 13))),
            IconButton(onPressed: () => setState(() => _languages.remove(l)), icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.red)),
          ],
        )),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final TextEditingController achCtrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField(achCtrl, 'Add Achievement...', Icons.emoji_events_outlined)),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (achCtrl.text.isNotEmpty) {
                  setState(() => _achievements.add(achCtrl.text.trim()));
                  achCtrl.clear();
                }
              }, 
              icon: const Icon(Icons.add_circle, color: Color(0xFF5B3FD8)),
            ),
          ],
        ),
        ..._achievements.map((a) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [const Icon(Icons.check, size: 14, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(a))]),
        )),
      ],
    );
  }

  void _addEducation() {
    final schoolCtrl = TextEditingController();
    final degreeCtrl = TextEditingController();
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Education'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: schoolCtrl, decoration: const InputDecoration(labelText: 'School/University')),
            TextField(controller: degreeCtrl, decoration: const InputDecoration(labelText: 'Degree/Level')),
            Row(
              children: [
                Expanded(child: TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'From Year'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'To Year'))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _educationList.add(Education(school: schoolCtrl.text, level: degreeCtrl.text, yearFrom: fromCtrl.text, yearTo: toCtrl.text)));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addExperience() {
    final titleCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    String type = 'Internship';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
              TextField(controller: orgCtrl, decoration: const InputDecoration(labelText: 'Organization')),
              Row(
                children: [
                  Expanded(child: TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'Start Date'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'End Date'))),
                ],
              ),
              DropdownButton<String>(
                value: type,
                isExpanded: true,
                items: ['Job', 'Internship', 'Volunteer'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() => _experienceList.add(WorkExperience(title: titleCtrl.text, organization: orgCtrl.text, startDate: fromCtrl.text, endDate: toCtrl.text, type: type)));
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _addProject() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Project Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _projectList.add(Project(title: titleCtrl.text, description: descCtrl.text)));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCertification() {
    final nameCtrl = TextEditingController();
    final skillCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Certification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Certification Name')),
            TextField(controller: skillCtrl, decoration: const InputDecoration(labelText: 'Related Skill')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _certificationList.add(Certification(name: nameCtrl.text, skill: skillCtrl.text)));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
