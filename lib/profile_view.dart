import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firebase_service.dart';
import 'resume_builder_page.dart'; // To use the Experience model

class ProfileView extends StatefulWidget {
  final String username; // Now represents Firebase User ID
  const ProfileView({super.key, required this.username});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Map<String, dynamic>? _resumeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await FirebaseService.instance.getResume(widget.username);
    setState(() {
      _resumeData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_resumeData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No cloud data found. Please complete the Cloud Resume Builder.'),
        ),
      );
    }

    // Firestore stores these as Lists directly
    final List<dynamic> experienceList = _resumeData!['experience'] ?? [];
    final List<dynamic> skillsList = _resumeData!['skills'] ?? [];
    final List<dynamic> fileList = _resumeData!['fileNames'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.person, 'Cloud Profile'),
          _buildInfoCard([
            _buildInfoRow('Full Name', _resumeData!['fullName'] ?? 'N/A'),
            _buildInfoRow('Contact Email', _resumeData!['email'] ?? 'N/A'),
          ]),
          
          _buildSectionTitle(Icons.school, 'Education'),
          _buildInfoCard([
            _buildInfoRow('Highest Degree', _resumeData!['education'] ?? 'N/A'),
          ]),

          _buildSectionTitle(Icons.work, 'Work Experience'),
          if (experienceList.isEmpty)
            const Padding(padding: EdgeInsets.only(left: 10), child: Text('No experience added.'))
          else
            ...experienceList.map((expJson) {
              try {
                final exp = Experience.fromJson(expJson as Map<String, dynamic>);
                final startStr = exp.startDate != null ? DateFormat('MMM yyyy').format(exp.startDate!) : 'N/A';
                final endStr = exp.endDate != null ? DateFormat('MMM yyyy').format(exp.endDate!) : 'Present';
                
                return _buildInfoCard([
                  Text(exp.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(exp.company, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('$startStr - $endStr', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ]);
              } catch (e) {
                return const SizedBox.shrink();
              }
            }).toList(),

          _buildSectionTitle(Icons.star, 'Skills'),
          if (skillsList.isEmpty)
            const Padding(padding: EdgeInsets.only(left: 10), child: Text('No skills added.'))
          else
            Wrap(
              spacing: 8.0,
              children: skillsList.map((skill) => Chip(label: Text(skill.toString()))).toList(),
            ),

          _buildSectionTitle(Icons.attach_file, 'Documents'),
          _buildInfoCard(fileList.isEmpty 
            ? [const Text('No documents uploaded.')]
            : fileList.map((file) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(file.toString()),
                  ],
                ),
              )).toList()
          ),
          
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadData, 
              icon: const Icon(Icons.sync), 
              label: const Text('Refresh from Cloud')
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
