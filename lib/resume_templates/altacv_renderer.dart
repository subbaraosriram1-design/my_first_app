import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AltaCVRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final normal = fonts['normal']!;
    final bold = fonts['bold']!;
    final italic = fonts['italic']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => [
          pw.FullPage(
            ignoreMargins: true,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // SIDEBAR (Left)
                pw.Container(
                  width: format.width * 0.33,
                  color: PdfColors.blueGrey50,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Profile Image
                      if (data['profileImage'] != null)
                        pw.Center(
                          child: pw.Container(
                            width: 100,
                            height: 100,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              image: pw.DecorationImage(
                                image: pw.MemoryImage(base64Decode(data['profileImage'])),
                                fit: pw.BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      pw.SizedBox(height: 20),
                      
                      _sectionTitle('CONTACT', bold),
                      _infoItem(pw.IconData(0xe0e1), data['email'] ?? '', normal),
                      _infoItem(pw.IconData(0xe0cd), data['phone'] ?? '', normal),
                      _infoItem(pw.IconData(0xe0c8), data['address'] ?? '', normal),
                      if (data['linkedin'] != null) _infoItem(pw.IconData(0xe894), 'LinkedIn', normal),
                      
                      pw.SizedBox(height: 25),
                      _sectionTitle('SKILLS', bold),
                      pw.Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: (data['skills'] as List? ?? []).map((s) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blueGrey700,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(s.toString(), style: pw.TextStyle(color: PdfColors.white, fontSize: 8, font: normal)),
                        )).toList(),
                      ),
                      
                      pw.SizedBox(height: 25),
                      _sectionTitle('LANGUAGES', bold),
                      ... (data['languages'] as List? ?? []).map((l) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(l['name'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9)),
                            pw.Text(l['proficiency'] ?? '', style: pw.TextStyle(font: italic, fontSize: 8, color: PdfColors.grey700)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                
                // MAIN CONTENT (Right)
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(data['fullName']?.toUpperCase() ?? '', style: pw.TextStyle(font: bold, fontSize: 24, color: PdfColors.blueGrey900)),
                        pw.Text(data['tagline'] ?? '', style: pw.TextStyle(font: normal, fontSize: 14, color: PdfColors.blueGrey600)),
                        pw.SizedBox(height: 20),
                        
                        _mainSectionTitle('SUMMARY', bold),
                        pw.Text(data['summary'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10, lineSpacing: 1.5)),
                        
                        pw.SizedBox(height: 25),
                        _mainSectionTitle('EXPERIENCE', bold),
                        ... (data['experienceList'] as List? ?? []).map((e) => _buildExperienceItem(e, bold, normal, italic)),
                        
                        pw.SizedBox(height: 25),
                        _mainSectionTitle('EDUCATION', bold),
                        ... (data['educationList'] as List? ?? []).map((edu) => _buildEducationItem(edu, bold, normal)),

                        pw.SizedBox(height: 25),
                        _mainSectionTitle('PROJECTS', bold),
                        ... (data['projects'] as List? ?? []).map((p) => _buildProjectItem(p, bold, normal)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.blueGrey900, letterSpacing: 1.2)),
          pw.Container(height: 1, width: 20, color: PdfColors.blueGrey900, margin: const pw.EdgeInsets.only(top: 2)),
        ],
      ),
    );
  }

  static pw.Widget _mainSectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.blueGrey900, letterSpacing: 1.2)),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey400)),
        ],
      ),
    );
  }

  static pw.Widget _infoItem(pw.IconData icon, String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Icon(icon, size: 10, color: PdfColors.blueGrey700),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.blueGrey800))),
        ],
      ),
    );
  }

  static pw.Widget _buildExperienceItem(dynamic e, pw.Font bold, pw.Font normal, pw.Font italic) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e['title'] ?? '', style: pw.TextStyle(font: bold, fontSize: 10)),
              pw.Text('${e['startDate']} - ${e['endDate']}', style: pw.TextStyle(font: normal, fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
          pw.Text(e['organization'] ?? '', style: pw.TextStyle(font: italic, fontSize: 9, color: PdfColors.blueGrey700)),
          pw.SizedBox(height: 4),
          pw.Bullet(text: e['description'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9, lineSpacing: 1.2)),
        ],
      ),
    );
  }

  static pw.Widget _buildEducationItem(dynamic edu, pw.Font bold, pw.Font normal) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(edu['school'] ?? '', style: pw.TextStyle(font: bold, fontSize: 10)),
              pw.Text(edu['level'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
          pw.Text('${edu['yearFrom']} - ${edu['yearTo']}', style: pw.TextStyle(font: normal, fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildProjectItem(dynamic p, pw.Font bold, pw.Font normal) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p['title'] ?? '', style: pw.TextStyle(font: bold, fontSize: 10)),
          pw.Text(p['description'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9)),
        ],
      ),
    );
  }
}
