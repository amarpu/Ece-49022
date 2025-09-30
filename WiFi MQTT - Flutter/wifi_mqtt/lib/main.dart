import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:math'; // Import the math library for random numbers

// --- Configuration for Adafruit IO MQTT Broker ---
// IMPORTANT: These must match the details from your Adafruit IO account
const String aioServer = 'io.adafruit.com';
const String aioUsername = 'XiaohanYu1'; // Your Adafruit IO Username

// CHANGE THSI TOO
const String aioKey = '_aio_NTnz10gHo8ptPPrgOyJGFKTpS3dd'; // I don't think publishing Adafruit IO Key is a security risk

const int aioPort = 1883;

// The MQTT topic path for your feed.
// It's always in the format: "username/feeds/feed_name"
const String ledControlFeed = '$aioUsername/feeds/led-control';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 MQTT Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        useMaterial3: true,
      ),
      home: const MqttControllerPage(),
    );
  }
}

class MqttControllerPage extends StatefulWidget {
  const MqttControllerPage({super.key});

  @override
  State<MqttControllerPage> createState() => _MqttControllerPageState();
}

class _MqttControllerPageState extends State<MqttControllerPage> {
  String _ledStatus = 'Unknown';
  String _connectionStatus = 'Disconnected';
  late MqttServerClient _client;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  // --- MQTT Connection Logic ---
  void _connect() async {
    // A unique client ID for this connection
    // [FIXED] Create a shorter, random client ID that Adafruit IO will accept.
    final clientID = 'flutter-client-${Random().nextInt(100000)}';
    _client = MqttServerClient.withPort(aioServer, clientID, aioPort);
    _client.logging(on: false); // Disable logging for cleaner output
    _client.keepAlivePeriod = 60;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    // Set the username and password for the connection
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientID)
        .withWillQos(MqttQos.atLeastOnce)
        .startClean()
        .withWillTopic('willtopic') // Not used by Adafruit IO but required by the library
        .withWillMessage('My will message')
        .authenticateAs(aioUsername, aioKey);

    _client.connectionMessage = connMessage;

    try {
      setState(() {
        _connectionStatus = 'Connecting...';
      });
      await _client.connect();
    } catch (e) {
      print('Exception: $e');
      _disconnect();
    }
  }

  void _disconnect() {
    _client.disconnect();
    _onDisconnected();
  }

  void _onConnected() {
    setState(() {
      _connectionStatus = 'Connected to Adafruit IO';
    });
    print('MQTT Client Connected');
  }

  void _onDisconnected() {
    setState(() {
      _connectionStatus = 'Disconnected';
    });
    print('MQTT Client Disconnected');
  }

  // --- MQTT Publish Logic ---
  void _publishMessage(String message) {
    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client.publishMessage(ledControlFeed, MqttQos.atLeastOnce, builder.payload!);
      
      // Optimistically update the UI
      setState(() {
        _ledStatus = message;
      });

    } else {
      print('Cannot publish, client is not connected');
      _connect(); // Attempt to reconnect if disconnected
    }
  }
  
  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 MQTT Controller'),
        centerTitle: true,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Connection Status Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Broker Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _connectionStatus,
                        style: TextStyle(
                          color: _connectionStatus == 'Connected to Adafruit IO' ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // LED Status Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    'LED Status: ${_ledStatus.toUpperCase()}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    text: 'Turn ON',
                    color: Colors.green,
                    onPressed: () => _publishMessage('ON'),
                    icon: Icons.lightbulb,
                  ),
                  _buildControlButton(
                    text: 'Turn OFF',
                    color: Colors.red,
                    onPressed: () => _publishMessage('OFF'),
                    icon: Icons.lightbulb_outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(fontSize: 18, color: Colors.white)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
    );
  }
}


