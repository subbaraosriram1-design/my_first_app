import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'firebase_service.dart';
import 'models.dart';

class LoginPage extends StatefulWidget {
  final int? initialStep;
  final bool isEditMode;
  const LoginPage({super.key, this.initialStep, this.isEditMode = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _actualPassword = '';
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isProcessing = false;

  // Sign Up Multi-step state
  int _signUpStep = 0;
  final int _totalSignUpSteps = 11;

  // Step 2: Personal Info
  String? _profileImageBase64;
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _summaryController = TextEditingController();
  final _dobController = TextEditingController();
  String? _gender;

  // Step 3: Academic Profile
  bool? _isFirstGen;
  final _weightedGpaController = TextEditingController();
  String? _satScoreRange;
  String? _actScoreRange;

  // Step 4: Education
  final List<String> _educationLevels = ['Elementary', 'Middle', 'High', 'College'];
  int _selectedEduLevelIndex = 2; // Default to High
  int? _ongoingLevelIndex; // Index of the level that is marked as ongoing

  final _schoolController = TextEditingController();
  final _classOfController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();
  final _gradeFromController = TextEditingController();
  final _gradeToController = TextEditingController();
  final _gpaController = TextEditingController();
  bool _isEduOngoing = false;
  List<String> _eduAttachments = [];

  final List<Education> _educationList = [];

  final List<Project> _projects = [Project()];

  // Step 6: Student Interests
  final _unweightedGpaController = TextEditingController();
  final List<String> _selectedCareerInterests = [];
  final _interestSearchController = TextEditingController();

  // Step 7: Skills & Certs
  final _skillController = TextEditingController();
  final _studentInterestController = TextEditingController();
  final List<String> _skills = [];
  final List<String> _studentInterests = [];
  final _certNameController = TextEditingController();
  String? _selectedSkillForCert;
  final List<Certification> _certifications = [];
  final List<String> _certAttachments = [];

  // Step 8: Goals
  final List<String> _extracurricularMotivations = [];
  String? _targetAchievementLevel;
  bool? _interestedInLeadership;
  bool? _interestedInResearch;

  // Step 9: Activity Preferences (New)
  String? _opportunitySelectiveness;
  bool? _interestedInPaid;
  String? _ecFormatPreference;
  String? _weeklyTimeCommitment;

  // Step 10: Final Details (New)
  bool? _interestedInTravel;
  String? _howDidYouHear;
  bool? _usedOtherApps;
  bool _agreedToTerms = false;

  final List<String> _motivationOptions = [
    'College Application', 'Skill Building', 'Job', 'Scholarships',
    'Networking', 'Personal Growth', 'Just for fun', 'Others'
  ];

  final List<String> _levelOptions = [
    'League Schools', 'Top 50 Universities', 'Competitive Internships',
    'Elite Jobs', 'Local/State Recognition', 'National Recognization',
    'International Recognization', 'Others'
  ];

  final List<String> _selectivenessOptions = [
    'Highly Selective', 'No Preference', 'Open to All', 'Moderately Selective'
  ];

  final List<String> _formatOptions = [
    'In-person', 'Virtual', 'Hybrid', 'No Preference'
  ];

  final List<String> _timeOptions = [
    '<2hr', '2-5hr', '5-10hr', 'More than 10hr', 'No Preference'
  ];

  final List<String> _referralOptions = [
    'Social Media', 'Teacher/Counselor', 'Friends', 'Family',
    'App Store', 'Google Search', 'Event/Fair', 'Advertisement',
    'School Poster', 'Other'
  ];

  final List<String> _careerInterestOptions = [
    'Software Engineer', 'Data Scientist', 'AI Researcher', 'Cybersecurity Analyst',
    'Web Developer', 'Mobile App Developer', 'Cloud Architect', 'UX/UI Designer',
    'Product Manager', 'Digital Marketer', 'Financial Analyst', 'Investment Banker',
    'Accountant', 'HR Specialist', 'Business Consultant', 'Mechanical Engineer',
    'Civil Engineer', 'Electrical Engineer', 'Aerospace Engineer', 'Chemical Engineer',
    'Doctor (General)', 'Surgeon', 'Nurse', 'Pharmacist', 'Dentist', 'Psychologist',
    'Architect', 'Interior Designer', 'Fashion Designer', 'Graphic Designer',
    'Fine Artist', 'Photographer', 'Journalist', 'Content Writer', 'Public Relations',
    'Lawyer', 'Judge', 'Political Scientist', 'Teacher (K-12)', 'Professor',
    'Research Scientist (Bio)', 'Chemist', 'Physicist', 'Environmental Scientist',
    'Marine Biologist', 'Geologist', 'Chef', 'Hotel Manager', 'Event Planner',
    'Social Media Manager', 'Data Analyst', 'Systems Administrator', 'Network Engineer',
    'Video Editor', 'Animator'
  ];

  final List<String> _otherInterests = [
    'Design', 'Painting', 'Soccer', 'Basketball', 'Running', 'Swimming',
    'Skiing', 'Volleyball', 'Camping', 'Chess', 'Hiking', 'Sewing',
    'Fitness', 'Shopping', 'Volunteering', 'Football', 'Baking', 'Dance',
    'Acting', 'Cheerleading', 'Photography', 'Weightlifting', 'Drama', 'Crafts',
    'Music', 'Sports', 'Cooking', 'Food', 'Travel', 'Community Service',
    'Reading', 'Arts', 'Movies', 'Fashion', 'Animals', 'Outdoors'
  ];

  final List<String> _selectedOtherInterests = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialStep != null) {
      _signUpStep = widget.initialStep!;
      _isLogin = false;
      if (widget.isEditMode) {
        _loadExistingData();
      }
    }
  }

  Future<void> _loadExistingData() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      setState(() => _isProcessing = true);
      final data = await FirebaseService.instance.getResume(userId);
      if (data != null) {
        setState(() {
          if (data['fullName'] != null) _nameController.text = data['fullName'];
          if (data['tagline'] != null) _taglineController.text = data['tagline'];
          if (data['summary'] != null) _summaryController.text = data['summary'];
          if (data['dob'] != null) _dobController.text = data['dob'];
          if (data['gender'] != null) _gender = data['gender'];
          if (data['profileImage'] != null) _profileImageBase64 = data['profileImage'];
          
          if (data['isFirstGen'] != null) _isFirstGen = data['isFirstGen'];
          if (data['weightedGpa'] != null) _weightedGpaController.text = data['weightedGpa'];
          if (data['satScoreRange'] != null) _satScoreRange = data['satScoreRange'];
          if (data['actScoreRange'] != null) _actScoreRange = data['actScoreRange'];

          if (data['educationList'] != null) {
            _educationList.clear();
            _educationList.addAll((data['educationList'] as List).map((e) => Education.fromJson(e as Map<String, dynamic>)));
          }
          if (data['projects'] != null) {
            _projects.clear();
            _projects.addAll((data['projects'] as List).map((p) => Project.fromJson(p as Map<String, dynamic>)));
          }
          if (data['unweightedGpa'] != null) _unweightedGpaController.text = data['unweightedGpa'];
          if (data['skills'] != null) {
            _skills.clear();
            _skills.addAll(List<String>.from(data['skills']));
          }
          if (data['careerInterests'] != null) {
            _selectedCareerInterests.clear();
            _selectedCareerInterests.addAll(List<String>.from(data['careerInterests']));
          }
          if (data['hobbies'] != null) {
            _studentInterests.clear();
            _studentInterests.addAll(List<String>.from(data['hobbies']));
          }
          if (data['certifications'] != null) {
            _certifications.clear();
            _certifications.addAll((data['certifications'] as List).map((c) => Certification.fromJson(c as Map<String, dynamic>)));
          }
          if (data['goals'] != null) {
            final goals = data['goals'] as Map<String, dynamic>;
            if (goals['extracurricularMotivations'] != null) {
              _extracurricularMotivations.clear();
              _extracurricularMotivations.addAll(List<String>.from(goals['extracurricularMotivations']));
            }
            _targetAchievementLevel = goals['targetAchievementLevel'];
            _interestedInLeadership = goals['interestedInLeadership'];
            _interestedInResearch = goals['interestedInResearch'];
          }

          if (data['hobbies'] != null) {
            _studentInterests.clear();
            _studentInterests.addAll(List<String>.from(data['hobbies']));
          }
          if (data['otherInterests'] != null) {
            _selectedOtherInterests.clear();
            _selectedOtherInterests.addAll(List<String>.from(data['otherInterests']));
          }

          if (data['activityPreferences'] != null) {
            final activity = data['activityPreferences'] as Map<String, dynamic>;
            _opportunitySelectiveness = activity['opportunitySelectiveness'];
            _interestedInPaid = activity['interestedInPaid'];
            _ecFormatPreference = activity['ecFormatPreference'];
            _weeklyTimeCommitment = activity['weeklyTimeCommitment'];
          }

          if (data['finalDetails'] != null) {
            final finalDetails = data['finalDetails'] as Map<String, dynamic>;
            _interestedInTravel = finalDetails['interestedInTravel'];
            _howDidYouHear = finalDetails['howDidYouHear'];
            _usedOtherApps = finalDetails['usedOtherApps'];
          }
        });
      }
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your Gmail to reset your password:', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: _buildInputDecoration('Gmail', Icons.email_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                final userExists = await FirebaseService.instance.getResumeByEmail(email) != null;
                if (mounted) {
                  Navigator.pop(context);
                  if (userExists) {
                    _showNewPasswordDialog(email);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not found.')),
                    );
                  }
                }
              }
            },
            child: const Text('Verify Email'),
          ),
        ],
      ),
    );
  }

  void _showNewPasswordDialog(String email) {
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set New Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter new password for $email:', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: _buildInputDecoration('New Password', Icons.lock_outline),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newPass = newPasswordController.text.trim();
              if (newPass.length >= 6) {
                final success = await FirebaseService.instance.updatePasswordByEmail(email, newPass);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _actualPassword = '';
                    _passwordController.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Password updated successfully!' : 'Failed to update password.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters.')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    final password = _actualPassword;
    if (_isLogin) {
      if (_formKey.currentState!.validate()) {
        setState(() => _isProcessing = true);
        final email = _emailController.text.trim();

        User? user = await FirebaseService.instance.loginUser(email, password);
        if (user != null) {
          FirebaseService.instance.setManualUser(user.uid);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // Fallback check: Check Firestore for manual password update
          final resumeData = await FirebaseService.instance.getResumeByEmail(email);
          if (resumeData != null && resumeData['password'] == password) {
            // Found a match in Firestore. In a real app we'd use a token,
            // but for this dev phase, we'll allow entry if the user exists.
            FirebaseService.instance.setManualUser(resumeData['id'] ?? email); // Use email as fallback ID if id not present
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login failed. Check your email and password.')),
              );
            }
          }
        }
        if (mounted) setState(() => _isProcessing = false);
      }
    } else {
      // Sign Up Flow
      if (_signUpStep < _totalSignUpSteps - 1) {
        // Validation logic for step 1 (Account Security)
        if (_signUpStep == 0) {
           if (!_formKey.currentState!.validate()) return;
        }
        setState(() {
          _signUpStep++;
        });
      } else {
        // Final Submission
        if (!_agreedToTerms) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please agree to the Terms and Conditions.')),
          );
          return;
        }

        setState(() => _isProcessing = true);
        final email = _emailController.text.trim();
        final password = _actualPassword;

        User? user = await FirebaseService.instance.registerUser(email, password);
        if (user != null) {
          // Save Resume Data
          final resumeData = {
            'fullName': _nameController.text,
            'email': email,
            'tagline': _taglineController.text,
            'summary': _summaryController.text,
            'dob': _dobController.text,
            'gender': _gender,
            // Academic Profile
            'isFirstGen': _isFirstGen,
            'weightedGpa': _weightedGpaController.text,
            'satScoreRange': _satScoreRange,
            'actScoreRange': _actScoreRange,
            // Education
            'educationList': _educationList.map((e) => e.toJson()).toList(),
            // Projects
            'projects': _projects.map((p) => p.toJson()).toList(),
            // Student Interests
            'unweightedGpa': _unweightedGpaController.text,
            'careerInterests': _selectedCareerInterests,
            'otherInterests': _selectedOtherInterests,
            // Skills & Hobbies
            'skills': _skills,
            'hobbies': _studentInterests,
            'certifications': _certifications.map((c) => c.toJson()).toList(),
            // Goals
            'goals': {
              'extracurricularMotivations': _extracurricularMotivations,
              'targetAchievementLevel': _targetAchievementLevel,
              'interestedInLeadership': _interestedInLeadership,
              'interestedInResearch': _interestedInResearch,
            },
            // Activity Preferences
            'activityPreferences': {
              'opportunitySelectiveness': _opportunitySelectiveness,
              'interestedInPaid': _interestedInPaid,
              'ecFormatPreference': _ecFormatPreference,
              'weeklyTimeCommitment': _weeklyTimeCommitment,
            },
            // Final Details
            'finalDetails': {
              'interestedInTravel': _interestedInTravel,
              'howDidYouHear': _howDidYouHear,
              'usedOtherApps': _usedOtherApps,
            },
            'createdAt': DateTime.now().toIso8601String(),
          };
          
          await FirebaseService.instance.saveResume(user.uid, resumeData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account created and profile set up!')),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration failed. Email might be in use.')),
            );
          }
        }
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  void _previousStep() {
    if (widget.isEditMode && _signUpStep == 1) {
      Navigator.pop(context);
      return;
    }
    if (_signUpStep > 0) {
      setState(() {
        _signUpStep--;
      });
    } else {
      setState(() {
        _isLogin = true;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B3FD8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: (widget.isEditMode && widget.initialStep == null)
        ? AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text('Edit Education', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          )
        : (!_isLogin ? AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: _previousStep,
            ),
            title: Text(
              'Step ${_signUpStep + 1} of $_totalSignUpSteps',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: (_signUpStep + 1) / _totalSignUpSteps,
                backgroundColor: Colors.grey.shade100,
                color: const Color(0xFF5B3FD8),
              ),
            ),
          ) : null),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLogin) _buildLoginHeader() else _buildSignUpHeader(),
              const SizedBox(height: 32),
              if (_isLogin) _buildLoginForm() else _buildSignUpStepContent(),
              const SizedBox(height: 48),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
              else ...[
                _buildMainButton(),
                const SizedBox(height: 16),
                if (_isLogin) _buildToggleAuthMode(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text(
          'Welcome Back',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to your student career guidance portal',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpHeader() {
    String title = '';
    String subtitle = '';
    IconData? headerIcon;

    switch (_signUpStep) {
      case 0:
        title = 'Account Security';
        subtitle = 'Let\'s start with your login credentials';
        headerIcon = Icons.lock_outline;
        break;
      case 1:
        title = 'Personal Info';
        subtitle = 'Tell us a bit about yourself';
        headerIcon = Icons.person_outline;
        break;
      case 2:
        title = 'Academic profile';
        subtitle = 'Helps us recommend right-fit opportunities';
        headerIcon = Icons.school;
        break;
      case 3:
        title = 'Education';
        subtitle = 'Where have you studied?';
        headerIcon = Icons.school_outlined;
        break;
      case 4:
        title = 'Projects';
        subtitle = 'Showcase your work and achievements';
        headerIcon = Icons.rocket_launch_outlined;
        break;
      case 5:
        title = 'Student interests';
        subtitle = 'Tell us about your goals and interests';
        headerIcon = Icons.interests_outlined;
        break;
      case 6:
        title = 'Skills & Certifications';
        subtitle = 'Show off your skills and achievements';
        headerIcon = Icons.verified_outlined;
        break;
      case 7:
        title = 'Goals';
        subtitle = 'Define your aspirations and targets';
        headerIcon = Icons.track_changes_outlined;
        break;
      case 8:
        title = 'Activity Preferences';
        subtitle = 'What kind of opportunities are you looking for?';
        headerIcon = Icons.tune_outlined;
        break;
      case 9:
        title = 'Almost done';
        subtitle = 'A few final questions before we finish';
        headerIcon = Icons.done_all_outlined;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerIcon != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5B3FD8).withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(headerIcon, color: const Color(0xFF5B3FD8), size: 24),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm({bool showForgotPassword = true}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextFieldLabel('Email Address'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: _buildInputDecoration('Enter your email', Icons.email_outlined),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!value.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildTextFieldLabel('Password'),
          TextFormField(
            controller: _passwordController,
            obscureText: false, // Changed to false to handle custom masking
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: _buildInputDecoration('Enter your password', Icons.lock_outline),
            onChanged: (value) {
              // Custom masking logic
              if (value.length > _actualPassword.length) {
                // Character added
                String addedChar = value.substring(_actualPassword.length);
                _actualPassword += addedChar;
              } else if (value.length < _actualPassword.length) {
                // Character removed
                _actualPassword = _actualPassword.substring(0, value.length);
              }
              
              // Update display with asterisks
              String masked = '*' * _actualPassword.length;
              if (_passwordController.text != masked) {
                _passwordController.value = TextEditingValue(
                  text: masked,
                  selection: TextSelection.collapsed(offset: masked.length),
                );
              }
            },
            validator: (value) {
              if (_actualPassword.isEmpty) return 'Please enter a password';
              if (_actualPassword.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          if (showForgotPassword)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(color: const Color(0xFF5B3FD8), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSignUpStepContent() {
    switch (_signUpStep) {
      case 0:
        return _buildLoginForm(showForgotPassword: false);
      case 1:
        return Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    setState(() {
                      _profileImageBase64 = base64Encode(result.files.single.bytes!);
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFF5B3FD8).withAlpha(26),
                  backgroundImage: _profileImageBase64 != null ? MemoryImage(base64Decode(_profileImageBase64!)) : null,
                  child: _profileImageBase64 == null ? const Icon(Icons.add_a_photo_outlined, color: Color(0xFF5B3FD8), size: 30) : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_nameController, 'Full Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(_taglineController, 'Tagline (e.g. Student at MIT)', Icons.label_outline),
            const SizedBox(height: 16),
            _buildTextField(_summaryController, 'Professional Summary', Icons.description_outlined, maxLines: 4),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildGenderSelection(),
          ],
        );
      case 2:
        return _buildAcademicProfileStep();
      case 3:
        return _buildEducationStep();
      case 4:
        return _buildProjectsStep();
      case 5:
        return _buildOtherInterestsStep();
      case 6:
        return _buildStudentInterestsStep();
      case 7:
        return _buildSkillsCertsStep();
      case 8:
        return _buildGoalsStep();
      case 9:
        return _buildActivityPreferencesStep();
      case 10:
        return _buildFinalDetailsStep();
      default:
        return Container();
    }
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel('Date of Birth'),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          onTap: () => _selectDate(context),
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _buildInputDecoration('Select your date of birth', Icons.calendar_today_outlined),
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel('Gender'),
        Row(
          children: [
            Expanded(child: _buildToggleOption('Male', _gender == 'Male', () => setState(() => _gender = 'Male'))),
            const SizedBox(width: 12),
            Expanded(child: _buildToggleOption('Female', _gender == 'Female', () => setState(() => _gender = 'Female'))),
            const SizedBox(width: 12),
            Expanded(child: _buildToggleOption('Other', _gender == 'Other', () => setState(() => _gender = 'Other'))),
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel('FIRST-GENERATION COLLEGE STUDENT? *'),
        Row(
          children: [
            Expanded(child: _buildToggleOption('Yes', _isFirstGen == true, () => setState(() => _isFirstGen = true))),
            const SizedBox(width: 16),
            Expanded(child: _buildToggleOption('No', _isFirstGen == false, () => setState(() => _isFirstGen = false))),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('WEIGHTED GPA *'),
        _buildTextField(_weightedGpaController, '3.9', Icons.grade_outlined),
        const SizedBox(height: 24),
        _buildTextFieldLabel('SAT SCORE RANGE *'),
        _buildScoreGrid(['400-990', '1000-1190', '1200-1390', '1400-1490', '1500+', 'None'], _satScoreRange, (val) => setState(() => _satScoreRange = val)),
        const SizedBox(height: 24),
        _buildTextFieldLabel('ACT SCORE RANGE *'),
        _buildScoreGrid(['1-22', '23-29', '30-33', '34+', 'None'], _actScoreRange, (val) => setState(() => _actScoreRange = val)),
      ],
    );
  }

  Widget _buildStudentInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel('UNWEIGHTED GPA *'),
        _buildTextField(_unweightedGpaController, '3.8', Icons.grade),
        const SizedBox(height: 24),
        _buildTextFieldLabel('CAREER INTERESTS (Select up to 5) *'),
        _buildInterestSelection(),
      ],
    );
  }

  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel('WHY DO YOU WANT EXTRACURRICULARS? *'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _motivationOptions.map((opt) {
            final isSelected = _extracurricularMotivations.contains(opt);
            return FilterChip(
              label: Text(opt, style: GoogleFonts.poppins(fontSize: 13, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _extracurricularMotivations.add(opt);
                  } else {
                    _extracurricularMotivations.remove(opt);
                  }
                });
              },
              selectedColor: const Color(0xFF5B3FD8),
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFF5B3FD8) : Colors.grey.shade200)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('WHAT LEVEL DO YOU WANT TO REACH? *'),
        _buildScoreGrid(_levelOptions, _targetAchievementLevel, (val) => setState(() => _targetAchievementLevel = val)),
        const SizedBox(height: 24),
        _buildTextFieldLabel('LOOKING FOR LEADERSHIP ROLES? *'),
        Row(
          children: [
            Expanded(child: _buildToggleOption('Yes', _interestedInLeadership == true, () => setState(() => _interestedInLeadership = true))),
            const SizedBox(width: 16),
            Expanded(child: _buildToggleOption('No', _interestedInLeadership == false, () => setState(() => _interestedInLeadership = false))),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('INTERESTED IN RESEARCH? *'),
        Row(
          children: [
            Expanded(child: _buildToggleOption('Yes', _interestedInResearch == true, () => setState(() => _interestedInResearch = true))),
            const SizedBox(width: 16),
            Expanded(child: _buildToggleOption('No', _interestedInResearch == false, () => setState(() => _interestedInResearch = false))),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel('OPPORTUNITY SELECTIVENESS? *'),
        _buildScoreGrid(_selectivenessOptions, _opportunitySelectiveness, (val) => setState(() => _opportunitySelectiveness = val)),
        const SizedBox(height: 24),
        _buildTextFieldLabel('INTERESTED IN PAID OPPORTUNITIES? *'),
        Row(
          children: [
            Expanded(child: _buildToggleOption('Yes', _interestedInPaid == true, () => setState(() => _interestedInPaid = true))),
            const SizedBox(width: 16),
            Expanded(child: _buildToggleOption('No', _interestedInPaid == false, () => setState(() => _interestedInPaid = false))),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('EC FORMAT PREFERENCE? *'),
        _buildScoreGrid(_formatOptions, _ecFormatPreference, (val) => setState(() => _ecFormatPreference = val)),
        const SizedBox(height: 24),
        _buildTextFieldLabel('WEEKLY TIME COMMITMENT *'),
        _buildScoreGrid(_timeOptions, _weeklyTimeCommitment, (val) => setState(() => _weeklyTimeCommitment = val)),
      ],
    );
  }

  Widget _buildFinalDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel('INTERESTED IN TRAVEL/STUDY ABROAD? *'),
        Row(
          children: [
            Expanded(child: _buildToggleOption('Yes', _interestedInTravel == true, () => setState(() => _interestedInTravel = true))),
            const SizedBox(width: 16),
            Expanded(child: _buildToggleOption('No', _interestedInTravel == false, () => setState(() => _interestedInTravel = false))),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('HOW DID YOU HEAR ABOUT US? *'),
        _buildScoreGrid(_referralOptions, _howDidYouHear, (val) => setState(() => _howDidYouHear = val)),
        const SizedBox(height: 24),
        _buildTextFieldLabel('USED OTHER EC FINDER APPS BEFORE? *'),
        Row(
          children: [
            Expanded(child: _buildToggleOption('Yes', _usedOtherApps == true, () => setState(() => _usedOtherApps = true))),
            const SizedBox(width: 16),
            Expanded(child: _buildToggleOption('No', _usedOtherApps == false, () => setState(() => _usedOtherApps = false))),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _agreedToTerms ? const Color(0xFF5B3FD8).withAlpha(15) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _agreedToTerms ? const Color(0xFF5B3FD8) : Colors.grey.shade200),
          ),
          child: CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
            title: Text(
              'I agree to the Terms and Conditions and Privacy Policy',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF5B3FD8),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildOtherInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel('INTERESTS'),
        Text(
          'Select minimum of three interest areas',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _otherInterests.length,
          itemBuilder: (context, index) {
            final interest = _otherInterests[index];
            final isSelected = _selectedOtherInterests.contains(interest);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedOtherInterests.remove(interest);
                  } else {
                    _selectedOtherInterests.add(interest);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5B3FD8).withAlpha(26) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF5B3FD8) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getInterestIcon(interest),
                      color: isSelected ? const Color(0xFF5B3FD8) : Colors.grey.shade400,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      interest,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF5B3FD8) : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('ADD INTEREST'),
        Row(
          children: [
            Expanded(child: _buildTextField(_interestSearchController, 'Type to add custom interest', Icons.add_circle_outline)),
            const SizedBox(width: 8),
            _buildSmallAddButton(() {
              final interest = _interestSearchController.text.trim();
              if (interest.isNotEmpty && !_otherInterests.contains(interest)) {
                setState(() {
                  _otherInterests.add(interest);
                  _selectedOtherInterests.add(interest);
                  _interestSearchController.clear();
                });
              }
            }),
          ],
        ),
        const SizedBox(height: 24),
        Text('Student Interests', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTextField(_studentInterestController, 'Interest name', Icons.star_border_outlined)),
            const SizedBox(width: 8),
            _buildSmallAddButton(() {
              final interest = _studentInterestController.text.trim();
              if (interest.isNotEmpty && !_studentInterests.contains(interest)) {
                setState(() {
                  _studentInterests.add(interest);
                  _studentInterestController.clear();
                });
              }
            }),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _studentInterests.map((interest) => Chip(
            label: Text(interest),
            onDeleted: () => setState(() => _studentInterests.remove(interest)),
            backgroundColor: Colors.orange.withAlpha(26),
            side: BorderSide.none,
          )).toList(),
        ),
      ],
    );
  }

  IconData _getInterestIcon(String interest) {
    switch (interest.toLowerCase()) {
      case 'design': return Icons.architecture;
      case 'painting': return Icons.palette;
      case 'soccer': return Icons.sports_soccer;
      case 'basketball': return Icons.sports_basketball;
      case 'running': return Icons.directions_run;
      case 'swimming': return Icons.pool;
      case 'skiing': return Icons.downhill_skiing;
      case 'volleyball': return Icons.sports_volleyball;
      case 'camping': return Icons.terrain;
      case 'chess': return Icons.extension;
      case 'hiking': return Icons.hiking;
      case 'sewing': return Icons.content_cut;
      case 'fitness': return Icons.fitness_center;
      case 'shopping': return Icons.shopping_cart;
      case 'volunteering': return Icons.volunteer_activism;
      case 'football': return Icons.sports_football;
      case 'baking': return Icons.bakery_dining;
      case 'dance': return Icons.emoji_events;
      case 'acting': return Icons.theater_comedy;
      case 'cheerleading': return Icons.campaign;
      case 'photography': return Icons.camera_alt;
      case 'weightlifting': return Icons.fitness_center;
      case 'drama': return Icons.masks;
      case 'crafts': return Icons.brush;
      case 'music': return Icons.music_note;
      case 'sports': return Icons.sports;
      case 'cooking': return Icons.restaurant;
      case 'food': return Icons.fastfood;
      case 'travel': return Icons.flight;
      case 'community service': return Icons.people;
      case 'reading': return Icons.book;
      case 'arts': return Icons.brush;
      case 'movies': return Icons.movie;
      case 'fashion': return Icons.checkroom;
      case 'animals': return Icons.pets;
      case 'outdoors': return Icons.nature_people;
      default: return Icons.star_border;
    }
  }

  Widget _buildInterestSelection() {
    return Column(
      children: [
        TextFormField(
          controller: _interestSearchController,
          decoration: _buildInputDecoration('Search interests...', Icons.search),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _selectedCareerInterests.map((interest) => Chip(
            label: Text(interest, style: const TextStyle(fontSize: 12)),
            onDeleted: () => setState(() => _selectedCareerInterests.remove(interest)),
            backgroundColor: const Color(0xFF5B3FD8).withAlpha(26),
            side: BorderSide.none,
          )).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView(
            children: _careerInterestOptions.where((opt) => opt.toLowerCase().contains(_interestSearchController.text.toLowerCase()) && !_selectedCareerInterests.contains(opt)).map((opt) {
              return ListTile(
                title: Text(opt, style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  if (_selectedCareerInterests.length < 5) {
                    setState(() {
                      _selectedCareerInterests.add(opt);
                      _interestSearchController.clear();
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select up to 5 interests only.')));
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF5B3FD8) : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF5B3FD8).withAlpha(26), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF5B3FD8) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreGrid(List<String> options, String? selectedValue, Function(String) onSelect) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final opt = options[index];
        final isSelected = selectedValue == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFF5B3FD8) : Colors.grey.shade200, width: isSelected ? 2 : 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  opt,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF5B3FD8) : Colors.grey.shade600,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF5B3FD8)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEducationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add education',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select school level',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: _educationLevels.asMap().entries.map((entry) {
              int idx = entry.key;
              String level = entry.value;
              bool isSelected = _selectedEduLevelIndex == idx;
              bool isDisabled = _ongoingLevelIndex != null && idx > _ongoingLevelIndex!;

              return Expanded(
                child: GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () => setState(() => _selectedEduLevelIndex = idx),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      level,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isDisabled
                            ? Colors.grey.shade400
                            : (isSelected ? Colors.white : Colors.grey.shade600),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(_schoolController, 'School name', Icons.search),
        const SizedBox(height: 16),
        _buildTextField(_classOfController, 'Class of', Icons.keyboard_arrow_down),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_yearFromController, 'Year from', null)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_yearToController, 'Year to', null)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'This will be editable if you have multiple high school',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _isEduOngoing,
                  onChanged: (val) {
                    setState(() {
                      _isEduOngoing = val ?? false;
                      if (_isEduOngoing) {
                        _ongoingLevelIndex = _selectedEduLevelIndex;
                        _yearToController.text = 'Present';
                      } else {
                        _ongoingLevelIndex = null;
                        _yearToController.clear();
                      }
                    });
                  },
                  activeColor: const Color(0xFF5B3FD8),
                ),
                Text('Ongoing', style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_gradeFromController, 'Grade from', null)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(_gradeToController, 'Grade to', null)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(_gpaController, 'GPA', null, suffixText: 'Optional'),
        const SizedBox(height: 24),
        _buildActionButton('Add Attachment', Icons.attach_file, () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles();
          if (result != null) {
            setState(() {
              _eduAttachments.add(result.files.single.path!);
            });
          }
        }),
        if (_eduAttachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _eduAttachments.map((path) => Chip(
              label: Text(path.split('/').last, style: const TextStyle(fontSize: 12)),
              onDeleted: () => setState(() => _eduAttachments.remove(path)),
            )).toList(),
          ),
        ],
        const SizedBox(height: 16),
        _buildActionButton('Add Education Entry', Icons.add, () {
          if (_schoolController.text.isNotEmpty) {
            setState(() {
              _educationList.add(Education(
                level: _educationLevels[_selectedEduLevelIndex],
                school: _schoolController.text,
                classOf: _classOfController.text,
                yearFrom: _yearFromController.text,
                yearTo: _yearToController.text,
                gradeFrom: _gradeFromController.text,
                gradeTo: _gradeToController.text,
                gpa: _gpaController.text,
                isOngoing: _isEduOngoing,
                attachments: List.from(_eduAttachments),
              ));
              _schoolController.clear();
              _classOfController.clear();
              _yearFromController.clear();
              _yearToController.clear();
              _gradeFromController.clear();
              _gradeToController.clear();
              _gpaController.clear();
              _isEduOngoing = false;
              _eduAttachments = [];
            });
          }
        }),
        const SizedBox(height: 24),
        ..._educationList.map((edu) => _buildCard(
          title: '${edu.level}: ${edu.school}',
          subtitle: '${edu.yearFrom} - ${edu.yearTo} | GPA: ${edu.gpa}',
          onDelete: () => setState(() {
             _educationList.remove(edu);
             if (edu.isOngoing) _ongoingLevelIndex = null;
          }),
        )),
      ],
    );
  }

  Widget _buildProjectsStep() {
    return Column(
      children: [
        ..._projects.asMap().entries.map((entry) {
          int idx = entry.key;
          Project project = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Project ${idx + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    if (_projects.length > 1)
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _projects.removeAt(idx))),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(null, 'Project Title', Icons.rocket_launch_outlined, initialValue: project.title, onChanged: (v) => project.title = v),
                const SizedBox(height: 16),
                _buildTextFieldLabel('Link to Career Interests'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [..._selectedCareerInterests, 'Others'].map((interest) {
                    final isSelected = project.linkedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest, style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            project.linkedInterests = [...project.linkedInterests, interest];
                          } else {
                            project.linkedInterests = project.linkedInterests.where((i) => i != interest).toList();
                          }
                        });
                      },
                      selectedColor: const Color(0xFF5B3FD8),
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFF5B3FD8) : Colors.grey.shade200)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildTextFieldLabel('Link to Skills'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _skills.map((skill) {
                    final isSelected = project.linkedSkills.contains(skill);
                    return FilterChip(
                      label: Text(skill, style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            project.linkedSkills = [...project.linkedSkills, skill];
                          } else {
                            project.linkedSkills = project.linkedSkills.where((s) => s != skill).toList();
                          }
                        });
                      },
                      selectedColor: Colors.orange,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? Colors.orange : Colors.grey.shade200)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildTextField(null, 'Description', Icons.description_outlined, maxLines: 3, initialValue: project.description, onChanged: (v) => project.description = v),
                const SizedBox(height: 12),
                _buildActionButton('Add Attachment', Icons.attach_file, () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                    setState(() {
                      project.attachments.add(result.files.single.path!);
                    });
                  }
                }),
                if (project.attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: project.attachments.map((path) => Chip(
                      label: Text(path.split('/').last, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => setState(() => project.attachments.remove(path)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
        _buildActionButton('Add Project', Icons.add, () => setState(() => _projects.add(Project()))),
      ],
    );
  }

  final List<String> _certLevels = ['Basic', 'Intermediate', 'Advanced'];
  String _selectedCertLevel = 'Basic';

  Widget _buildSkillsCertsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skills', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTextField(_skillController, 'Skill name', Icons.bolt_outlined)),
            const SizedBox(width: 8),
            _buildSmallAddButton(() {
              final skill = _skillController.text.trim();
              if (skill.isNotEmpty && !_skills.contains(skill)) {
                setState(() {
                  _skills.add(skill);
                  _skillController.clear();
                });
              }
            }),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _skills.map((skill) => Chip(
            label: Text(skill),
            onDeleted: () => setState(() => _skills.remove(skill)),
            backgroundColor: const Color(0xFF5B3FD8).withAlpha(26),
            side: BorderSide.none,
          )).toList(),
        ),
        const SizedBox(height: 24),
        Text('Student Interests', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTextField(_studentInterestController, 'Interest name', Icons.star_border_outlined)),
            const SizedBox(width: 8),
            _buildSmallAddButton(() {
              final interest = _studentInterestController.text.trim();
              if (interest.isNotEmpty && !_studentInterests.contains(interest)) {
                setState(() {
                  _studentInterests.add(interest);
                  _studentInterestController.clear();
                });
              }
            }),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _studentInterests.map((interest) => Chip(
            label: Text(interest),
            onDeleted: () => setState(() => _studentInterests.remove(interest)),
            backgroundColor: Colors.orange.withAlpha(26),
            side: BorderSide.none,
          )).toList(),
        ),
        const SizedBox(height: 24),
        _buildTextField(_certNameController, 'Cert Name', Icons.workspace_premium_outlined),
        const SizedBox(height: 16),
        Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedSkillForCert,
              hint: Text('Link to Career Interest', style: GoogleFonts.poppins()),
              decoration: _buildInputDecoration('', Icons.stars_outlined),
              items: [..._selectedCareerInterests, 'Others'].map((interest) => DropdownMenuItem(value: interest, child: Text(interest))).toList(),
              onChanged: (val) => setState(() => _selectedSkillForCert = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCertLevel,
              hint: Text('Level', style: GoogleFonts.poppins()),
              decoration: _buildInputDecoration('', Icons.layers_outlined),
              items: _certLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
              onChanged: (val) => setState(() => _selectedCertLevel = val ?? 'Basic'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionButton('Add Attachment', Icons.attach_file, () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles();
          if (result != null) {
            setState(() {
              _certAttachments.add(result.files.single.path!);
            });
          }
        }),
        if (_certAttachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _certAttachments.map((path) => Chip(
              label: Text(path.split('/').last, style: const TextStyle(fontSize: 12)),
              onDeleted: () => setState(() => _certAttachments.remove(path)),
            )).toList(),
          ),
        ],
        const SizedBox(height: 16),
        _buildActionButton('Add Certification', Icons.add, () {
          if (_certNameController.text.isNotEmpty && _selectedSkillForCert != null) {
            setState(() {
              _certifications.add(Certification(
                name: _certNameController.text,
                skill: _selectedSkillForCert!,
                level: _selectedCertLevel,
                attachments: List.from(_certAttachments),
              ));
              _certNameController.clear();
              _selectedSkillForCert = null;
              _certAttachments.clear();
              _selectedCertLevel = 'Basic';
            });
          }
        }),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          children: _certifications.map((cert) => Chip(
            label: Text('${cert.name} (${cert.skill} - ${cert.level})'),
            onDeleted: () => setState(() => _certifications.remove(cert)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    if (widget.isEditMode) {
      return Column(
        children: [
          if (_signUpStep < _totalSignUpSteps - 1)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => setState(() => _signUpStep++),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3FD8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          if (_signUpStep < _totalSignUpSteps - 1) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _saveAndClose,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B3FD8),
                side: const BorderSide(color: Color(0xFF5B3FD8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _signUpStep == _totalSignUpSteps - 1 ? 'Save & Close' : 'Save & Exit',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    String label = _isLogin ? 'Sign In' : (_signUpStep == _totalSignUpSteps - 1 ? 'Complete Sign Up' : 'Continue');
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B3FD8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndClose() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      setState(() => _isProcessing = true);
      try {
        final resumeData = {
          'profileImage': _profileImageBase64,
          'fullName': _nameController.text,
          'tagline': _taglineController.text,
          'summary': _summaryController.text,
          'dob': _dobController.text,
          'gender': _gender,
          // Academic Profile
          'isFirstGen': _isFirstGen,
          'weightedGpa': _weightedGpaController.text,
          'satScoreRange': _satScoreRange,
          'actScoreRange': _actScoreRange,
          // Education
          'educationList': _educationList.map((e) => e.toJson()).toList(),
          // Projects
          'projects': _projects.map((p) => p.toJson()).toList(),
          // Student Interests
          'unweightedGpa': _unweightedGpaController.text,
          'careerInterests': _selectedCareerInterests,
          'otherInterests': _selectedOtherInterests,
          // Skills & Hobbies
          'skills': _skills,
          'hobbies': _studentInterests,
          'certifications': _certifications.map((c) => c.toJson()).toList(),
          // Goals
          'goals': {
            'extracurricularMotivations': _extracurricularMotivations,
            'targetAchievementLevel': _targetAchievementLevel,
            'interestedInLeadership': _interestedInLeadership,
            'interestedInResearch': _interestedInResearch,
          },
          // Activity Preferences
          'activityPreferences': {
            'opportunitySelectiveness': _opportunitySelectiveness,
            'interestedInPaid': _interestedInPaid,
            'ecFormatPreference': _ecFormatPreference,
            'weeklyTimeCommitment': _weeklyTimeCommitment,
          },
          // Final Details
          'finalDetails': {
            'interestedInTravel': _interestedInTravel,
            'howDidYouHear': _howDidYouHear,
            'usedOtherApps': _usedOtherApps,
          },
        };

        await FirebaseService.instance.saveResume(userId, resumeData);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildToggleAuthMode() {
    return Center(
      child: TextButton(
        onPressed: () => setState(() {
          _isLogin = !_isLogin;
          _signUpStep = 0;
        }),
        child: RichText(
          text: TextSpan(
            text: 'Don\'t have an account? ',
            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
            children: const [
              TextSpan(
                text: 'Sign Up',
                style: TextStyle(
                  color: Color(0xFF5B3FD8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTextFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController? controller, String label, IconData? icon, {int maxLines = 1, String? initialValue, Function(String)? onChanged, String? suffixText}) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _buildInputDecoration(label, icon, suffixText: suffixText),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData? icon, {String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF5B3FD8), size: 20) : null,
      suffixText: suffixText,
      suffixStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5B3FD8), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5B3FD8),
          side: const BorderSide(color: Color(0xFF5B3FD8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildSmallAddButton(VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF5B3FD8), borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: onPressed),
    );
  }

  Widget _buildCard({required String title, required String subtitle, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: onDelete),
      ),
    );
  }
}
