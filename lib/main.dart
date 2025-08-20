import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vvp_app/screens/home_screen.dart';
import 'package:vvp_app/screens/login_screen.dart';
import 'package:vvp_app/services/compass_service.dart';
import 'package:vvp_app/services/vastu_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const MyApp({Key? key, this.firebaseInitialized = false}) : super(key: key);

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
            ? const AuthenticationWrapper() 
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
        // Otherwise, they're not signed in
        return const LoginScreen();
      },
    );
  }
}
