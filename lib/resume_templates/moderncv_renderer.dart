import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ModernCVRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final normal = fonts['normal']!;
    final bold = fonts['bold']!;
    final italic = fonts['italic']!;
    final accentColor = PdfColor.fromHex('#2196F3');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(text: data['fullName']?.split(' ').first ?? '', style: pw.TextStyle(font: normal, fontSize: 32, color: PdfColors.grey600)),
                          pw.TextSpan(text: ' ${data['fullName']?.split(' ').skip(1).join(' ') ?? ''}', style: pw.TextStyle(font: bold, fontSize: 32, color: accentColor)),
                        ],
                      ),
                    ),
                    pw.Text(data['tagline'] ?? '', style: pw.TextStyle(font: italic, fontSize: 14, color: PdfColors.grey700)),
                  ]
                )
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _headerContact(data['address'] ?? '', pw.IconData(0xe0c8), normal),
                  _headerContact(data['phone'] ?? '', pw.IconData(0xe0cd), normal),
                  _headerContact(data['email'] ?? '', pw.IconData(0xe0e1), normal),
                ]
              )
            ]
          ),
          pw.SizedBox(height: 40),
          
          _sectionTitle('Experience', bold, accentColor),
          ... (data['experienceList'] as List? ?? []).map((e) => _buildEntry(
            '${e['startDate']} - ${e['endDate']}',
            e['title'] ?? '',
            e['organization'] ?? '',
            e['description'] ?? '',
            bold, normal, italic, accentColor
          )),
          
          _sectionTitle('Education', bold, accentColor),
          ... (data['educationList'] as List? ?? []).map((edu) => _buildEntry(
            '${edu['yearFrom']} - ${edu['yearTo']}',
            edu['level'] ?? '',
            edu['school'] ?? '',
            '',
            bold, normal, italic, accentColor
          )),
          
          _sectionTitle('Skills', bold, accentColor),
          _buildEntry('', 'Technical Skills', (data['skills'] as List?)?.join(', ') ?? '', '', bold, normal, italic, accentColor),
        ],
      ),
    );
  }

  static pw.Widget _headerContact(String text, pw.IconData icon, pw.Font font) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9)),
        pw.SizedBox(width: 5),
        pw.Icon(icon, size: 10, color: PdfColors.grey700),
      ]
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font font, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Row(
        children: [
          pw.Container(
            width: 80,
            alignment: pw.Alignment.centerRight,
            child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 14, color: color)),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(child: pw.Container(height: 1, color: color.shade(0.2))),
        ]
      ),
    );
  }

  static pw.Widget _buildEntry(String date, String title, String subtitle, String desc, pw.Font bold, pw.Font normal, pw.Font italic, PdfColor accent) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 80,
            alignment: pw.Alignment.centerRight,
            child: pw.Text(date, style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey700)),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 11)),
                pw.Text(subtitle, style: pw.TextStyle(font: italic, fontSize: 10, color: PdfColors.grey800)),
                if (desc.isNotEmpty) pw.Text(desc, style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey700)),
              ]
            )
          )
        ]
      ),
    );
  }
}
