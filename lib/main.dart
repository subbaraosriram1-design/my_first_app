import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'career_profile_screen.dart';
import 'ai_insights_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Career Guidance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B3FD8),
          primary: const Color(0xFF5B3FD8),
          surface: Colors.white,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const MyHomePage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Screens for the navigation
    final List<Widget> screens = [
      const CareerProfileScreen(), // The new profile/home screen
      const Center(child: Text('Feed Screen')),
      const Center(child: Text('Connections Screen')),
      const Center(child: Text('Chat Screen')),
      const AiInsightsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFF5B3FD8).withAlpha(26),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: _selectedIndex == 0 ? const Color(0xFF5B3FD8) : Colors.grey),
              selectedIcon: const Icon(Icons.person, color: Color(0xFF5B3FD8)),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.rss_feed, color: _selectedIndex == 1 ? const Color(0xFF5B3FD8) : Colors.grey),
              selectedIcon: const Icon(Icons.rss_feed, color: Color(0xFF5B3FD8)),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: _selectedIndex == 2 ? const Color(0xFF5B3FD8) : Colors.grey),
              selectedIcon: const Icon(Icons.people, color: Color(0xFF5B3FD8)),
              label: 'Connections',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline, color: _selectedIndex == 3 ? const Color(0xFF5B3FD8) : Colors.grey),
              selectedIcon: const Icon(Icons.chat_bubble, color: Color(0xFF5B3FD8)),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.lightbulb_outline, color: _selectedIndex == 4 ? const Color(0xFF5B3FD8) : Colors.grey),
              selectedIcon: const Icon(Icons.lightbulb, color: Color(0xFF5B3FD8)),
              label: 'AI Insights',
            ),
          ],
        ),
      ),
    );
  }
}
