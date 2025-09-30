import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For json decoding

 // IF THIS DOESN'T WORK, LET LUCAS KNOW

void main() {
  runApp(const ESP32ControlApp());

}

class ESP32ControlApp extends StatelessWidget {
  const ESP32ControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Controller',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ControlScreen(),
    );
  }
}

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final TextEditingController _ipController = TextEditingController();
  String _ledStatus = 'Unknown';
  String _feedbackMessage = 'Enter ESP32 IP Address: ';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // You can set a default IP for faster testing if you know it
    // _ipController.text = '192.168.1.123';
  }

  // Generic function to send HTTP GET requests
  Future<void> _sendRequest(String endpoint) async {
    if (_ipController.text.isEmpty) {
      setState(() {
        _feedbackMessage = 'Error: IP Address cannot be empty!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _feedbackMessage = 'Sending command...';
    });

    try {
      final url = Uri.http(_ipController.text, endpoint);
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // If the server returns a JSON response for the status endpoint
        if (endpoint == '/status') {
          final decoded = json.decode(response.body);
          setState(() {
            _ledStatus = decoded['status'] ?? 'Error';
            _feedbackMessage = 'Status updated successfully!';
          });
        } else {
          setState(() {
            _feedbackMessage = response.body;
          });
          // After turning LED on/off, refresh the status
          await _sendRequest('/status');
        }
      } else {
        setState(() {
          _feedbackMessage = 'Error: ${response.statusCode} - ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Error: Could not connect. Check IP and network.';
      });
    } finally {
       setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 WiFi Controller'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IP Address Input
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'ESP32 IP Address',
                  hintText: 'e.g., 192.168.1.100',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),

              // LED Status Display
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('LED Status: ', style: TextStyle(fontSize: 18)),
                      Text(
                        _ledStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _ledStatus == 'on' ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Refresh Button
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Get Status'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _isLoading ? null : () => _sendRequest('/status'),
              ),
              const SizedBox(height: 30),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lightbulb),
                    label: const Text('Turn ON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    onPressed: _isLoading ? null : () => _sendRequest('/led_on'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Turn OFF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    onPressed: _isLoading ? null : () => _sendRequest('/led_off'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Feedback Section
              if (_isLoading) const Center(child: CircularProgressIndicator()),
              if (!_isLoading)
                Text(
                  _feedbackMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
