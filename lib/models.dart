import 'dart:convert';

class Project {
  String title;
  String description;
  List<String> linkedInterests;
  List<String> linkedSkills;
  DateTime? startDate;
  DateTime? endDate;
  List<String> attachments;

  Project({
    this.title = '',
    this.description = '',
    this.linkedInterests = const [],
    this.linkedSkills = const [],
    this.startDate,
    this.endDate,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'linkedInterests': linkedInterests,
        'linkedSkills': linkedSkills,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'attachments': attachments,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        linkedInterests: List<String>.from(json['linkedInterests'] ?? (json['skill'] != null ? [json['skill']] : [])),
        linkedSkills: List<String>.from(json['linkedSkills'] ?? []),
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        attachments: List<String>.from(json['attachments'] ?? []),
      );
}

class Certification {
  String name;
  String skill;
  String level; // Basic, Intermediate, Advanced
  List<String> attachments;

  Certification({
    this.name = '',
    this.skill = '',
    this.level = 'Basic',
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'skill': skill,
        'level': level,
        'attachments': attachments,
      };

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        name: json['name'] ?? '',
        skill: json['skill'] ?? '',
        level: json['level'] ?? 'Basic',
        attachments: List<String>.from(json['attachments'] ?? []),
      );
}

class Education {
  String level; // Elementary, Middle, High, College
  String school;
  String classOf;
  String yearFrom;
  String yearTo;
  String gradeFrom;
  String gradeTo;
  String gpa;
  bool isOngoing;
  String additionalInfo;
  List<String> attachments;

  Education({
    this.level = '',
    this.school = '',
    this.classOf = '',
    this.yearFrom = '',
    this.yearTo = '',
    this.gradeFrom = '',
    this.gradeTo = '',
    this.gpa = '',
    this.isOngoing = false,
    this.additionalInfo = '',
    this.attachments = const [],
  });

  // Getters for alias fields used in UI
  String get degree => level;
  String get startYear => yearFrom;
  String get endYear => yearTo;

  Map<String, dynamic> toJson() => {
        'level': level,
        'school': school,
        'classOf': classOf,
        'yearFrom': yearFrom,
        'yearTo': yearTo,
        'gradeFrom': gradeFrom,
        'gradeTo': gradeTo,
        'gpa': gpa,
        'isOngoing': isOngoing,
        'additionalInfo': additionalInfo,
        'attachments': attachments,
      };

  factory Education.fromJson(Map<String, dynamic> json) => Education(
        level: json['level'] ?? '',
        school: json['school'] ?? '',
        classOf: json['classOf'] ?? '',
        yearFrom: json['yearFrom'] ?? '',
        yearTo: json['yearTo'] ?? '',
        gradeFrom: json['gradeFrom'] ?? '',
        gradeTo: json['gradeTo'] ?? '',
        gpa: json['gpa'] ?? '',
        isOngoing: json['isOngoing'] ?? false,
        additionalInfo: json['additionalInfo'] ?? '',
        attachments: List<String>.from(json['attachments'] ?? []),
      );
}

class TestScore {
  String testName;
  String score;
  String date;

  TestScore({this.testName = '', this.score = '', this.date = ''});

  Map<String, dynamic> toJson() => {
        'testName': testName,
        'score': score,
        'date': date,
      };

  factory TestScore.fromJson(Map<String, dynamic> json) => TestScore(
        testName: json['testName'] ?? '',
        score: json['score'] ?? '',
        date: json['date'] ?? '',
      );
}
