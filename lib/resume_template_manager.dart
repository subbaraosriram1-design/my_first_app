import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models.dart';

/// Aggregates all user data required for a resume.
/// This structure makes it easy to pass user data to any template or generator.
class ResumeData {
  final String fullName;
  final String email;
  final String phone;
  final String tagline;
  final String summary;
  final List<Education> education;
  final List<Project> projects;
  final List<Certification> certifications;
  final List<TestScore> testScores;
  final List<String> skills;
  final List<String> hobbies;

  ResumeData({
    required this.fullName,
    required this.email,
    required this.phone,
    this.tagline = '',
    this.summary = '',
    this.education = const [],
    this.projects = const [],
    this.certifications = const [],
    this.testScores = const [],
    this.skills = const [],
    this.hobbies = const [],
  });

  /// Factory to create ResumeData from the Firestore map format used in CareerProfileScreen.
  factory ResumeData.fromFirestore(Map<String, dynamic> data) {
    return ResumeData(
      fullName: data['fullName'] ?? 'Name',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      tagline: data['tagline'] ?? '',
      summary: data['summary'] ?? '',
      education: (data['educationList'] as List? ?? [])
          .map((e) => Education.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      projects: (data['projects'] as List? ?? data['experience'] as List? ?? [])
          .map((e) => Project.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      certifications: (data['certifications'] as List? ?? [])
          .map((e) => Certification.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      testScores: (data['testScores'] as List? ?? [])
          .map((e) => TestScore.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      skills: List<String>.from(data['skills'] ?? []),
      hobbies: List<String>.from(data['hobbies'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'tagline': tagline,
    'summary': summary,
    'education': education.map((e) => e.toJson()).toList(),
    'projects': projects.map((e) => e.toJson()).toList(),
    'certifications': certifications.map((e) => e.toJson()).toList(),
    'testScores': testScores.map((e) => e.toJson()).toList(),
    'skills': skills,
    'hobbies': hobbies,
  };
}

/// Represents a section in the resume template (e.g., "Experience", "Skills").
class TemplateSection {
  final String title;
  final String type; // e.g., 'list', 'text', 'grid'
  final bool isVisible;

  TemplateSection({
    required this.title,
    required this.type,
    this.isVisible = true,
  });

  factory TemplateSection.fromJson(Map<String, dynamic> json) {
    return TemplateSection(
      title: json['title'] ?? '',
      type: json['type'] ?? 'text',
      isVisible: json['isVisible'] ?? true,
    );
  }
}

/// Represents the "temple file" or structure definition for a resume.
class ResumeTemplate {
  final String name;
  final String description;
  final List<TemplateSection> sections;
  final Map<String, dynamic> style; // For future UI/PDF styling (font, colors)

  ResumeTemplate({
    required this.name,
    this.description = '',
    required this.sections,
    this.style = const {},
  });

  factory ResumeTemplate.fromJson(Map<String, dynamic> json) {
    return ResumeTemplate(
      name: json['name'] ?? 'Default Template',
      description: json['description'] ?? '',
      sections: (json['sections'] as List? ?? [])
          .map((s) => TemplateSection.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      style: json['style'] ?? {},
    );
  }

  /// Returns a basic default template if the user hasn't provided one.
  static ResumeTemplate defaultTemplate() {
    return ResumeTemplate(
      name: 'Standard Professional',
      sections: [
        TemplateSection(title: 'Summary', type: 'text'),
        TemplateSection(title: 'Education', type: 'list'),
        TemplateSection(title: 'Experience', type: 'list'),
        TemplateSection(title: 'Skills', type: 'grid'),
        TemplateSection(title: 'Certifications', type: 'list'),
      ],
    );
  }
}

/// A manager class to handle resume generation logic.
/// This can be used anywhere in the app to create a structured resume.
class ResumeTemplateManager {
  
  /// Formats user data into a structured output based on the provided template.
  /// This output can then be used to render a PDF or a custom UI.
  static Map<String, dynamic> generateResumeContent({
    required ResumeData userData,
    required ResumeTemplate template,
  }) {
    final Map<String, dynamic> content = {
      'header': {
        'name': userData.fullName,
        'contact': '${userData.email} | ${userData.phone}',
        'tagline': userData.tagline,
      },
      'sections': [],
    };

    for (var section in template.sections) {
      if (!section.isVisible) continue;

      dynamic sectionData;
      
      // Mapping logic based on section type or title
      switch (section.title.toLowerCase()) {
        case 'summary':
          sectionData = userData.summary;
          break;
        case 'education':
          sectionData = userData.education.map((e) => {
            'institution': e.school,
            'degree': e.level,
            'period': '${e.yearFrom} - ${e.yearTo}',
            'gpa': e.gpa,
          }).toList();
          break;
        case 'experience':
        case 'projects':
          sectionData = userData.projects.map((p) => {
            'title': p.title,
            'description': p.description,
            'period': p.startDate != null ? '${p.startDate?.year} - ${p.endDate?.year ?? 'Present'}' : '',
          }).toList();
          break;
        case 'skills':
          sectionData = userData.skills;
          break;
        case 'certifications':
          sectionData = userData.certifications.map((c) => {
            'name': c.name,
            'authority': c.skill,
            'level': c.level,
          }).toList();
          break;
        default:
          sectionData = null;
      }

      if (sectionData != null) {
        content['sections'].add({
          'title': section.title,
          'type': section.type,
          'data': sectionData,
        });
      }
    }

    return content;
  }

  /// Helper to load a template from a JSON string.
  static ResumeTemplate loadTemplateFromJson(String jsonString) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return ResumeTemplate.fromJson(decoded);
    } catch (e) {
      print('Error loading template: $e');
      return ResumeTemplate.defaultTemplate();
    }
  }

  /// Future Enhancement: PDF Generation
  static Future<Uint8List> generatePdf(Map<String, dynamic> content) async {
    final pdf = pw.Document();
    final header = content['header'];
    final sections = content['sections'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(header['name'], style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(header['tagline'], style: const pw.TextStyle(fontSize: 14)),
                pw.Text(header['contact'], style: const pw.TextStyle(fontSize: 12, color: PdfColors.green)),
                pw.Padding(padding: const pw.EdgeInsets.only(bottom: 20)),
              ],
            ),
          ),
          ...sections.map((section) {
            final data = section['data'];
            final type = section['type'];
            
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(padding: const pw.EdgeInsets.only(top: 10)),
                pw.Text(section['title'].toString().toUpperCase(), 
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Divider(),
                if (type == 'text')
                  pw.Text(data.toString(), style: const pw.TextStyle(fontSize: 11))
                else if (type == 'grid' && data is List)
                  pw.Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: data.map((item) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Text(item.toString(), style: const pw.TextStyle(fontSize: 10, color: PdfColors.green900)),
                    )).toList(),
                  )
                else if (type == 'list' && data is List)
                  ...data.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Bullet(),
                        pw.SizedBox(width: 5),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (item is Map) ...[
                                pw.Text(item.values.first.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                                if (item.length > 1) pw.Text(item.values.elementAt(1).toString(), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                              ] else
                                pw.Text(item.toString(), style: const pw.TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                pw.SizedBox(height: 10),
              ],
            );
          }),
        ],
      ),
    );

    return pdf.save();
  }
}
