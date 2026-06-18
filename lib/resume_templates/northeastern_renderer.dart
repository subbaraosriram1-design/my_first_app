import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class NortheasternRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final normal = fonts['serifNormal']!;
    final bold = fonts['serifBold']!;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          // Header
          pw.Text(data['fullName']?.toUpperCase() ?? '', style: pw.TextStyle(font: bold, fontSize: 18)),
          pw.Text(data['address'] ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
          pw.Text(data['email'] ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
          pw.Text(data['phone'] ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
          pw.SizedBox(height: 30),
          
          _sectionTitle('Education', bold),
          ... (data['educationList'] as List? ?? []).map((edu) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 100, child: pw.Text('${edu['yearFrom']} - ${edu['yearTo']}', style: pw.TextStyle(font: normal, fontSize: 11))),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu['school'] ?? '', style: pw.TextStyle(font: bold, fontSize: 11)),
                      pw.Text(edu['level'] ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
                    ]
                  )
                )
              ]
            )
          )),
          
          _sectionTitle('Professional Appointments', bold),
          ... (data['experienceList'] as List? ?? []).map((e) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 100, child: pw.Text('${e['startDate']} - ${e['endDate']}', style: pw.TextStyle(font: normal, fontSize: 11))),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${e['title']}, ${e['organization']}', style: pw.TextStyle(font: bold, fontSize: 11)),
                      pw.Text(e['description'] ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
                    ]
                  )
                )
              ]
            )
          )),
          
          _sectionTitle('Publications and Research', bold),
          ... (data['projects'] as List? ?? []).map((p) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Bullet(text: p['title'] ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
          )),

          _sectionTitle('Skills and Expertise', bold),
          pw.Text((data['skills'] as List?)?.join(', ') ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 25, bottom: 10),
      child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 14, decoration: pw.TextDecoration.underline)),
    );
  }
}
