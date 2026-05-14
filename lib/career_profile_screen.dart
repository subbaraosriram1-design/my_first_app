import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'firebase_service.dart';
import 'placeholder_screens.dart';
import 'login_page.dart';

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
  Map<String, List<String>> _labelDetails = {};
  List<dynamic> _projects = [];
  List<dynamic> _testScores = [];
  List<String> _careerInterests = [];
  Map<String, double> _interestPoints = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (data != null) {
        List<String> skills = [];
        if (data['skills'] is List) {
          skills = (data['skills'] as List).map((e) => e.toString()).toList();
        }
        List<String> studentInterests = [];
        if (data['hobbies'] is List) {
          studentInterests = (data['hobbies'] as List).map((e) => e.toString()).toList();
        }

        List<dynamic> certsRaw = data['certifications'] ?? [];
        Map<String, List<String>> certsBySkill = {};
        for (var c in certsRaw) {
          String s = c['skill'] ?? '';
          String n = c['name'] ?? '';
          if (s.isNotEmpty) {
            certsBySkill.putIfAbsent(s, () => []).add(n);
          }
        }

        List<String> topSkills = skills.take(4).toList();
        List<String> topHobbies = studentInterests.take(4).toList();
        List<String> labels = [...topSkills, ...topHobbies.map((e) => 'Interest $e')];
        const defaults = ['Skill 1', 'Skill 2', 'Skill 3', 'Skill 4', 'Interest 1', 'Interest 2', 'Interest 3', 'Interest 4'];
        for (int i = labels.length; i < 8; i++) {
          labels.add(defaults[i]);
        }

        Map<String, double> progress = {};
        Map<String, List<String>> details = {};
        for (var label in labels) {
          String cleanLabel = label.startsWith('Interest ') ? label.substring(9) : label;
          if (topSkills.contains(label)) {
            int count = certsBySkill[label]?.length ?? 0;
            progress[label] = (count / 5).clamp(0.0, 1.0);
            details[label] = certsBySkill[label] ?? [];
          } else if (topHobbies.contains(cleanLabel)) {
            progress[label] = 0.5; // Default progress for interests
            details[label] = ['Passionate about $cleanLabel'];
          } else {
            progress[label] = 0.0;
            details[label] = [];
          }
        }

        // Calculate Career Interest Points
        List<String> userInterests = [];
        if (data['careerInterests'] is List) {
          userInterests = (data['careerInterests'] as List).map((e) => e.toString()).toList();
        }

        Map<String, double> pointsMap = {};
        for (var interest in userInterests) {
          double points = 0;
          for (var cert in certsRaw) {
            if (cert['skill'] == interest || cert['skill'] == 'Others') {
              String level = cert['level'] ?? 'Basic';
              if (level == 'Basic') {
            points += 5;
          }
              else if (level == 'Intermediate') {
                points += 10;
              } else if (level == 'Advanced') {
                points += 15;
              }
            }
          }
          List<dynamic> projectsRaw = data['projects'] ?? data['experience'] ?? [];
          for (var proj in projectsRaw) {
            List<String> linkedInterests = [];
            if (proj['linkedInterests'] is List) {
              linkedInterests = List<String>.from(proj['linkedInterests']);
            } else if (proj['skill'] != null) {
              linkedInterests = [proj['skill'].toString()];
            }

            if (linkedInterests.contains(interest) || (proj['description'] != null && proj['description'].toString().contains(interest))) {
              points += 20;
            }
          }
          if (points > 0) pointsMap[interest] = points;
        }

        setState(() {
          _displayName = data['fullName'] ?? 'Name';
          _tagline = (data['tagline'] != null && data['tagline'].toString().isNotEmpty) ? data['tagline'] : 'Add a tagline';
          _summary = data['summary'] ?? '';
          _educationList = data['educationList'] ?? [];
          _projects = data['projects'] ?? data['experience'] ?? [];
          _testScores = data['testScores'] ?? [];
          _careerInterests = userInterests;
          _interestPoints = pointsMap;
          _profileImageBase64 = data['profileImage'];
          _radarLabels = labels;
          _labelProgress = progress;
          _labelDetails = details;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  void _navigateToResumeBuilder() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage(initialStep: 1, isEditMode: true)));
      _loadProfileData();
    }
  }

  Future<void> _updateFirestoreField(String field, dynamic value) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      await FirebaseService.instance.saveResume(userId, {field: value});
      _loadProfileData();
    }
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
              final newScores = List.from(_testScores)..add({'testName': testNameController.text, 'score': scoreController.text});
              _updateFirestoreField('testScores', newScores);
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: false);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final int sizeInBytes = await file.length();
        const int maxSizeInBytes = 5 * 1024 * 1024;
        if (sizeInBytes > maxSizeInBytes) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video size must be less than 5MB', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video selected successfully!', style: GoogleFonts.poppins()), backgroundColor: const Color(0xFF5B3FD8)));
        }
      }
    } catch (e) { debugPrint('Error picking video: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8))));
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
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
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
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: _buildProfileHeader()),
            _buildPieChartSection(),
            const SizedBox(height: 48),
            _buildVideoCard(),
            const SizedBox(height: 24),
            _buildExpandableSections(),
            const SizedBox(height: 48),
            _buildRadarChartSection(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection() {
    if (_interestPoints.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Certification Progress', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text('Points earned through certifications and projects', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(width: 150, height: 150, child: CustomPaint(painter: PieChartPainter(data: _interestPoints, careerInterests: _careerInterests))),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _interestPoints.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: _getInterestColor(entry.key), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.key, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                          Text('${entry.value.toInt()} pts', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getInterestColor(String interest) {
    final List<Color> colors = [const Color(0xFF5B3FD8), const Color(0xFFF97316), const Color(0xFF10B981), const Color(0xFF3B82F6), const Color(0xFFEF4444), const Color(0xFF8B5CF6)];
    int index = _careerInterests.indexOf(interest) % colors.length;
    if (index < 0) index = 0;
    return colors[index];
  }

  Widget _buildVideoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1522202176988-66273c2fd55f?q=80&w=1471&auto=format&fit=crop'), fit: BoxFit.cover, opacity: 0.4),
          color: const Color(0x0D000000),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Add your introduction video', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pickVideo,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B3FD8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), elevation: 0),
              child: Text('Add video', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
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
            onEdit: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => SummaryViewPage(summary: _summary)));
              if (result == true) _loadProfileData();
            }
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Education', 
            icon: Icons.school_outlined, 
            content: _educationList.isNotEmpty ? Column(children: _educationList.map((edu) => _buildEducationCard(edu)).toList()) : null, 
            onEdit: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EducationViewPage()));
              if (result == true) _loadProfileData();
            }
          ),
          const SizedBox(height: 16),
          _ProfileSection(title: 'Test scores', icon: Icons.assignment_outlined, content: _testScores.isNotEmpty ? _buildTestScoresList() : null, onEdit: _showTestScoreEditDialog),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Projects', 
            icon: Icons.rocket_launch_outlined, 
            content: _projects.isNotEmpty ? _buildProjectsList() : null, 
            onEdit: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage(initialStep: 4, isEditMode: true)));
              if (result == true) _loadProfileData();
            }
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(edu['school'] ?? '', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text('${edu['yearFrom'] ?? edu['startYear'] ?? ''} - ${edu['yearTo'] ?? edu['endYear'] ?? ''} | Class of: ${edu['classOf'] ?? edu['degree'] ?? ''}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildTestScoresList() {
    return Column(children: _testScores.map((score) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(score['testName'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)), Text(score['score'] ?? '', style: GoogleFonts.poppins(color: const Color(0xFF5B3FD8), fontWeight: FontWeight.bold))]))).toList());
  }

  Widget _buildProjectsList() {
    return Column(children: _projects.map((proj) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(proj['title'] ?? proj['jobTitle'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), Text(proj['description'] ?? proj['company'] ?? '', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600))]))).toList());
  }

  Widget _buildAppBarIcon(IconData icon, {bool hasBadge = false, VoidCallback? onTap}) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0), child: GestureDetector(onTap: onTap, child: Stack(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.black87, size: 20)), if (hasBadge) Positioned(right: 8, top: 8, child: Container(width: 7, height: 7, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))))])));
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Stack(
          children: [
            Container(width: 90, height: 90, decoration: BoxDecoration(color: const Color(0xFF5B3FD8).withAlpha(30), borderRadius: BorderRadius.circular(24)), child: CustomPaint(painter: ProfileImagePainter(), child: Center(child: _profileImageBase64 != null ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.memory(base64Decode(_profileImageBase64!), width: 90, height: 90, fit: BoxFit.cover)) : const Icon(Icons.person_outline, size: 50, color: Color(0xFF5B3FD8))))),
            Positioned(bottom: 4, right: 4, child: GestureDetector(onTap: _navigateToResumeBuilder, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFF5B3FD8), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.edit, size: 12, color: Colors.white)))),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_displayName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))), const SizedBox(height: 6), GestureDetector(onTap: _navigateToResumeBuilder, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF5B3FD8).withAlpha(15), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: Text(_tagline, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF5B3FD8)))), const SizedBox(width: 6), const Icon(Icons.edit, size: 12, color: Color(0xFF5B3FD8))])))]))
      ],
    );
  }

  Widget _buildRadarChartSection() {
    final bool hasData = _radarLabels.any((l) => !l.startsWith('Skill ') && !l.startsWith('Hobby '));
    return Center(child: Stack(alignment: Alignment.center, children: [GestureDetector(onTapUp: (details) => _handleRadarTap(details.localPosition), child: SizedBox(width: 340, height: 340, child: CustomPaint(painter: RadarChartPainter(labels: _radarLabels, progress: _labelProgress)))), if (!hasData) Column(mainAxisSize: MainAxisSize.min, children: [Text('Visualize your story', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))), const SizedBox(height: 2), SizedBox(width: 180, child: Text('Add projects to visualize your profile here', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500, height: 1.4)))])]));
  }

  void _handleRadarTap(Offset localPosition) {
    const double centerX = 170.0; const double centerY = 170.0; const double radius = 170.0 - 60.0; const double labelRadius = radius + 25;
    final double angleStep = (2 * math.pi) / _radarLabels.length;
    for (int i = 0; i < _radarLabels.length; i++) {
      final double angle = i * angleStep - math.pi / 2;
      final double lx = centerX + labelRadius * math.cos(angle); final double ly = centerY + labelRadius * math.sin(angle);
      if (math.sqrt(math.pow(lx - localPosition.dx, 2) + math.pow(ly - localPosition.dy, 2)) < 30) { _showLabelDetails(_radarLabels[i]); break; }
    }
  }

  void _showLabelDetails(String label) {
    final details = _labelDetails[label] ?? [];
    showDialog(context: context, builder: (context) => AlertDialog(title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: details.isEmpty ? [const Text('No details added yet.')] : details.map((d) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(children: [const Icon(Icons.check_circle, size: 16, color: Color(0xFF5B3FD8)), const SizedBox(width: 8), Expanded(child: Text(d, style: GoogleFonts.poppins()))]))).toList()), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final List<String> careerInterests;
  PieChartPainter({required this.data, required this.careerInterests});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2); final radius = math.min(size.width / 2, size.height / 2); final total = data.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return;
    double startAngle = -math.pi / 2;
    final List<Color> colors = [const Color(0xFF5B3FD8), const Color(0xFFF97316), const Color(0xFF10B981), const Color(0xFF3B82F6), const Color(0xFFEF4444), const Color(0xFF8B5CF6)];
    
    for (var entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      int colorIndex = careerInterests.indexOf(entry.key) % colors.length;
      if (colorIndex < 0) colorIndex = 0;
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, Paint()..color = colors[colorIndex]);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
      startAngle += sweepAngle;
    }
    canvas.drawCircle(center, radius * 0.5, Paint()..color = Colors.white);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class ProfileImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height); final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    canvas.drawRRect(rrect, Paint()..color = Colors.grey.shade200..style = PaintingStyle.stroke..strokeWidth = 2);
    final orangePaint = Paint()..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    final path = Path()..addArc(Rect.fromLTWH(-1, -1, size.width + 2, size.height + 2), -math.pi / 2 - 0.5, 1.0);
    canvas.save(); canvas.clipRRect(rrect); canvas.drawPath(path, orangePaint); canvas.restore();
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RadarChartPainter extends CustomPainter {
  final List<String> labels; final Map<String, double> progress;
  RadarChartPainter({required this.labels, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2); final radius = size.width / 2 - 60;
    final gridPaint = Paint()..color = Colors.grey.shade200..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var i = 1; i <= 8; i++) {
      canvas.drawCircle(center, radius * (i / 8), gridPaint);
    }
    final angleStep = (2 * math.pi) / labels.length;
    for (var i = 0; i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      canvas.drawLine(center, Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)), gridPaint);
      final textPainter = TextPainter(text: TextSpan(text: labels[i], style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade400)), textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
      double labelRadius = radius + 25; double x = center.dx + labelRadius * math.cos(angle) - textPainter.width / 2; double y = center.dy + labelRadius * math.sin(angle) - textPainter.height / 2;
      if (math.cos(angle).abs() > 0.1) x += (math.cos(angle) > 0 ? 1 : -1) * textPainter.width / 4;
      textPainter.paint(canvas, Offset(x, y));
    }
    final path = Path(); bool first = true;
    for (int i = 0; i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2; final val = progress[labels[i]] ?? 0.0;
      final double displayVal = val == 0 && !labels[i].startsWith('Skill ') && !labels[i].startsWith('Interest ') ? 0.05 : val;
      final x = center.dx + (radius * displayVal) * math.cos(angle); final y = center.dy + (radius * displayVal) * math.sin(angle);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    if (progress.values.any((v) => v > 0)) { 
      canvas.drawPath(path, Paint()..color = const Color(0xFF5B3FD8).withAlpha(128)); 
      canvas.drawPath(path, Paint()..color = const Color(0xFF5B3FD8)..style = PaintingStyle.stroke..strokeWidth = 2); 
    }
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class SummaryViewPage extends StatefulWidget {
  final String summary;
  const SummaryViewPage({super.key, required this.summary});

  @override
  State<SummaryViewPage> createState() => _SummaryViewPageState();
}

class _SummaryViewPageState extends State<SummaryViewPage> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.summary);
  }

  Future<void> _save() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      setState(() => _isSaving = true);
      try {
        await FirebaseService.instance.saveResume(userId, {'summary': _controller.text});
        if (mounted) {
          Navigator.pop(context, true);
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Professional Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          _isSaving 
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                onPressed: () {
                  if (_isEditing) {
                    _save();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isEditing 
          ? TextFormField(
              controller: _controller,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: GoogleFonts.poppins(),
            )
          : SingleChildScrollView(
              child: Text(
                _controller.text,
                style: GoogleFonts.poppins(fontSize: 16, height: 1.6, color: Colors.grey.shade800),
              ),
            ),
      ),
    );
  }
}

class EducationViewPage extends StatefulWidget {
  const EducationViewPage({super.key});

  @override
  State<EducationViewPage> createState() => _EducationViewPageState();
}

class _EducationViewPageState extends State<EducationViewPage> {
  List<dynamic> _educationList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (data != null) {
        setState(() {
          _educationList = data['educationList'] ?? [];
          _isLoading = false;
        });
      }
    }
  }

  void _editLevel(String level) async {
    // Navigate to LoginPage with initialStep for Education and EditMode
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const LoginPage(initialStep: 3, isEditMode: true))
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final levels = ['Elementary', 'Middle', 'High', 'College'];
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Education', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 24)),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text('Add schools you have attended', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                final edu = _educationList.firstWhere(
                  (e) => e['level']?.toString().toLowerCase() == level.toLowerCase(),
                  orElse: () => null,
                );

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline line and dot
                      Column(
                        children: [
                          Container(
                            width: 2,
                            height: 20,
                            color: index == 0 ? Colors.transparent : Colors.grey.shade200,
                          ),
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: edu != null ? const Color(0xFF5B3FD8) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              edu != null ? '${edu['yearFrom']}-${edu['yearTo']?.toString().substring(edu['yearTo'].toString().length - 2)}' : 'TBD',
                              style: GoogleFonts.poppins(
                                color: edu != null ? Colors.white : Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text(
                            level,
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
                          ),
                          Expanded(
                            child: Container(
                              width: 2,
                              color: index == levels.length - 1 ? Colors.transparent : Colors.grey.shade200,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Info card
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32.0),
                          child: edu != null 
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(edu['school'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(edu['classOf'] ?? 'Location info', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                          child: Text('Grade: ${edu['gradeFrom'] ?? 'N/A'}', style: GoogleFonts.poppins(fontSize: 10)),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () => _editLevel(level),
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: const Color(0xFF1A237E),
                                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _editLevel(level),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF5B3FD8),
                                      side: const BorderSide(color: Color(0xFF5B3FD8)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Add Info'),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatefulWidget {
  final String title; final IconData icon; final Widget? content; final VoidCallback onEdit;
  const _ProfileSection({required this.title, required this.icon, this.content, required this.onEdit});
  @override State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8F7FF), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [ListTile(onTap: () => setState(() => _isExpanded = !_isExpanded), leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Icon(widget.icon, color: const Color(0xFF5B3FD8), size: 20)), title: Text(widget.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))), trailing: GestureDetector(onTap: widget.onEdit, child: Icon(widget.content == null ? Icons.add : Icons.edit_outlined, color: const Color(0xFF5B3FD8), size: 20))), if (_isExpanded && widget.content != null) Padding(padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16), child: widget.content!)]),
    );
  }
}
