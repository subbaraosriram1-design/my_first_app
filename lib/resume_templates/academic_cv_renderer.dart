import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AcademicCVRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final normal = fonts['serifNormal']!;
    final bold = fonts['serifBold']!;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          // Header
          pw.Center(child: pw.Text(data['fullName'] ?? '', style: pw.TextStyle(font: bold, fontSize: 24))),
          pw.Center(child: pw.Text(data['address'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10))),
          pw.Center(child: pw.Text('${data['email']} | ${data['phone']}', style: pw.TextStyle(font: normal, fontSize: 10))),
          pw.SizedBox(height: 30),
          
          _sectionTitle('Education', bold),
          ... (data['educationList'] as List? ?? []).map((edu) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu['school'] ?? '', style: pw.TextStyle(font: bold, fontSize: 11)),
                      pw.Text(edu['level'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
                    ]
                  )
                ),
                pw.Text('${edu['yearFrom']} - ${edu['yearTo']}', style: pw.TextStyle(font: normal, fontSize: 10)),
              ]
            )
          )),
          
          _sectionTitle('Research Interests', bold),
          pw.Text((data['skills'] as List?)?.join(', ') ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
          
          _sectionTitle('Publications', bold),
          ... (data['projects'] as List? ?? []).map((p) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 40, child: pw.Text('2023', style: pw.TextStyle(font: normal, fontSize: 10))),
                pw.Expanded(child: pw.Text(p['title'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10))),
              ]
            )
          )),

          _sectionTitle('Awards and Honors', bold),
          ... (data['achievements'] as List? ?? []).map((a) => pw.Bullet(text: a.toString(), style: pw.TextStyle(font: normal, fontSize: 10))),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title.toUpperCase(), style: pw.TextStyle(font: font, fontSize: 12)),
          pw.Divider(thickness: 0.5),
        ],
      ),
    );
  }
}
