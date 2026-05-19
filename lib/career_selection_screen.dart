import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'career_plan_screen.dart';

class CareerSelectionScreen extends StatefulWidget {
  const CareerSelectionScreen({super.key});

  @override
  State<CareerSelectionScreen> createState() => _CareerSelectionScreenState();
}

class _CareerSelectionScreenState extends State<CareerSelectionScreen> {
  final TextEditingController _careerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Start New Journey', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 16 : 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch_outlined, size: 80, color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              const SizedBox(height: 32),
              Text(
                'What is your target career?',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the career path you want to explore. AI will generate a personalized learning roadmap for you.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _careerController,
                autofocus: true,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'e.g. AI Engineer, Product Designer...',
                  hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _navigateToPlan(value.trim());
                  }
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    final career = _careerController.text.trim();
                    if (career.isNotEmpty) {
                      _navigateToPlan(career);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Generate AI Plan',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPlan(String career) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CareerPlanScreen(targetCareer: career),
      ),
    );
  }
}
