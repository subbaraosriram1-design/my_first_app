import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AwesomeCVRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final normal = fonts['normal']!;
    final bold = fonts['bold']!;
    final italic = fonts['italic']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: data['fullName']?.split(' ').first ?? '', style: pw.TextStyle(font: normal, fontSize: 32, color: PdfColors.grey700)),
                      pw.TextSpan(text: ' ${data['fullName']?.split(' ').skip(1).join(' ') ?? ''}', style: pw.TextStyle(font: bold, fontSize: 32, color: PdfColors.black)),
                    ],
                  ),
                ),
                pw.Text(data['tagline']?.toUpperCase() ?? '', style: pw.TextStyle(font: normal, fontSize: 12, color: PdfColors.red700, letterSpacing: 2)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(data['email'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9)),
                    pw.Text('  ·  ', style: pw.TextStyle(font: bold, fontSize: 9)),
                    pw.Text(data['phone'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9)),
                    pw.Text('  ·  ', style: pw.TextStyle(font: bold, fontSize: 9)),
                    pw.Text(data['address'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9)),
                  ]
                ),
                pw.SizedBox(height: 30),
              ],
            ),
          ),
          
          _sectionTitle('SUMMARY', bold),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, bottom: 20),
            child: pw.Text(data['summary'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10, lineSpacing: 1.3)),
          ),
          
          _sectionTitle('EXPERIENCE', bold),
          ... (data['experienceList'] as List? ?? []).map((e) => _buildItem(
            e['organization'] ?? '',
            e['location'] ?? '',
            e['title'] ?? '',
            '${e['startDate']} - ${e['endDate']}',
            e['description'] ?? '',
            bold, normal, italic
          )),
          
          _sectionTitle('EDUCATION', bold),
          ... (data['educationList'] as List? ?? []).map((edu) => _buildItem(
            edu['school'] ?? '',
            '',
            edu['level'] ?? '',
            '${edu['yearFrom']} - ${edu['yearTo']}',
            '',
            bold, normal, italic
          )),
          
          _sectionTitle('SKILLS', bold),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10),
            child: pw.Text((data['skills'] as List?)?.join('  ·  ') ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15, top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 16, color: PdfColors.black)),
          pw.Container(height: 2, color: PdfColors.grey800, width: 30),
          pw.Container(height: 0.5, color: PdfColors.grey300),
        ],
      ),
    );
  }

  static pw.Widget _buildItem(String title, String subtitle, String role, String date, String desc, pw.Font bold, pw.Font normal, pw.Font italic) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10, bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 11)),
              pw.Text(date, style: pw.TextStyle(font: italic, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(role, style: pw.TextStyle(font: normal, fontSize: 10, color: PdfColors.red700)),
              pw.Text(subtitle, style: pw.TextStyle(font: italic, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          if (desc.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Bullet(text: desc, style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey800)),
          ]
        ],
      ),
    );
  }
}
