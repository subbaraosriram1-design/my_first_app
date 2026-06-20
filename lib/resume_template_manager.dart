import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:docx_template/docx_template.dart';
import 'models.dart';

class ResumeTemplateManager {
  static final ResumeTemplateManager instance = ResumeTemplateManager._init();
  ResumeTemplateManager._init();

  String? _customTemplateBase64;
  String? _htmlResume;
  
  Uint8List? _customDocxBytes;
  Map<String, dynamic>? _docxMapping;

  void setCustomTemplate(String base64Image, String html) {
    _customTemplateBase64 = base64Image;
    _htmlResume = html;
    _customDocxBytes = null;
  }

  void setCustomDocx(Uint8List bytes, Map<String, dynamic> mapping) {
    _customDocxBytes = bytes;
    _docxMapping = mapping;
    _customTemplateBase64 = null;
    _htmlResume = null;
  }

  String? get customTemplateBase64 => _customTemplateBase64;
  String? get htmlResume => _htmlResume;
  
  Uint8List? get customDocxBytes => _customDocxBytes;
  Map<String, dynamic>? get docxMapping => _docxMapping;

  bool get hasCustomTemplate => _customTemplateBase64 != null && _htmlResume != null;
  bool get hasCustomDocx => _customDocxBytes != null && _docxMapping != null;

  void clearCustomTemplate() {
    _customTemplateBase64 = null;
    _htmlResume = null;
    _customDocxBytes = null;
    _docxMapping = null;
  }

  Future<Uint8List?> generateFilledDocx(Map<String, dynamic> userData) async {
    if (_customDocxBytes == null || _docxMapping == null) return null;

    try {
      final docx = await DocxTemplate.fromBytes(_customDocxBytes!);
      
      final Content content = Content();
      
      _docxMapping!.forEach((field, placeholder) {
        if (userData.containsKey(field)) {
          final String key = placeholder.toString().replaceAll('[', '').replaceAll(']', '');
          content.add(TextContent(key, userData[field].toString()));
        }
      });

      final result = await docx.generate(content);
      return result != null ? Uint8List.fromList(result) : null;
    } catch (e) {
      debugPrint("Error generating filled docx: $e");
      return null;
    }
  }

  // Support for resume_application_screen.dart
  static Map<String, dynamic> loadTemplateFromJson(String jsonStr) {
    return jsonDecode(jsonStr);
  }

  static Map<String, dynamic> generateResumeContent({required ResumeData userData, required Map<String, dynamic> template}) {
    return {
      "header": {
        "name": userData.fullName,
        "tagline": userData.tagline,
        "contact": "${userData.email} | ${userData.contact}"
      },
      "sections": (template['sections'] as List).map((s) => {
        "title": s['title'],
        "type": s['type'],
        "data": "Sample data for ${s['title']}"
      }).toList()
    };
  }

  static Future<Uint8List> generatePdf(Map<String, dynamic> content) async {
    // Mock PDF generation for application screen
    return Uint8List(0);
  }
}
