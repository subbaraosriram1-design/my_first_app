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
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        linkedInterests: (json['linkedInterests'] is List) 
            ? List<String>.from((json['linkedInterests'] as List).map((e) => e.toString()))
            : (json['skill'] != null ? [json['skill'].toString()] : []),
        linkedSkills: (json['linkedSkills'] is List)
            ? List<String>.from((json['linkedSkills'] as List).map((e) => e.toString()))
            : [],
        startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
        endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
        attachments: (json['attachments'] is List)
            ? List<String>.from((json['attachments'] as List).map((e) => e.toString()))
            : [],
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
        name: json['name']?.toString() ?? '',
        skill: json['skill']?.toString() ?? '',
        level: json['level']?.toString() ?? 'Basic',
        attachments: (json['attachments'] is List)
            ? List<String>.from((json['attachments'] as List).map((e) => e.toString()))
            : [],
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
        level: json['level']?.toString() ?? '',
        school: json['school']?.toString() ?? '',
        classOf: json['classOf']?.toString() ?? '',
        yearFrom: json['yearFrom']?.toString() ?? '',
        yearTo: json['yearTo']?.toString() ?? '',
        gradeFrom: json['gradeFrom']?.toString() ?? '',
        gradeTo: json['gradeTo']?.toString() ?? '',
        gpa: json['gpa']?.toString() ?? '',
        isOngoing: json['isOngoing'] ?? false,
        additionalInfo: json['additionalInfo']?.toString() ?? '',
        attachments: (json['attachments'] is List)
            ? List<String>.from((json['attachments'] as List).map((e) => e.toString()))
            : [],
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
        testName: json['testName']?.toString() ?? '',
        score: json['score']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
      );
}

class WorkExperience {
  String title;
  String organization;
  String location;
  String startDate;
  String endDate;
  bool isCurrent;
  String description;
  String type; // Job, Internship, Volunteer

  WorkExperience({
    this.title = '',
    this.organization = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.isCurrent = false,
    this.description = '',
    this.type = 'Job',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'organization': organization,
        'location': location,
        'startDate': startDate,
        'endDate': endDate,
        'isCurrent': isCurrent,
        'description': description,
        'type': type,
      };

  factory WorkExperience.fromJson(Map<String, dynamic> json) => WorkExperience(
        title: json['title']?.toString() ?? '',
        organization: json['organization']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? '',
        isCurrent: json['isCurrent'] ?? false,
        description: json['description']?.toString() ?? '',
        type: json['type']?.toString() ?? 'Job',
      );
}

class Language {
  String name;
  String proficiency; // Basic, Conversational, Fluent, Native

  Language({this.name = '', this.proficiency = 'Basic'});

  Map<String, dynamic> toJson() => {'name': name, 'proficiency': proficiency};
  factory Language.fromJson(Map<String, dynamic> json) => Language(
        name: json['name']?.toString() ?? '',
        proficiency: json['proficiency']?.toString() ?? 'Basic',
      );
}

class ResumeData {
  String fullName;
  String email;
  String tagline;
  String contact;
  // ... other fields can be added as needed by resume_application_screen

  ResumeData({
    this.fullName = '',
    this.email = '',
    this.tagline = '',
    this.contact = '',
  });

  factory ResumeData.fromFirestore(Map<String, dynamic> json) => ResumeData(
        fullName: json['fullName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        tagline: json['tagline']?.toString() ?? '',
        contact: json['phone']?.toString() ?? '',
      );
}

