import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'career_profile_screen.dart';
import 'roadmap_choice_screen.dart';
import 'reminders_screen.dart';
import 'events_provider.dart';
import 'career_hub_screen.dart';
import 'nearby_you_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // On some platforms, you might need to provide options manually if the default config isn't found
    debugPrint('Check if GoogleService-Info.plist or google-services.json is in the correct folder.');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventsProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if index was passed as an argument
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _selectedIndex = args;
    }
  }

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
      const RoadmapChoiceScreen(),
      const RemindersScreen(),
      const NearbyYouScreen(),
      const CareerHubScreen(),
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
              icon: Icon(Icons.map_outlined, color: _selectedIndex == 1 ? const Color(0xFF5B3FD8) : Colors.grey),
              selectedIcon: const Icon(Icons.map, color: Color(0xFF5B3FD8)),
              label: 'Roadmap',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined, color: _selectedIndex == 2 ? const Color(0xFF5B3FD8) : Colors.grey),
              selectedIcon: const Icon(Icons.notifications, color: Color(0xFF5B3FD8)),
              label: 'Reminders',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined, color: _selectedIndex == 3 ? const Color(0xFF5B3FD8) : Colors.grey),
              selectedIcon: const Icon(Icons.location_on, color: Color(0xFF5B3FD8)),
              label: 'Nearby',
            ),
            NavigationDestination(
              icon: Icon(Icons.lightbulb_outline, color: _selectedIndex == 4 ? const Color(0xFF5B3FD8) : Colors.grey),
              selectedIcon: const Icon(Icons.lightbulb, color: Color(0xFF5B3FD8)),
              label: 'Career Hub',
            ),
          ],
        ),
      ),
    );
  }
}
