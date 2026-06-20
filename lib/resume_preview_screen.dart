import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Import template renderers (to be created)
import 'resume_templates/altacv_renderer.dart';
import 'resume_templates/deedy_renderer.dart';
import 'resume_templates/awesome_cv_renderer.dart';
import 'resume_templates/moderncv_renderer.dart';
import 'resume_templates/twenty_seconds_renderer.dart';
import 'resume_templates/medium_length_renderer.dart';
import 'resume_templates/friggeri_renderer.dart';
import 'resume_templates/rendercv_renderer.dart';
import 'resume_templates/academic_cv_renderer.dart';
import 'resume_templates/elegant_renderer.dart';
import 'resume_templates/harshibar_renderer.dart';
import 'resume_templates/northeastern_renderer.dart';
import 'resume_templates/custom_template_renderer.dart';
import 'resume_template_manager.dart';
import 'package:share_plus/share_plus.dart';

class ResumePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> resumeData;
  final String templateName;

  const ResumePreviewScreen({
    super.key,
    required this.resumeData,
    required this.templateName,
  });

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    
    // Standard fonts
    final robotoNormal = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();
    final robotoItalic = await PdfGoogleFonts.robotoItalic();
    
    final notoSerifNormal = await PdfGoogleFonts.notoSerifRegular();
    final notoSerifBold = await PdfGoogleFonts.notoSerifBold();
    final notoSerifItalic = await PdfGoogleFonts.notoSerifItalic();

    final loraNormal = await PdfGoogleFonts.loraRegular();
    final loraBold = await PdfGoogleFonts.loraBold();
    final loraItalic = await PdfGoogleFonts.loraItalic();

    final fonts = {
      'normal': robotoNormal,
      'bold': robotoBold,
      'italic': robotoItalic,
      'serifNormal': notoSerifNormal,
      'serifBold': notoSerifBold,
      'serifItalic': notoSerifItalic,
      'loraNormal': loraNormal,
      'loraBold': loraBold,
      'loraItalic': loraItalic,
    };

    // Map template names to their respective renderers
    switch (widget.templateName) {
      case 'AltaCV':
        await AltaCVRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Deedy Resume':
        await DeedyRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Awesome-CV':
        await AwesomeCVRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'ModernCV':
        await ModernCVRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Twenty Seconds CV':
        await TwentySecondsRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Medium Length Professional CV':
        await MediumLengthRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Friggeri CV':
        await FriggeriRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'RenderCV Classic Theme':
        await RenderCVRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Academic CV':
        await AcademicCVRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Elegant Resume':
        await ElegantRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Harshibar’s Resume':
        await HarshibarRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Northeastern University COS Faculty CV':
        await NortheasternRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'Custom':
        await CustomTemplateRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      case 'CustomDocx':
        // CustomDocx is handled separately in the UI
        await AltaCVRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
      default:
        await AltaCVRenderer.render(pdf, format, widget.resumeData, fonts);
        break;
    }

    return pdf.save();
  }

  Future<void> _saveAsPdf() async {
    if (widget.templateName == 'CustomDocx') {
      final docxBytes = await ResumeTemplateManager.instance.generateFilledDocx(widget.resumeData);
      if (docxBytes == null) return;
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/resume_custom.docx');
      await file.writeAsBytes(docxBytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DOCX Saved to: ${file.path}')),
        );
      }
      return;
    }

    final pdfBytes = await _generatePdf(PdfPageFormat.a4);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/resume_${widget.templateName.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(pdfBytes);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to: ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = widget.templateName == 'Custom' ? 'Custom Layout' : widget.templateName;
    
    if (widget.templateName == 'CustomDocx') {
      return Scaffold(
        appBar: AppBar(
          title: Text('Preview: Custom DOCX', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _saveAsPdf,
              tooltip: 'Download DOCX',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                final docxBytes = await ResumeTemplateManager.instance.generateFilledDocx(widget.resumeData);
                if (docxBytes != null) {
                  final directory = await getTemporaryDirectory();
                  final file = File('${directory.path}/resume.docx');
                  await file.writeAsBytes(docxBytes);
                  await Share.shareXFiles([XFile(file.path)], text: 'My Resume');
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description, size: 80, color: Color(0xFF5B3FD8)),
              const SizedBox(height: 24),
              Text(
                'Your custom DOCX template is ready!',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'PDF preview is not available for custom DOCX files.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveAsPdf,
                icon: const Icon(Icons.download),
                label: const Text('Download Filled DOCX'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3FD8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: $titleText', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _saveAsPdf,
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
               final pdfBytes = await _generatePdf(PdfPageFormat.a4);
               await Printing.sharePdf(bytes: pdfBytes, filename: 'resume.pdf');
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.a4,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onPrinted: (context) => debugPrint('Printed'),
        onShared: (context) => debugPrint('Shared'),
      ),
    );
  }
}
