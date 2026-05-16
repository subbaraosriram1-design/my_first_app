import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_service.dart';
import 'career_plan_screen.dart';

class CareerSelectionScreen extends StatefulWidget {
  const CareerSelectionScreen({super.key});

  @override
  State<CareerSelectionScreen> createState() => _CareerSelectionScreenState();
}

class _CareerSelectionScreenState extends State<CareerSelectionScreen> {
  List<String> _interests = [];
  bool _isLoading = true;
  String? _selectedInterest;
  final TextEditingController _customInterestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      final data = await FirebaseService.instance.getResume(userId);
      if (data != null) {
        setState(() {
          _interests = List<String>.from(data['careerInterests'] ?? []);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Select Career Interest', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3FD8)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What career interest do you want to focus on?',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI will generate a personalized plan for your selection.',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  if (_interests.isEmpty)
                    Center(
                      child: Text(
                        'No interests found in your profile. Add one below!',
                        style: GoogleFonts.poppins(color: Colors.grey.shade500),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text('Choose an interest', style: GoogleFonts.poppins()),
                          value: _interests.contains(_selectedInterest) ? _selectedInterest : null,
                          items: _interests.map((interest) {
                            return DropdownMenuItem<String>(
                              value: interest,
                              child: Text(interest, style: GoogleFonts.poppins()),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            setState(() {
                              _selectedInterest = value;
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Text(
                    'Or enter a different interest:',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customInterestController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Data Scientist, UX Designer',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _selectedInterest = value;
                        });
                      }
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _selectedInterest == null
                          ? null
                          : () async {
                              // If it's a new interest, add it to the user's career interests in the database
                              final userId = FirebaseService.instance.currentUserId;
                              if (userId != null) {
                                setState(() => _isLoading = true);
                                Map<String, dynamic> updateData = {'activeCareerInterest': _selectedInterest!};
                                if (!_interests.contains(_selectedInterest)) {
                                  updateData['careerInterests'] = List<String>.from(_interests)..add(_selectedInterest!);
                                }
                                await FirebaseService.instance.saveResume(userId, updateData);
                              }

                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CareerPlanScreen(targetCareer: _selectedInterest!),
                                  ),
                                ).then((_) => _loadInterests());
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3FD8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        'Generate AI Plan',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
