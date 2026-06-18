import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TwentySecondsRenderer {
  static Future<void> render(pw.Document pdf, PdfPageFormat format, Map<String, dynamic> data, Map<String, pw.Font> fonts) async {
    final normal = fonts['normal']!;
    final bold = fonts['bold']!;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => [
          pw.FullPage(
            ignoreMargins: true,
            child: pw.Row(
              children: [
                // SIDEBAR
                pw.Container(
                  width: format.width * 0.35,
                  color: PdfColors.blueGrey800,
                  padding: const pw.EdgeInsets.all(30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(data['fullName']?.toUpperCase() ?? '', style: pw.TextStyle(font: bold, fontSize: 28, color: PdfColors.white)),
                      pw.SizedBox(height: 5),
                      pw.Text(data['tagline'] ?? '', style: pw.TextStyle(font: normal, fontSize: 12, color: PdfColors.grey300)),
                      pw.SizedBox(height: 40),
                      
                      _sidebarTitle('CONTACT', bold),
                      _sidebarInfo(data['phone'] ?? '', pw.IconData(0xe0cd), normal),
                      _sidebarInfo(data['email'] ?? '', pw.IconData(0xe0e1), normal),
                      _sidebarInfo(data['address'] ?? '', pw.IconData(0xe0c8), normal),
                      
                      pw.SizedBox(height: 30),
                      _sidebarTitle('SKILLS', bold),
                      ... (data['skills'] as List? ?? []).map((s) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(s, style: pw.TextStyle(color: PdfColors.white, font: normal, fontSize: 10)),
                            pw.SizedBox(height: 4),
                            pw.Container(height: 3, width: double.infinity, color: PdfColors.blueGrey900, child: pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Container(width: 60, color: PdfColors.cyan))),
                          ]
                        )
                      )),
                    ],
                  ),
                ),
                
                // MAIN CONTENT
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(40),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('WORK EXPERIENCE', bold),
                        ... (data['experienceList'] as List? ?? []).map((e) => _buildTimelineItem(
                          '${e['startDate']} - ${e['endDate']}',
                          e['title'] ?? '',
                          e['organization'] ?? '',
                          e['description'] ?? '',
                          bold, normal
                        )),
                        
                        pw.SizedBox(height: 30),
                        _sectionHeader('EDUCATION', bold),
                        ... (data['educationList'] as List? ?? []).map((edu) => _buildTimelineItem(
                          '${edu['yearFrom']} - ${edu['yearTo']}',
                          edu['level'] ?? '',
                          edu['school'] ?? '',
                          '',
                          bold, normal
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sidebarTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.cyan, letterSpacing: 1.5)),
    );
  }

  static pw.Widget _sidebarInfo(String text, pw.IconData icon, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.Icon(icon, size: 12, color: PdfColors.white),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.white))),
        ],
      ),
    );
  }

  static pw.Widget _sectionHeader(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 18, color: PdfColors.blueGrey800)),
    );
  }

  static pw.Widget _buildTimelineItem(String date, String title, String subtitle, String desc, pw.Font bold, pw.Font normal) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 80,
            child: pw.Text(date, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.cyan700)),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 11)),
                pw.Text(subtitle, style: pw.TextStyle(font: normal, fontSize: 10, color: PdfColors.grey700)),
                if (desc.isNotEmpty) pw.Text(desc, style: pw.TextStyle(font: normal, fontSize: 9, color: PdfColors.grey600)),
              ]
            )
          )
        ],
      ),
    );
  }
}
