import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vvp_app/screens/home_screen.dart';
import 'package:vvp_app/services/compass_service.dart';
import 'package:vvp_app/services/vastu_service.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        home: const HomeScreen(),
      ),
    );
  }
}
