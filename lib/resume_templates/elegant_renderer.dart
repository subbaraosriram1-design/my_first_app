import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ElegantRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final loraNormal = fonts['loraNormal']!;
    final loraBold = fonts['loraBold']!;
    final loraItalic = fonts['loraItalic']!;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(50),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(data['fullName']?.toUpperCase() ?? '', style: pw.TextStyle(font: loraBold, fontSize: 32, letterSpacing: 2)),
                pw.SizedBox(height: 5),
                pw.Container(height: 1, width: 40, color: PdfColors.black),
                pw.SizedBox(height: 10),
                pw.Text(data['tagline']?.toUpperCase() ?? '', style: pw.TextStyle(font: loraNormal, fontSize: 10, letterSpacing: 3, color: PdfColors.grey700)),
                pw.SizedBox(height: 20),
                pw.Text('${data['email']}  |  ${data['phone']}  |  ${data['address']}', style: pw.TextStyle(font: loraNormal, fontSize: 9)),
              ],
            ),
          ),
          pw.SizedBox(height: 50),
          
          _section('Profile', loraBold),
          pw.Text(data['summary'] ?? '', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: loraNormal, fontSize: 11, lineSpacing: 1.5)),
          pw.SizedBox(height: 30),
          
          _section('Experience', loraBold),
          ... (data['experienceList'] as List? ?? []).map((e) => _buildExperience(e, loraBold, loraNormal, loraItalic)),
          
          _section('Education', loraBold),
          ... (data['educationList'] as List? ?? []).map((edu) => _buildEducation(edu, loraBold, loraNormal)),
          
          pw.SizedBox(height: 30),
          pw.Center(child: pw.Text('S K I L L S', style: pw.TextStyle(font: loraBold, fontSize: 12, letterSpacing: 2))),
          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text((data['skills'] as List?)?.join('  •  ') ?? '', style: pw.TextStyle(font: loraNormal, fontSize: 10))),
        ],
      ),
    );
  }

  static pw.Widget _section(String title, pw.Font font) {
    return pw.Column(
      children: [
        pw.Center(child: pw.Text(title.toUpperCase(), style: pw.TextStyle(font: font, fontSize: 14, letterSpacing: 2))),
        pw.SizedBox(height: 15),
      ]
    );
  }

  static pw.Widget _buildExperience(dynamic e, pw.Font bold, pw.Font normal, pw.Font italic) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Text(e['organization']?.toUpperCase() ?? '', style: pw.TextStyle(font: bold, fontSize: 11, letterSpacing: 1)),
          pw.Text(e['title'] ?? '', style: pw.TextStyle(font: italic, fontSize: 10)),
          pw.Text('${e['startDate']} - ${e['endDate']}', style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Text(e['description'] ?? '', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: normal, fontSize: 10)),
        ]
      ),
    );
  }

  static pw.Widget _buildEducation(dynamic edu, pw.Font bold, pw.Font normal) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        children: [
          pw.Text(edu['school']?.toUpperCase() ?? '', style: pw.TextStyle(font: bold, fontSize: 11, letterSpacing: 1)),
          pw.Text(edu['level'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
          pw.Text('${edu['yearFrom']} - ${edu['yearTo']}', style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey700)),
        ]
      ),
    );
  }
}
