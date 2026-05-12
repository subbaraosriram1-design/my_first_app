import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'firebase_service.dart';
import 'resume_builder_page.dart';
import 'placeholder_screens.dart';

class CareerProfileScreen extends StatefulWidget {
  const CareerProfileScreen({super.key});

  @override
  State<CareerProfileScreen> createState() => _CareerProfileScreenState();
}

class _CareerProfileScreenState extends State<CareerProfileScreen> {
  String _displayName = 'Name';
  String _tagline = 'Add a tagline';
  String _summary = '';
  List<dynamic> _educationList = [];
  String? _profileImageBase64;
  List<String> _radarLabels = [];
  Map<String, double> _labelProgress = {};
  Map<String, List<String>> _labelDetails = {}; // Stores certification names or hobby text
  List<dynamic> _experiences = [];
  List<dynamic> _testScores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      final data = await FirebaseService.instance.getResume(user.uid);
      if (data != null) {
        // Extract skills and hobbies
        List<String> skills = [];
        if (data['skills'] is List) {
          skills = (data['skills'] as List).map((e) => e.toString()).toList();
        }
        
        List<String> hobbies = [];
        if (data['hobbies'] is List) {
          hobbies = (data['hobbies'] as List).map((e) => e.toString()).toList();
        }

        // Certifications
        List<dynamic> certsRaw = data['certifications'] ?? [];
        Map<String, List<String>> certsBySkill = {};
        for (var c in certsRaw) {
          String s = c['skill'] ?? '';
          String n = c['name'] ?? '';
          if (s.isNotEmpty) {
            certsBySkill.putIfAbsent(s, () => []).add(n);
          }
        }

        // Take top 4 of each
        List<String> topSkills = skills.take(4).toList();
        List<String> topHobbies = hobbies.take(4).toList();
        
        // Combine them for the radar chart (8 labels total)
        List<String> labels = [...topSkills, ...topHobbies];
        
        // Fill the rest with defaults if less than 8
        const defaults = ['Skill 1', 'Skill 2', 'Skill 3', 'Skill 4', 'Hobby 1', 'Hobby 2', 'Hobby 3', 'Hobby 4'];
        for (int i = labels.length; i < 8; i++) {
          labels.add(defaults[i]);
        }

        // Calculate progress
        Map<String, double> progress = {};
        Map<String, List<String>> details = {};
        for (var label in labels) {
          if (topSkills.contains(label)) {
            // For skills, progress is based on certifications (max 5 for 100%)
            int count = certsBySkill[label]?.length ?? 0;
            progress[label] = (count / 5).clamp(0.0, 1.0);
            details[label] = certsBySkill[label] ?? [];
          } else if (topHobbies.contains(label)) {
            // Hobbies don't have progress line, so 0.0 or just a fixed value if needed
            // The prompt says "if hobbies just take info", so we keep progress 0 or low
            progress[label] = 0.0;
            details[label] = ['Passionate about $label'];
          } else {
            progress[label] = 0.0;
            details[label] = [];
          }
        }

        setState(() {
          _displayName = data['fullName'] ?? 'Name';
          _tagline = (data['tagline'] != null && data['tagline'].toString().isNotEmpty) 
              ? data['tagline'] 
              : 'Add a tagline';
          _summary = data['summary'] ?? '';
          _educationList = data['educationList'] ?? [];
          _experiences = data['experience'] ?? [];
          _testScores = data['testScores'] ?? [];
          _profileImageBase64 = data['profileImage'];
          _radarLabels = labels;
          _labelProgress = progress;
          _labelDetails = details;
        });
      } else {
        setState(() {
          _radarLabels = ['Skill 1', 'Skill 2', 'Skill 3', 'Skill 4', 'Hobby 1', 'Hobby 2', 'Hobby 3', 'Hobby 4'];
          _labelProgress = {};
          _labelDetails = {};
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToResumeBuilder() async {
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResumeBuilderPage(username: user.uid),
        ),
      );
      // Reload data when coming back
      _loadProfileData();
    }
  }

  // --- Inline Editing Methods ---

  Future<void> _updateFirestoreField(String field, dynamic value) async {
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      await FirebaseService.instance.saveResume(user.uid, {field: value});
      _loadProfileData(); // Refresh UI
    }
  }

  void _showSummaryEditDialog() {
    final controller = TextEditingController(text: _summary);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextFormField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Enter your summary...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _updateFirestoreField('summary', controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEducationEditDialog() {
    final schoolController = TextEditingController();
    final degreeController = TextEditingController();
    final startYearController = TextEditingController();
    final endYearController = TextEditingController();
    final additionalController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Education', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: schoolController, decoration: const InputDecoration(labelText: 'School / Institution')),
              TextFormField(controller: degreeController, decoration: const InputDecoration(labelText: 'Degree / Class')),
              TextFormField(controller: startYearController, decoration: const InputDecoration(labelText: 'Start Year')),
              TextFormField(controller: endYearController, decoration: const InputDecoration(labelText: 'End Year')),
              TextFormField(controller: additionalController, decoration: const InputDecoration(labelText: 'Additional Info')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newEdu = List.from(_educationList)..add({
                'school': schoolController.text,
                'degree': degreeController.text,
                'startYear': startYearController.text,
                'endYear': endYearController.text,
                'additionalInfo': additionalController.text,
              });
              _updateFirestoreField('educationList', newEdu);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTestScoreEditDialog() {
    final testNameController = TextEditingController();
    final scoreController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Test Score', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: testNameController, decoration: const InputDecoration(labelText: 'Test Name')),
            TextFormField(controller: scoreController, decoration: const InputDecoration(labelText: 'Score')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newScores = List.from(_testScores)..add({
                'testName': testNameController.text,
                'score': scoreController.text,
              });
              _updateFirestoreField('testScores', newScores);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExperienceEditDialog() {
    final jobController = TextEditingController();
    final companyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Experience', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: jobController, decoration: const InputDecoration(labelText: 'Job Title')),
            TextFormField(controller: companyController, decoration: const InputDecoration(labelText: 'Company')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newExperiences = List.from(_experiences)..add({
                'jobTitle': jobController.text,
                'company': companyController.text,
              });
              _updateFirestoreField('experience', newExperiences);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final int sizeInBytes = await file.length();
        const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB

        if (sizeInBytes > maxSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Video size must be less than 5MB', style: GoogleFonts.poppins()),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } else {
          // Success! (In a real app, we would upload this to Firebase Storage)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Video selected successfully!', style: GoogleFonts.poppins()),
                backgroundColor: const Color(0xFF5B3FD8),
              ),
            );
          }
          debugPrint('Picked video: ${file.path}, size: $sizeInBytes bytes');
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
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
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPage())),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu, color: Colors.black87, size: 20),
            ),
          ),
        ),
        actions: [
          _buildAppBarIcon(Icons.work_outline, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkPage()))),
          _buildAppBarIcon(Icons.notifications_none, hasBadge: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()))),
          _buildAppBarIcon(Icons.more_vert, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MoreOptionsPage()))),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildProfileHeader(),
            ),
            const SizedBox(height: 48),
            _buildRadarChartSection(),
            const SizedBox(height: 32),
            _buildVideoCard(),
            const SizedBox(height: 24),
            _buildExpandableSections(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1522202176988-66273c2fd55f?q=80&w=1471&auto=format&fit=crop'),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
          color: const Color(0x0D000000), // Black with 5% opacity
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Add your introduction video',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pickVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3FD8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 0,
              ),
              child: Text(
                'Add video',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _ProfileSection(
            title: 'Summary',
            icon: Icons.edit_note,
            content: _summary.isNotEmpty ? Text(_summary, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)) : null,
            onEdit: _showSummaryEditDialog,
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Education',
            icon: Icons.school_outlined,
            content: _educationList.isNotEmpty 
              ? Column(children: _educationList.map((edu) => _buildEducationCard(edu)).toList())
              : null,
            onEdit: _showEducationEditDialog,
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Test scores',
            icon: Icons.assignment_outlined,
            content: _testScores.isNotEmpty 
              ? _buildTestScoresList()
              : null,
            onEdit: _showTestScoreEditDialog,
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Experiences',
            icon: Icons.workspace_premium_outlined,
            content: _experiences.isNotEmpty 
              ? _buildExperiencesList()
              : null,
            onEdit: _showExperienceEditDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu['school'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${edu['startYear']} - ${edu['endYear']} | ${edu['additionalInfo']}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestScoresList() {
    return Column(
      children: _testScores.map((score) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(score['testName'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            Text(score['score'] ?? '', style: GoogleFonts.poppins(color: const Color(0xFF5B3FD8), fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildExperiencesList() {
    return Column(
      children: _experiences.map((exp) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exp['jobTitle'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            Text(exp['company'] ?? '', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAppBarIcon(IconData icon, {bool hasBadge = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.black87, size: 20),
            ),
            if (hasBadge)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF5B3FD8).withAlpha(30),
                borderRadius: BorderRadius.circular(24),
              ),
              child: CustomPaint(
                painter: ProfileImagePainter(),
                child: Center(
                  child: _profileImageBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.memory(
                            base64Decode(_profileImageBase64!),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person_outline, size: 50, color: Color(0xFF5B3FD8)),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: _navigateToResumeBuilder,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B3FD8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _navigateToResumeBuilder,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B3FD8).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _tagline,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5B3FD8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit, size: 12, color: Color(0xFF5B3FD8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadarChartSection() {
    final bool hasData = _radarLabels.any((l) => !l.startsWith('Skill ') && !l.startsWith('Hobby '));

    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTapUp: (details) {
                  _handleRadarTap(details.localPosition);
                },
                child: SizedBox(
                  width: 340,
                  height: 340,
                  child: CustomPaint(
                    painter: RadarChartPainter(
                      labels: _radarLabels,
                      progress: _labelProgress,
                    ),
                  ),
                ),
              ),
              if (!hasData)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Visualize your story',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 180,
                      child: Text(
                        'Add experiences to visualize your profile here',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleRadarTap(Offset localPosition) {
    const double centerX = 170.0; // 340 / 2
    const double centerY = 170.0;
    const double radius = 170.0 - 60.0;
    const double labelRadius = radius + 25;

    final double angleStep = (2 * math.pi) / _radarLabels.length;

    for (int i = 0; i < _radarLabels.length; i++) {
      final double angle = i * angleStep - math.pi / 2;
      final double lx = centerX + labelRadius * math.cos(angle);
      final double ly = centerY + labelRadius * math.sin(angle);

      // Check if tap is near label
      final double distance = math.sqrt(math.pow(lx - localPosition.dx, 2) + math.pow(ly - localPosition.dy, 2));
      if (distance < 30) {
        _showLabelDetails(_radarLabels[i]);
        break;
      }
    }
  }

  void _showLabelDetails(String label) {
    final details = _labelDetails[label] ?? [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details.isEmpty
              ? [const Text('No details added yet.')]
              : details.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Color(0xFF5B3FD8)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d, style: GoogleFonts.poppins())),
                    ],
                  ),
                )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class ProfileImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRRect(rrect, paint);

    // Draw orange segment on top
    final orangePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.addArc(
      Rect.fromLTWH(-1, -1, size.width + 2, size.height + 2),
      -math.pi / 2 - 0.5,
      1.0,
    );
    
    // This is a bit simplified, ideally we'd clip to the rrect
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(path, orangePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RadarChartPainter extends CustomPainter {
  final List<String> labels;
  final Map<String, double> progress;
  RadarChartPainter({required this.labels, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 60; // Leave space for labels
    
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles
    const int circlesCount = 8;
    for (var i = 1; i <= circlesCount; i++) {
      canvas.drawCircle(center, radius * (i / circlesCount), gridPaint);
    }

    final angleStep = (2 * math.pi) / labels.length;

    // Draw axis lines and labels
    for (var i = 0; i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endPoint, gridPaint);

      // Draw labels
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      double labelRadius = radius + 25;
      double x = center.dx + labelRadius * math.cos(angle) - textPainter.width / 2;
      double y = center.dy + labelRadius * math.sin(angle) - textPainter.height / 2;

      if (math.cos(angle).abs() < 0.1) {
      } else if (math.cos(angle) > 0) {
        x += textPainter.width / 4;
      } else {
        x -= textPainter.width / 4;
      }

      textPainter.paint(canvas, Offset(x, y));
    }

    // Draw Blue Progress Line
    final bluePaint = Paint()
      ..color = const Color(0xFF5B3FD8).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final blueStroke = Paint()
      ..color = const Color(0xFF5B3FD8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    bool first = true;

    for (int i = 0; i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final val = progress[labels[i]] ?? 0.0;
      // Minimum visual progress if the skill exists but has 0 certs
      final double displayVal = val == 0 && !labels[i].startsWith('Skill ') && !labels[i].startsWith('Hobby ') ? 0.05 : val;
      
      final x = center.dx + (radius * displayVal) * math.cos(angle);
      final y = center.dy + (radius * displayVal) * math.sin(angle);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Only draw if there is some progress
    if (progress.values.any((v) => v > 0)) {
      canvas.drawPath(path, bluePaint);
      canvas.drawPath(path, blueStroke);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _ProfileSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget? content;
  final VoidCallback onEdit;

  const _ProfileSection({
    required this.title,
    required this.icon,
    this.content,
    required this.onEdit,
  });

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: const Color(0xFF5B3FD8), size: 20),
            ),
            title: Text(
              widget.title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            trailing: GestureDetector(
              onTap: widget.onEdit,
              child: Icon(
                widget.content == null ? Icons.add : Icons.edit_outlined,
                color: const Color(0xFF5B3FD8),
                size: 20,
              ),
            ),
          ),
          if (_isExpanded && widget.content != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: widget.content!,
            ),
        ],
      ),
    );
  }
}
