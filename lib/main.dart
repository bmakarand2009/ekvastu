import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vvp_app/screens/home_screen.dart';
import 'package:vvp_app/screens/login_screen.dart';
import 'package:vvp_app/screens/onboarding_screen.dart';
import 'package:vvp_app/services/compass_service.dart';
import 'package:vvp_app/services/vastu_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    print('Firebase initialization successful');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // We'll continue without Firebase for now
  }
  
  // Check if the user has seen onboarding
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  
  runApp(MyApp(
    firebaseInitialized: firebaseInitialized, 
    hasSeenOnboarding: hasSeenOnboarding
  ));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final bool hasSeenOnboarding;
  
  const MyApp({Key? key, this.firebaseInitialized = false, this.hasSeenOnboarding = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CompassService()),
        ChangeNotifierProvider(create: (_) => VastuService()),
      ],
      child: MaterialApp(
        title: 'VVP - Vastu Virtual Planner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFFF3ECE4), // Set background color to #f3ece4
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            secondary: Colors.amber,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          useMaterial3: true,
        ),
        home: firebaseInitialized 
            ? (hasSeenOnboarding ? const AuthenticationWrapper() : const OnboardingScreen())
            : const HomeScreen(), // Fallback to home screen if Firebase fails to initialize
      ),
    );
  }
}

/// Widget that handles checking authentication state
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has user data, then they're already signed in
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Otherwise, they're not signed in - show onboarding instead of login
        return const OnboardingScreen();
      },
    );
  }
}
