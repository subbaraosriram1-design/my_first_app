import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../resume_template_manager.dart';

class CustomTemplateRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final manager = ResumeTemplateManager.instance;
    if (!manager.hasCustomTemplate) return;

    // For now, we fall back to a clean standard rendering because direct HTML-to-PDF is not reliable in Flutter
    // However, we use the HTML content as a reference for layout structure in a future iteration.
    
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(data, fonts),
              pw.SizedBox(height: 20),
              if (data.containsKey('summary')) _buildSection('SUMMARY', data['summary'], fonts),
              if (data.containsKey('experienceList')) _buildExperienceList(data['experienceList'], fonts),
              if (data.containsKey('educationList')) _buildEducationList(data['educationList'], fonts),
              if (data.containsKey('skills')) _buildSkills(data['skills'], fonts),
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _buildHeader(Map<String, dynamic> data, Map<String, pw.Font> fonts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(data['fullName'] ?? '', style: pw.TextStyle(font: fonts['bold'], fontSize: 24)),
        pw.Text('${data['email'] ?? ''} | ${data['phone'] ?? ''}', style: pw.TextStyle(font: fonts['normal'], fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildSection(String title, String content, Map<String, pw.Font> fonts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.Text(title, style: pw.TextStyle(font: fonts['bold'], fontSize: 14)),
        pw.SizedBox(height: 4),
        pw.Text(content, style: pw.TextStyle(font: fonts['normal'], fontSize: 10)),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildExperienceList(dynamic list, Map<String, pw.Font> fonts) {
    if (list is! List) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.Text('EXPERIENCE', style: pw.TextStyle(font: fonts['bold'], fontSize: 14)),
        ...list.map((e) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e['title'] ?? '', style: pw.TextStyle(font: fonts['bold'], fontSize: 11)),
                  pw.Text('${e['startDate'] ?? ''} - ${e['endDate'] ?? ''}', style: pw.TextStyle(font: fonts['normal'], fontSize: 9)),
                ],
              ),
              pw.Text(e['organization'] ?? '', style: pw.TextStyle(font: fonts['italic'], fontSize: 10)),
            ],
          ),
        )),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildEducationList(dynamic list, Map<String, pw.Font> fonts) {
    if (list is! List) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.Text('EDUCATION', style: pw.TextStyle(font: fonts['bold'], fontSize: 14)),
        ...list.map((edu) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${edu['school'] ?? ''} (${edu['level'] ?? ''})', style: pw.TextStyle(font: fonts['bold'], fontSize: 11)),
              pw.Text('${edu['yearFrom'] ?? ''} - ${edu['yearTo'] ?? ''}', style: pw.TextStyle(font: fonts['normal'], fontSize: 9)),
            ],
          ),
        )),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildSkills(dynamic list, Map<String, pw.Font> fonts) {
    if (list is! List) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.Text('SKILLS', style: pw.TextStyle(font: fonts['bold'], fontSize: 14)),
        pw.SizedBox(height: 4),
        pw.Text(list.join(', '), style: pw.TextStyle(font: fonts['normal'], fontSize: 10)),
      ],
    );
  }
}
