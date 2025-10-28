import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aquarium_controller_app/screens/splash_screen.dart';
import 'package:aquarium_controller_app/services/mqtt_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider is used to provide the MqttService to all widgets in the app.
    return MultiProvider(
      providers: [
        // The MqttService is created once and shared across the app.
        ChangeNotifierProvider(create: (_) => MqttService()),
      ],
      child: MaterialApp(
        title: 'Aquarium Controller',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: const Color(0xFF1976D2), 
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2), 
            elevation: 0,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white), 
            titleLarge: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white),
          ),
          cardTheme: CardThemeData(
            color: Colors.blue.shade700,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
        ),
        // The app starts with the SplashScreen.
        home: const SplashScreen(),
      ),
    );
  }
}

