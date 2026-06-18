import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DeedyRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final normal = fonts['normal']!;
    final bold = fonts['bold']!;
    final italic = fonts['italic']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(data['fullName']?.toUpperCase() ?? '', style: pw.TextStyle(font: normal, fontSize: 40, fontWeight: pw.FontWeight.normal, color: PdfColors.grey900)),
              pw.Row(
                children: [
                   pw.Text(data['email'] ?? '', style: pw.TextStyle(font: normal, fontSize: 11, color: PdfColors.blue700)),
                   pw.Text(' | ', style: pw.TextStyle(font: normal, fontSize: 11)),
                   pw.Text(data['phone'] ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
                   if (data['github'] != null) ...[
                     pw.Text(' | ', style: pw.TextStyle(font: normal, fontSize: 11)),
                     pw.Text('GitHub', style: pw.TextStyle(font: normal, fontSize: 11, color: PdfColors.blue700)),
                   ]
                ]
              ),
              pw.SizedBox(height: 20),
            ],
          ),
          
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN (Narrow)
              pw.Container(
                width: format.availableWidth * 0.3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('EDUCATION', bold),
                    ... (data['educationList'] as List? ?? []).map((edu) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(edu['school'] ?? '', style: pw.TextStyle(font: bold, fontSize: 10)),
                          pw.Text(edu['level'] ?? '', style: pw.TextStyle(font: normal, fontSize: 9)),
                          pw.Text('${edu['yearFrom']} - ${edu['yearTo']}', style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey700)),
                        ]
                      )
                    )),
                    
                    pw.SizedBox(height: 20),
                    _sectionTitle('SKILLS', bold),
                    ... (data['skills'] as List? ?? []).map((s) => pw.Text('• $s', style: pw.TextStyle(font: normal, fontSize: 10))),
                    
                    pw.SizedBox(height: 20),
                    _sectionTitle('LINKS', bold),
                    if (data['linkedin'] != null) pw.Text('LinkedIn', style: pw.TextStyle(font: normal, fontSize: 10, color: PdfColors.blue700)),
                    if (data['github'] != null) pw.Text('GitHub', style: pw.TextStyle(font: normal, fontSize: 10, color: PdfColors.blue700)),
                  ],
                ),
              ),
              
              pw.SizedBox(width: 20),
              
              // RIGHT COLUMN (Wide)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('EXPERIENCE', bold),
                    ... (data['experienceList'] as List? ?? []).map((e) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(e['organization']?.toUpperCase() ?? '', style: pw.TextStyle(font: bold, fontSize: 12)),
                              pw.Text('${e['startDate']} - ${e['endDate']}', style: pw.TextStyle(font: normal, fontSize: 10, color: PdfColors.grey700)),
                            ]
                          ),
                          pw.Text(e['title'] ?? '', style: pw.TextStyle(font: italic, fontSize: 11, color: PdfColors.grey800)),
                          pw.SizedBox(height: 4),
                          pw.Text(e['description'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
                        ]
                      )
                    )),
                    
                    pw.SizedBox(height: 20),
                    _sectionTitle('PROJECTS', bold),
                    ... (data['projects'] as List? ?? []).map((p) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(p['title']?.toUpperCase() ?? '', style: pw.TextStyle(font: bold, fontSize: 11)),
                          pw.Text(p['description'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
                        ]
                      )
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8, top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey800)),
          pw.Container(height: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 5),
        ],
      ),
    );
  }
}
