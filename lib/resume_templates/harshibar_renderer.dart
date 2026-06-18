import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class HarshibarRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final normal = fonts['normal']!;
    final bold = fonts['bold']!;
    final italic = fonts['italic']!;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(data['fullName'] ?? '', style: pw.TextStyle(font: bold, fontSize: 32)),
                  pw.Text(data['tagline'] ?? '', style: pw.TextStyle(font: normal, fontSize: 14, color: PdfColors.grey700)),
                ]
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(data['email'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
                  pw.Text(data['phone'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
                  pw.Text(data['linkedin'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
                ]
              )
            ]
          ),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 1, color: PdfColors.black),
          pw.SizedBox(height: 20),
          
          _section('Experience', bold),
          ... (data['experienceList'] as List? ?? []).map((e) => _buildExperience(e, bold, normal, italic)),
          
          _section('Projects', bold),
          ... (data['projects'] as List? ?? []).map((p) => _buildProject(p, bold, normal)),
          
          _section('Education', bold),
          ... (data['educationList'] as List? ?? []).map((edu) => _buildEducation(edu, bold, normal)),
          
          _section('Skills', bold),
          pw.Text((data['skills'] as List?)?.join(' | ') ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _section(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 15, bottom: 8),
      child: pw.Text(title.toUpperCase(), style: pw.TextStyle(font: font, fontSize: 14, letterSpacing: 1.2)),
    );
  }

  static pw.Widget _buildExperience(dynamic e, pw.Font bold, pw.Font normal, pw.Font italic) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e['organization'] ?? '', style: pw.TextStyle(font: bold, fontSize: 11)),
              pw.Text('${e['startDate']} - ${e['endDate']}', style: pw.TextStyle(font: normal, fontSize: 10)),
            ]
          ),
          pw.Text(e['title'] ?? '', style: pw.TextStyle(font: italic, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(e['description'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9)),
        ]
      ),
    );
  }

  static pw.Widget _buildProject(dynamic p, pw.Font bold, pw.Font normal) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p['title'] ?? '', style: pw.TextStyle(font: bold, fontSize: 11)),
          pw.Text(p['description'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9)),
        ]
      ),
    );
  }

  static pw.Widget _buildEducation(dynamic edu, pw.Font bold, pw.Font normal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('${edu['school']}, ${edu['level']}', style: pw.TextStyle(font: bold, fontSize: 10)),
        pw.Text('${edu['yearFrom']} - ${edu['yearTo']}', style: pw.TextStyle(font: normal, fontSize: 10)),
      ]
    );
  }
}
