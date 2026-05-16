import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai_service.dart';
import 'firebase_service.dart';

class RoadmapScreen extends StatefulWidget {
  final String skill;
  final String careerContext;
  const RoadmapScreen({super.key, required this.skill, required this.careerContext});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final AiService _aiService = GroqAiService();
  bool _isLoading = true;
  Map<String, dynamic>? _resources;
  String? _error;
  String _selectedLevel = 'Basic';
  
  Map<String, dynamic> _userProgress = {};

  @override
  void initState() {
    super.initState();
    _fetchResources();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (mounted) {
        setState(() {
          _userProgress = data?['resourceProgress'] ?? {};
        });
      }
    }
  }

  Future<void> _fetchResources() async {
    try {
      final resources = await _aiService.getSkillResources(widget.skill, widget.careerContext);
      if (mounted) {
        setState(() {
          _resources = resources;
          _isLoading = false;
        });
        _updateResourceCounts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateResourceCounts() async {
    if (_resources == null) return;
    int total = 0;
    _resources!['levels']?.forEach((level, data) {
      total += (data['trainings'] as List).length;
      total += (data['youtube'] as List).length;
      total += (data['docs'] as List).length;
    });

    final skillProgress = _userProgress[widget.skill] ?? {};
    if (skillProgress['totalResources'] != total) {
      skillProgress['totalResources'] = total;
      _userProgress[widget.skill] = skillProgress;
      await FirebaseService.instance.saveResume(
        FirebaseService.instance.currentUserId!, 
        {'resourceProgress': _userProgress}
      );
    }
  }

  Future<void> _markCompleted(String resourceTitle, String resourceLink) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    final skillProgress = Map<String, dynamic>.from(_userProgress[widget.skill] ?? {});
    List completed = List.from(skillProgress['completedResources'] ?? []);
    
    if (!completed.any((r) => r['link'] == resourceLink)) {
      completed.add({'title': resourceTitle, 'link': resourceLink, 'date': DateTime.now().toIso8601String()});
      skillProgress['completedResources'] = completed;
      _userProgress[widget.skill] = skillProgress;

      // Cross-skill synchronization
      _userProgress.forEach((sName, sData) {
        if (sName != widget.skill) {
          // If this specific resource exists in another skill, mark it completed there too
          // (Note: In a real app we'd need to fetch resources for all skills first)
        }
      });

      await FirebaseService.instance.saveResume(userId, {'resourceProgress': _userProgress});
      
      // Check if level is fully completed
      await _checkLevelCompletion();
      
      setState(() {});
    }
  }

  Future<void> _checkLevelCompletion() async {
    final levelData = _resources?['levels']?[_selectedLevel];
    if (levelData == null) return;

    List resourcesInLevel = [];
    resourcesInLevel.addAll(levelData['trainings']);
    resourcesInLevel.addAll(levelData['youtube']);
    resourcesInLevel.addAll(levelData['docs']);

    final completed = _userProgress[widget.skill]?['completedResources'] ?? [];
    bool allDone = resourcesInLevel.every((res) => completed.any((c) => c['link'] == res['link']));

    if (allDone) {
      // Add to user skills with level
      final userId = FirebaseService.instance.currentUserId!;
      final userData = await FirebaseService.instance.getResume(userId);
      List<dynamic> certs = List.from(userData?['certifications'] ?? []);
      
      bool alreadyAdded = certs.any((c) => c['name'] == '${widget.skill} Mastery' && c['level'] == _selectedLevel);
      if (!alreadyAdded) {
        certs.add({
          'name': '${widget.skill} Mastery',
          'skill': widget.skill,
          'level': _selectedLevel,
          'date': DateTime.now().toIso8601String(),
          'type': 'Automated'
        });
        await FirebaseService.instance.saveResume(userId, {'certifications': certs});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CONGRATULATIONS! You have completed the $_selectedLevel level for ${widget.skill}! This has been added to your profile certifications.'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 5),
            )
          );
        }
      }
    }
  }

  Future<void> _uploadAttachment(String resourceLink) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final skillProgress = Map<String, dynamic>.from(_userProgress[widget.skill] ?? {});
      List completed = List.from(skillProgress['completedResources'] ?? []);
      
      for (var res in completed) {
        if (res['link'] == resourceLink) {
          res['attachment'] = result.files.single.name; // In a real app, upload file to storage
        }
      }
      
      skillProgress['completedResources'] = completed;
      _userProgress[widget.skill] = skillProgress;
      await FirebaseService.instance.saveResume(FirebaseService.instance.currentUserId!, {'resourceProgress': _userProgress});
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Skill Roadmap', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkillHeader(),
                      const SizedBox(height: 32),
                      _buildLevelSelector(),
                      const SizedBox(height: 32),
                      _buildLevelContent(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSkillHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withAlpha(10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mastering ${widget.skill}',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
          ),
          const SizedBox(height: 8),
          Text(
            _resources?['description'] ?? 'Every step you take brings you closer to your goal!',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    final levels = ['Basic', 'Intermediate', 'Advanced'];
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: levels.map((level) {
          final isSelected = _selectedLevel == level;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedLevel = level),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5B3FD8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  level,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLevelContent() {
    final levelData = _resources?['levels']?[_selectedLevel];
    if (levelData == null) {
      return Center(
        child: Text('No resources available for this level yet.', style: GoogleFonts.poppins(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResourceSection('Personalized Trainings', levelData['trainings'], Icons.school_outlined, const Color(0xFF5B3FD8)),
        const SizedBox(height: 24),
        _buildResourceSection('Motivating Tutorials', levelData['youtube'], Icons.play_circle_outline, Colors.red),
        const SizedBox(height: 24),
        _buildResourceSection('In-depth Knowledge', levelData['docs'], Icons.description_outlined, const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildResourceSection(String title, List<dynamic>? items, IconData icon, Color color) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildResourceCard(item['title'], item['link'], color)).toList(),
      ],
    );
  }

  Future<void> _launchURL(String title, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // "if uer opend any skill in crease percentage"
        await _markCompleted(title, urlString);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildResourceCard(String? title, String? link, Color color) {
    final completed = (_userProgress[widget.skill]?['completedResources'] as List?) ?? [];
    final bool isDone = completed.any((r) => r['link'] == link);
    final String? attachmentName = completed.firstWhere((r) => r['link'] == link, orElse: () => {})['attachment'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? color.withAlpha(5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDone ? color.withAlpha(30) : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(title ?? 'Resource', style: GoogleFonts.poppins(fontSize: 14, fontWeight: isDone ? FontWeight.bold : FontWeight.w500, color: isDone ? color : Colors.black87)),
        leading: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? color : Colors.grey, size: 20),
        trailing: IconButton(
          icon: Icon(Icons.open_in_new, size: 18, color: color),
          onPressed: () => _launchURL(title!, link!),
        ),
        onExpansionChanged: (expanded) {
          if (expanded && !isDone) {
            // "If user opened any skill increase percentage" -> We count opening as partial but Mark Completed as full
            // For simplicity in this logic, we'll follow the "Mark Completed" requirement for full percentage
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isDone ? null : () => _markCompleted(title!, link!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    child: Text(isDone ? 'Completed' : 'Mark as Completed'),
                  ),
                ),
                const SizedBox(width: 12),
                if (isDone) ...[
                  IconButton(
                    icon: Icon(Icons.attach_file, color: attachmentName != null ? color : Colors.grey),
                    onPressed: () => _uploadAttachment(link!),
                    tooltip: attachmentName ?? 'Add Attachment',
                  ),
                  if (attachmentName != null)
                    Expanded(child: Text(attachmentName, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
