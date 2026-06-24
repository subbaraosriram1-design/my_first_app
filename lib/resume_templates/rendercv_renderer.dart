import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class RenderCVRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final serifNormal = fonts['serifNormal']!;
    final serifBold = fonts['serifBold']!;
    final serifItalic = fonts['serifItalic']!;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(data['fullName'] ?? '', style: pw.TextStyle(font: serifBold, fontSize: 24)),
                pw.SizedBox(height: 5),
                pw.Text(
                  '${data['address']} | ${data['phone']} | ${data['email']}',
                  style: pw.TextStyle(font: serifNormal, fontSize: 10)
                ),
                if (data['linkedin'] != null || data['github'] != null)
                  pw.Text(
                    '${data['linkedin'] ?? ''} ${data['github'] != null ? "| ${data['github']}" : ''}',
                    style: pw.TextStyle(font: serifNormal, fontSize: 10, color: PdfColors.blue800)
                  ),
                pw.SizedBox(height: 10),
              ],
            ),
          ),
          
          _sectionTitle('Professional Summary', serifBold),
          pw.Paragraph(text: data['summary'] ?? '', style: pw.TextStyle(font: serifNormal, fontSize: 10)),
          
          _sectionTitle('Experience', serifBold),
          ... (data['experienceList'] as List? ?? []).map((e) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e['organization'] ?? '', style: pw.TextStyle(font: serifBold, fontSize: 11)),
                  pw.Text('${e['startDate']} - ${e['endDate']}', style: pw.TextStyle(font: serifNormal, fontSize: 10)),
                ]
              ),
              pw.Text(e['title'] ?? '', style: pw.TextStyle(font: serifItalic, fontSize: 10)),
              pw.Bullet(text: e['description'] ?? '', style: pw.TextStyle(font: serifNormal, fontSize: 10)),
              pw.SizedBox(height: 5),
            ]
          )),
          
          _sectionTitle('Education', serifBold),
          ... (data['educationList'] as List? ?? []).map((edu) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(edu['school'] ?? '', style: pw.TextStyle(font: serifBold, fontSize: 11)),
                  pw.Text(edu['level'] ?? '', style: pw.TextStyle(font: serifNormal, fontSize: 10)),
                ]
              ),
              pw.Text('${edu['yearFrom']} - ${edu['yearTo']}', style: pw.TextStyle(font: serifNormal, fontSize: 10)),
            ]
          )),
          
          _sectionTitle('Skills', serifBold),
          pw.Text((data['skills'] as List?)?.join(', ') ?? '', style: pw.TextStyle(font: serifNormal, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 15, bottom: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title.toUpperCase(), style: pw.TextStyle(font: font, fontSize: 12, letterSpacing: 1)),
          pw.Divider(thickness: 1, color: PdfColors.black),
        ],
      ),
    );
  }
}
