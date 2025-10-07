import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:aquarium_controller_app/models/fish_data.dart';
import 'package:aquarium_controller_app/models/fish_parameter.dart';

// --- Configuration for Adafruit IO MQTT Broker ---
const String aioServer = 'io.adafruit.com';
const String aioUsername = 'XiaohanYu1'; // Your Adafruit IO Username
const String aioKey = 'XWXt15dAr9qltpQ2kKaBtrBtW9Ff'; // Your Adafruit IO Key
const int aioPort = 1883;

// --- Adafruit IO Feed Names ---
// These are the names of the feeds you create in your Adafruit IO dashboard.
const String statusFeedName = 'aquarium-status';
const String commandFeedName = 'aquarium-command';

class MqttService with ChangeNotifier {
  MqttServerClient? _client;
  String _connectionStatus = 'Disconnected';
  String get connectionStatus => _connectionStatus;

  // Store data for all fish using a Map, with the fish ID as the key.
  final Map<String, FishData> _aquariumData = {};
  Map<String, FishData> get aquariumData => _aquariumData;

  // --- MQTT Topics for Adafruit IO ---
  // The topic path is always in the format: "username/feeds/feed_name"
  final String statusTopic = '$aioUsername/feeds/$statusFeedName';
  final String commandTopic = '$aioUsername/feeds/$commandFeedName';

  Future<void> connect() async {
    // Avoid reconnecting if already connected or connecting.
    if (_client != null &&
        (_client?.connectionStatus?.state == MqttConnectionState.connected ||
            _client?.connectionStatus?.state == MqttConnectionState.connecting)) {
      debugPrint('MQTT Client already connected or connecting.');
      return;
    }

    // Generate a unique client ID for Adafruit IO.
    final clientID = 'flutter-client-${Random().nextInt(100000)}';
    _client = MqttServerClient.withPort(aioServer, clientID, aioPort);
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.onConnected = onConnected;
    _client!.onDisconnected = onDisconnected;
    _client!.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientID)
        .startClean()
        .authenticateAs(aioUsername, aioKey);

    _client!.connectionMessage = connMessage;

    try {
      _connectionStatus = 'Connecting...';
      notifyListeners();
      await _client!.connect();
    } catch (e) {
      debugPrint('Exception: $e');
      _client!.disconnect();
    }
  }

  void disconnect() {
    _client?.disconnect();
  }

  // --- MQTT Callbacks ---
  void onConnected() {
    _connectionStatus = 'Connected to Adafruit IO';
    notifyListeners();
    debugPrint('MQTT Client Connected');

    // Subscribe to the status topic to receive updates from the ESP32.
    _client!.subscribe(statusTopic, MqttQos.atLeastOnce);

    // Set up the listener for incoming messages.
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String topic = c[0].topic;
      final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      debugPrint('Received message: topic=$topic, payload=$payload');
      _processMqttMessage(topic, payload);
    });

    // Load initial dummy data for UI testing. This will be replaced by real data from ESP32.
    _loadInitialDummyData();
  }

  void onDisconnected() {
    _connectionStatus = 'Disconnected';
    notifyListeners();
    debugPrint('MQTT Client Disconnected');
  }

  void onSubscribed(String topic) {
    debugPrint('Subscribed to topic: $topic');
  }

  // --- Message Processing ---
  void _processMqttMessage(String topic, String payload) {
    // Ensure the message is from our status topic.
    if (topic != statusTopic) return;

    try {
      // The ESP32 can send data for one fish at a time or an array of fish.
      // We will handle both cases.
      final dynamic decodedPayload = jsonDecode(payload);
      
      if (decodedPayload is List) {
        // Handle an array of fish data objects
        for (var fishJson in decodedPayload) {
          _updateOrAddFish(fishJson);
        }
      } else if (decodedPayload is Map<String, dynamic>) {
        // Handle a single fish data object
        _updateOrAddFish(decodedPayload);
      }

      notifyListeners(); // Notify the UI that data has changed.
    } catch (e) {
      debugPrint('Error processing MQTT message: $e, payload: $payload');
    }
  }

  void _updateOrAddFish(Map<String, dynamic> fishJson) {
      String fishId = fishJson['id'];
      _aquariumData[fishId] = FishData.fromJson(fishId, fishJson);
  }


  // --- Publishing Commands ---
  void publishCommand(Map<String, dynamic> commandPayload) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(commandPayload));
      _client!.publishMessage(commandTopic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Published command to $commandTopic: $commandPayload');
    } else {
      debugPrint('Cannot publish, MQTT client not connected.');
      connect(); // Attempt to reconnect.
    }
  }

  // --- For UI Development & Testing ---
  void _loadInitialDummyData() {
    _aquariumData['Fish 1'] = FishData(
      id: 'Fish 1',
      temperature: FishParameter(value: 27.12, status: ParameterStatus.good),
      ph: FishParameter(value: 7.57, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 94.09, status: ParameterStatus.good, isOn: true),
    );
    _aquariumData['Fish 2'] = FishData(
      id: 'Fish 2',
      temperature: FishParameter(value: 23.72, status: ParameterStatus.good),
      ph: FishParameter(value: 7.34, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 88.24, status: ParameterStatus.good, isOn: false),
    );
    _aquariumData['Fish 3'] = FishData(
      id: 'Fish 3',
      temperature: FishParameter(value: 25.50, status: ParameterStatus.good),
      ph: FishParameter(value: 6.67, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 91.90, status: ParameterStatus.good, isOn: true),
    );
    _aquariumData['Fish 4'] = FishData(
      id: 'Fish 4',
      temperature: FishParameter(value: 25.50, status: ParameterStatus.good),
      ph: FishParameter(value: 6.67, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 91.90, status: ParameterStatus.good, isOn: true),
    );
    notifyListeners();
  }
}
