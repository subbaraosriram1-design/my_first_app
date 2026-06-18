import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'firebase_service.dart';
import 'resume_template_manager.dart';

class ResumeApplicationScreen extends StatefulWidget {
  const ResumeApplicationScreen({super.key});

  @override
  State<ResumeApplicationScreen> createState() => _ResumeApplicationScreenState();
}

class _ResumeApplicationScreenState extends State<ResumeApplicationScreen> {
  final _templateController = TextEditingController();
  Map<String, dynamic>? _generatedContent;
  bool _isLoading = false;
  ResumeData? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Default sample template
    _templateController.text = jsonEncode({
      "name": "Standard Professional",
      "sections": [
        {"title": "Summary", "type": "text"},
        {"title": "Education", "type": "list"},
        {"title": "Skills", "type": "grid"},
        {"title": "Projects", "type": "list"}
      ]
    });
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      setState(() => _isLoading = true);
      final data = await FirebaseService.instance.getResume(userId);
      if (data != null) {
        setState(() {
          _userData = ResumeData.fromFirestore(data);
        });
      }
      setState(() => _isLoading = false);
    }
  }

  void _generateResume() {
    if (_userData == null) return;

    try {
      final template = ResumeTemplateManager.loadTemplateFromJson(_templateController.text);
      final content = ResumeTemplateManager.generateResumeContent(
        userData: _userData!,
        template: template,
      );
      setState(() {
        _generatedContent = content;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error in template: $e')),
      );
    }
  }

  Future<void> _exportPdf() async {
    if (_generatedContent == null) return;
    
    try {
      final pdfBytes = await ResumeTemplateManager.generatePdf(_generatedContent!);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Resume_${_userData?.fullName ?? 'Export'}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Resume Builder', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTemplateInput(),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _generateResume,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Preview'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_generatedContent != null)
                        OutlinedButton.icon(
                          onPressed: _exportPdf,
                          icon: const Icon(Icons.download),
                          label: const Text('Download PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_generatedContent != null) _buildPreview(),
              ],
            ),
          ),
    );
  }

  Widget _buildTemplateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resume Template (JSON)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          'Paste your "temple file" below to define the structure.',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _templateController,
          maxLines: 8,
          style: GoogleFonts.sourceCodePro(fontSize: 13),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final header = _generatedContent!['header'];
    final sections = _generatedContent!['sections'] as List;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(header['name'], style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(header['tagline'], style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(header['contact'], style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF10B981))),
          const Divider(height: 32),

          // Sections
          ...sections.map((s) => _buildSection(s)).toList(),
        ],
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section['title'].toUpperCase(),
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          _buildSectionData(section),
        ],
      ),
    );
  }

  Widget _buildSectionData(Map<String, dynamic> section) {
    final data = section['data'];
    final type = section['type'];

    if (type == 'text') {
      return Text(data.toString(), style: GoogleFonts.poppins(fontSize: 14, height: 1.5));
    }

    if (type == 'grid' && data is List) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: data.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(item.toString(), style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.w500)),
        )).toList(),
      );
    }

    if (type == 'list' && data is List) {
      return Column(
        children: data.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item is Map) ...[
                      Text(item.values.first.toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (item.length > 1) Text(item.values.elementAt(1).toString(), style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
                    ] else
                      Text(item.toString(), style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      );
    }

    return Text(data.toString());
  }
}
