import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'firebase_service.dart';
import 'ai_insights_screen.dart';
import 'notification_service.dart';
import 'reminder_detail_screen.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          'This is the $title page',
          style: GoogleFonts.poppins(fontSize: 18),
        ),
      ),
    );
  }
}

class MoreOptionsPage extends StatefulWidget {
  const MoreOptionsPage({super.key});

  @override
  State<MoreOptionsPage> createState() => _MoreOptionsPageState();
}

class _MoreOptionsPageState extends State<MoreOptionsPage> {
  Map<String, dynamic>? _resumeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResumeData();
  }

  Future<void> _loadResumeData() async {
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      final data = await FirebaseService.instance.getResume(user.uid);
      if (mounted) {
        setState(() {
          _resumeData = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text('My Resume Info', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _resumeData == null
          ? Center(child: Text('No resume data found.', style: GoogleFonts.poppins()))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const Divider(height: 40),
                  _buildSection('Personal Details', [
                    _buildInfoRow('Email', _resumeData?['email']),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Summary', [
                    Text(_resumeData?['summary'] ?? 'No summary added.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Skills', _buildSkillsList()),
                  const SizedBox(height: 24),
                  _buildSection('Education', _buildEducationList()),
                  const SizedBox(height: 24),
                  _buildSection('Projects', _buildProjectsList()),
                  const SizedBox(height: 24),
                  _buildSection('Student Interests', _buildInterestsList()),
                  const SizedBox(height: 24),
                  _buildSection('Test Scores', _buildTestScoresList()),
                  const SizedBox(height: 24),
                  _buildSection('Certifications', _buildCertificationsList()),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (_resumeData?['profileImage'] != null)
          CircleAvatar(
            radius: 40,
            backgroundImage: MemoryImage(base64Decode(_resumeData!['profileImage'])),
          )
        else
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _resumeData?['fullName'] ?? 'N/A',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                _resumeData?['tagline'] ?? 'No tagline added',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, dynamic content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF5B3FD8)),
        ),
        const SizedBox(height: 12),
        if (content is List<Widget>) ...content else content,
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsList() {
    final skills = _resumeData?['skills'];
    if (skills == null || skills is! List || skills.isEmpty) {
      return Text('No skills added.', style: GoogleFonts.poppins(color: Colors.grey));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map<Widget>((skill) {
        return Chip(
          label: Text(skill.toString(), style: GoogleFonts.poppins(fontSize: 12)),
          backgroundColor: const Color(0xFF5B3FD8).withAlpha(20),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }

  Widget _buildInterestsList() {
    final interests = _resumeData?['hobbies'];
    if (interests == null || interests is! List || interests.isEmpty) {
      return Text('No interests added.', style: GoogleFonts.poppins(color: Colors.grey));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map<Widget>((interest) {
        return Chip(
          label: Text(interest.toString(), style: GoogleFonts.poppins(fontSize: 12)),
          backgroundColor: Colors.orange.withAlpha(20),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }

  List<Widget> _buildProjectsList() {
    final projects = _resumeData?['projects'] ?? _resumeData?['experience'];
    if (projects == null || projects is! List || projects.isEmpty) {
      return [Text('No projects added.', style: GoogleFonts.poppins(color: Colors.grey))];
    }

    return projects.map<Widget>((proj) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(proj['title'] ?? proj['jobTitle'] ?? 'N/A', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(proj['description'] ?? proj['company'] ?? 'N/A', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
              Text(
                '${_formatDate(proj['startDate'])} - ${_formatDate(proj['endDate'])}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEducationList() {
    final education = _resumeData?['educationList'];
    if (education == null || education is! List || education.isEmpty) {
      return [Text('No education added.', style: GoogleFonts.poppins(color: Colors.grey))];
    }

    return education.map<Widget>((edu) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(edu['school'] ?? 'N/A', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(edu['classOf'] ?? edu['degree'] ?? edu['level'] ?? 'N/A', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
              Text(
                '${edu['yearFrom'] ?? edu['startYear'] ?? ''} - ${edu['yearTo'] ?? edu['endYear'] ?? ''} | Grade: ${edu['gradeFrom'] ?? edu['additionalInfo'] ?? ''}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTestScoresList() {
    final scores = _resumeData?['testScores'];
    if (scores == null || scores is! List || scores.isEmpty) {
      return [Text('No test scores added.', style: GoogleFonts.poppins(color: Colors.grey))];
    }

    return scores.map<Widget>((s) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(s['testName'] ?? 'N/A', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text('Score: ${s['score'] ?? 'N/A'}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
        trailing: Text(s['date'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
      );
    }).toList();
  }

  List<Widget> _buildCertificationsList() {
    final certs = _resumeData?['certifications'];
    if (certs == null || certs is! List || certs.isEmpty) {
      return [Text('No certifications added.', style: GoogleFonts.poppins(color: Colors.grey))];
    }

    return certs.map<Widget>((c) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(c['name'] ?? 'N/A', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text('${c['skill'] ?? 'N/A'} - ${c['level'] ?? 'Basic'}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
      );
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Present';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class WorkPage extends StatelessWidget {
  const WorkPage({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderPage(title: 'Work');
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _activeNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      final reminders = List.from(data?['reminders'] ?? []);
      final active = NotificationService.instance.getDueNotifications(reminders);
      if (mounted) {
        setState(() {
          _activeNotifications = active;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _activeNotifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _activeNotifications.length,
                  itemBuilder: (context, index) {
                    final n = _activeNotifications[index];
                    return _buildNotificationCard(n);
                  },
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final reminder = n['reminder'];
    final type = reminder['type'];
    Color color = const Color(0xFF10B981);
    IconData icon = Icons.notifications_active_outlined;

    if (type == 'exam') {
      color = const Color(0xFF0F172A);
      icon = Icons.school_outlined;
    } else if (type == 'assignment') {
      color = const Color(0xFF059669);
      icon = Icons.assignment_outlined;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReminderDetailScreen(reminder: reminder)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['message'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['time'] ?? 'Today',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when tasks need attention.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      final data = await FirebaseService.instance.getResume(user.uid);
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _userData?['fullName'] ?? 'User Name',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    _userData?['tagline'] ?? 'Tagline',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE4E6).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_outlined, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reward points',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '0',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildMenuItem(Icons.settings_outlined, 'Account settings'),
                  _buildMenuItem(Icons.people_outline, 'Manage roles'),
                  _buildMenuItem(Icons.smart_toy_outlined, 'AI Insights'),
                  _buildMenuItem(Icons.mail_outline, 'Invite friends & earn'),
                  _buildMenuItem(Icons.verified_user_outlined, 'Privacy policy'),
                  _buildMenuItem(Icons.info_outline, 'About spikeview'),
                  _buildMenuItem(Icons.logout, 'Sign out', isDestructive: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF64748B), size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
        ),
        onTap: () async {
          if (isDestructive) {
            await FirebaseService.instance.logout();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          } else if (title == 'AI Insights') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AiInsightsScreen()),
            );
          } else {
            // Placeholder for other menu items
          }
        },
      ),
    );
  }
}
