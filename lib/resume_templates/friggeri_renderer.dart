import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FriggeriRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final normal = fonts['normal']!;
    final bold = fonts['bold']!;
    final italic = fonts['italic']!;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 20),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: data['fullName']?.split(' ').first?.toUpperCase() ?? '', style: pw.TextStyle(font: normal, fontSize: 48, color: PdfColors.grey600)),
                  pw.TextSpan(text: ' ${data['fullName']?.split(' ').skip(1).join(' ')?.toUpperCase() ?? ''}', style: pw.TextStyle(font: bold, fontSize: 48, color: PdfColors.black)),
                ],
              ),
            ),
          ),
          pw.Text(data['tagline']?.toUpperCase() ?? '', style: pw.TextStyle(font: normal, fontSize: 16, color: PdfColors.grey700)),
          pw.SizedBox(height: 40),
          
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left Column (Sidebar-like)
              pw.Container(
                width: format.availableWidth * 0.3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sideSection('CONTACT', bold),
                    pw.Text(data['address'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
                    pw.Text(data['phone'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
                    pw.Text(data['email'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10, color: PdfColors.blue700)),
                    
                    pw.SizedBox(height: 30),
                    _sideSection('SKILLS', bold),
                    ... (data['skills'] as List? ?? []).map((s) => pw.Text(s, style: pw.TextStyle(font: normal, fontSize: 10))),
                  ]
                )
              ),
              
              pw.SizedBox(width: 30),
              
              // Right Column
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _mainSection('EXPERIENCE', bold, PdfColors.cyan),
                    ... (data['experienceList'] as List? ?? []).map((e) => _buildEntry(
                      '${e['startDate']} - ${e['endDate']}',
                      e['organization'] ?? '',
                      e['title'] ?? '',
                      e['description'] ?? '',
                      bold, normal, italic
                    )),
                    
                    pw.SizedBox(height: 20),
                    _mainSection('EDUCATION', bold, PdfColors.purple),
                    ... (data['educationList'] as List? ?? []).map((edu) => _buildEntry(
                      '${edu['yearFrom']} - ${edu['yearTo']}',
                      edu['school'] ?? '',
                      edu['level'] ?? '',
                      '',
                      bold, normal, italic
                    )),
                  ]
                )
              )
            ]
          )
        ],
      ),
    );
  }

  static pw.Widget _sideSection(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey900)),
    );
  }

  static pw.Widget _mainSection(String title, pw.Font font, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Row(
        children: [
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: title.substring(0, 3), style: pw.TextStyle(font: font, fontSize: 20, color: color)),
                pw.TextSpan(text: title.substring(3), style: pw.TextStyle(font: font, fontSize: 20, color: PdfColors.black)),
              ]
            )
          ),
        ]
      ),
    );
  }

  static pw.Widget _buildEntry(String date, String org, String title, String desc, pw.Font bold, pw.Font normal, pw.Font italic) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 80, child: pw.Text(date, style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey600))),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(org, style: pw.TextStyle(font: bold, fontSize: 11)),
                pw.Text(title, style: pw.TextStyle(font: italic, fontSize: 10)),
                if (desc.isNotEmpty) pw.Text(desc, style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey800)),
              ]
            )
          )
        ]
      ),
    );
  }
}
