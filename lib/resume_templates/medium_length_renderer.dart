import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class MediumLengthRenderer {
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
                pw.Text(data['fullName'] ?? '', style: pw.TextStyle(font: bold, fontSize: 26)),
                pw.Text('${data['address']} | ${data['phone']} | ${data['email']}', style: pw.TextStyle(font: normal, fontSize: 10)),
                pw.SizedBox(height: 20),
              ],
            ),
          ),
          
          _section('Professional Summary', bold),
          pw.Text(data['summary'] ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
          
          pw.SizedBox(height: 20),
          _section('Education', bold),
          ... (data['educationList'] as List? ?? []).map((edu) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(edu['school'] ?? '', style: pw.TextStyle(font: bold, fontSize: 11)),
                  pw.Text(edu['level'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
                ]
              ),
              pw.Text('${edu['yearFrom']} - ${edu['yearTo']}', style: pw.TextStyle(font: normal, fontSize: 10)),
            ]
          )),
          
          pw.SizedBox(height: 20),
          _section('Experience', bold),
          ... (data['experienceList'] as List? ?? []).map((e) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 15),
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
                pw.SizedBox(height: 5),
                pw.Text(e['description'] ?? '', style: pw.TextStyle(font: normal, fontSize: 10)),
              ]
            ),
          )),
          
          pw.SizedBox(height: 20),
          _section('Skills', bold),
          pw.Text((data['skills'] as List?)?.join(', ') ?? '', style: pw.TextStyle(font: normal, fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _section(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.blue900)),
          pw.Divider(thickness: 1.5, color: PdfColors.blue900),
        ],
      ),
    );
  }
}
