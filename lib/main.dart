import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: FirebaseConfigs.personal,
  );

  // Start offline sync listener
  SyncService().startListening();

  runApp(const LagmayApp());
}

class LagmayApp extends StatefulWidget {
  const LagmayApp({super.key});

  @override
  State<LagmayApp> createState() => _LagmayAppState();
}

class _LagmayAppState extends State<LagmayApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lagmay',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Forced light theme as requested
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B), // Teal
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Light grey-blue
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00796B)),
              ),
            );
          }
          
          if (snapshot.hasData || AuthService().offlineUser != null) {
            return const HomeScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
