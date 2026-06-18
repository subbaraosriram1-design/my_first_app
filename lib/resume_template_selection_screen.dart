import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'resume_preview_screen.dart';

class ResumeTemplateSelectionPage extends StatelessWidget {
  final Map<String, dynamic> resumeData;
  
  const ResumeTemplateSelectionPage({super.key, required this.resumeData});

  final List<Map<String, String>> templates = const [
    {
      'name': 'AltaCV',
      'type': 'Professional Sidebar',
      'description': 'Sophisticated two-column layout with a sleek sidebar for skills and contact info.',
      'image': 'https://raw.githubusercontent.com/liantze/AltaCV/master/sample-1.png',
    },
    {
      'name': 'Deedy Resume',
      'type': 'Compact Tech',
      'description': 'The classic two-column engineering layout. Efficient, clean, and highly readable.',
      'image': 'https://raw.githubusercontent.com/deedy/Deedy-Resume/master/preview.png',
    },
    {
      'name': 'Awesome-CV',
      'type': 'Modern Professional',
      'description': 'A premium design with distinct typography and elegant section headers.',
      'image': 'https://raw.githubusercontent.com/posquit0/Awesome-CV/master/examples/resume.png',
    },
    {
      'name': 'ModernCV',
      'type': 'Traditional/Classic',
      'description': 'A formal and structured approach, widely recognized in academic and corporate circles.',
      'image': 'https://mirrors.ibiblio.org/CTAN/macros/latex/contrib/moderncv/examples/template-banking.png',
    },
    {
      'name': 'Twenty Seconds CV',
      'type': 'Creative Timeline',
      'description': 'Dynamic sidebar and timeline structure designed to grab attention quickly.',
      'image': 'https://raw.githubusercontent.com/spagnuolococuzza/twentysecondcv/master/template.png',
    },
    {
      'name': 'Medium Length Professional CV',
      'type': 'Business Balanced',
      'description': 'A clean, multi-page friendly layout that balances whitespace and content perfectly.',
      'image': 'https://raw.githubusercontent.com/mcanu/medium-length-cv/master/preview.png',
    },
    {
      'name': 'Friggeri CV',
      'type': 'Graphic Sidebar',
      'description': 'Unique creative layout with modern fonts and colored section highlights.',
      'image': 'https://raw.githubusercontent.com/afriggeri/cv/master/cv.png',
    },
    {
      'name': 'RenderCV Classic Theme',
      'type': 'Clean ATS-Friendly',
      'description': 'Optimized for parsing systems while maintaining a crisp, professional look.',
      'image': 'https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/classic_theme_preview.png',
    },
    {
      'name': 'Academic CV',
      'type': 'Research/Faculty',
      'description': 'Detailed layout focused on publications, research grants, and teaching history.',
      'image': 'https://raw.githubusercontent.com/kjhealy/latex-custom-cv/master/cv.png',
    },
    {
      'name': 'Elegant Resume',
      'type': 'Premium Minimalist',
      'description': 'Refined typography and delicate spacing for an executive-level presentation.',
      'image': 'https://raw.githubusercontent.com/mcanu/elegant-resume/master/preview.png',
    },
    {
      'name': 'Harshibar’s Resume',
      'type': 'Software Engineering',
      'description': 'The popular tech layout focused on impact, projects, and technical stack.',
      'image': 'https://raw.githubusercontent.com/harshibar/resume/master/preview.png',
    },
    {
      'name': 'Northeastern University COS Faculty CV',
      'type': 'Official Academic',
      'description': 'Strict academic formatting following university standards for faculty recruitment.',
      'image': 'https://www.overleaf.com/img/templates/northeastern-university-cos-faculty-cv-template.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Choose Resume Template', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF5B3FD8).withValues(alpha: 0.05),
            width: double.infinity,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF5B3FD8)),
                  const SizedBox(width: 8),
                  Text(
                    'AI-Enhanced Overleaf Layout Gallery',
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF5B3FD8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _buildTemplateCard(context, template);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, Map<String, String> template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layout Preview Image with CachedNetworkImage
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 0.78, // Standard resume aspect
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: template['image']!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade50,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5B3FD8))),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Preview Unavailable', style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        template['type']!,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template['name']!,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                Text(
                  template['description']!,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResumePreviewScreen(
                            resumeData: resumeData,
                            templateName: template['name']!,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B3FD8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Use This Template', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
