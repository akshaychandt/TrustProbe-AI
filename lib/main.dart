import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trustprobe_ai/app/app.locator.dart';
import 'package:trustprobe_ai/app/app.router.dart';
import 'package:trustprobe_ai/services/device_id_service.dart';
import 'package:stacked_services/stacked_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Web
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDemoKey123", // Placeholder - User will replace
      authDomain: "trustprobe-ai.firebaseapp.com",
      projectId: "trustprobe-ai",
      storageBucket: "trustprobe-ai.appspot.com",
      messagingSenderId: "123456789",
      appId: "1:123456789:web:abcdef123456",
    ),
  );

  // Setup Stacked locator (dependency injection)
  setupLocator();

  // Initialize device ID for anonymous scan tracking
  await locator<DeviceIdService>().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustProbe AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF00d2ff),
        scaffoldBackgroundColor: Color(0xFF1a1a2e),
        useMaterial3: true,
      ),
      navigatorKey: StackedService.navigatorKey,
      onGenerateRoute: StackedRouter().onGenerateRoute,
    );
  }
}
