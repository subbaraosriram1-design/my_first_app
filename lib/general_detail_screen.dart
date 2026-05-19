import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class GeneralDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final String category;

  const GeneralDetailScreen({super.key, required this.item, required this.category});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? item['name'] ?? 'Details';
    final company = item['company'] ?? item['provider'] ?? '';
    final location = item['location'] ?? 'Remote';
    final description = item['description'] ?? 'No description available.';
    final skills = item['skills'] as List? ?? [];
    final match = item['match'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(category, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B3FD8).withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForCategory(category),
                    color: const Color(0xFF5B3FD8),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        company,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.location_on_outlined, location),
            if (item['salary'] != null || item['stipend'] != null || item['fees'] != null)
              _buildInfoRow(Icons.payments_outlined, item['salary'] ?? item['stipend'] ?? item['fees']),
            if (item['duration'] != null)
              _buildInfoRow(Icons.timer_outlined, item['duration']),
            if (match > 0)
              _buildInfoRow(Icons.auto_awesome, '$match% Match with your profile', color: Colors.orange),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            Text(
              'About this $category',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
            
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Required Skills',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    skill.toString(),
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _launchURL(context, item['link'] ?? item['applyLink'] ?? item['courseLink'] ?? 'https://google.com'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3FD8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              _getButtonLabel(category),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: color ?? Colors.grey.shade700,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String cat) {
    if (cat.contains('Job')) return Icons.business_center;
    if (cat.contains('Internship')) return Icons.assignment_ind;
    if (cat.contains('Course')) return Icons.school;
    if (cat.contains('Cert')) return Icons.verified;
    return Icons.star;
  }

  String _getButtonLabel(String cat) {
    if (cat.contains('Job') || cat.contains('Internship')) return 'Apply Now';
    if (cat.contains('Course')) return 'View Course';
    if (cat.contains('Cert')) return 'Get Certified';
    return 'View Details';
  }
}
