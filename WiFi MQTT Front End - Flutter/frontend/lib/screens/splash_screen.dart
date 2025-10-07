import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aquarium_controller_app/services/mqtt_service.dart';
import 'package:aquarium_controller_app/screens/aquarium_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isConnectionAttemptComplete = false;

  @override
  void initState() {
    super.initState();
    // Connect to MQTT as soon as the screen is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToMqtt();
    });
  }

  // This function now only handles the connection logic.
  Future<void> _connectToMqtt() async {
    final mqttService = Provider.of<MqttService>(context, listen: false);
    await mqttService.connect();

    // After the connection attempt is finished, update the UI
    // to show the "Tap to continue" message.
    if (mounted) {
      setState(() {
        _isConnectionAttemptComplete = true;
      });
    }
  }

  // This function handles the navigation.
  void _navigateToDashboard() {
    // We only allow navigation after the connection attempt is complete.
    if (_isConnectionAttemptComplete && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AquariumDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector wraps the whole screen, making it tappable.
    return GestureDetector(
      onTap: _navigateToDashboard,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo centered
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Aquarium Water Parameter Controller',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'By The Fintastic 4 + 1',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 60),
              // Show a progress indicator while connecting...
              if (!_isConnectionAttemptComplete)
                const CircularProgressIndicator(color: Colors.white),

              const SizedBox(height: 20),
              // This widget will update the connection status text in real-time.
              Consumer<MqttService>(
                builder: (context, mqttService, child) {
                  return Text(
                    mqttService.connectionStatus,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  );
                },
              ),
              const SizedBox(height: 10),
              // ...then show a message prompting the user to tap.
              if (_isConnectionAttemptComplete)
                const Opacity(
                  opacity: 0.8,
                  child: Text(
                    'Tap anywhere to continue',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

