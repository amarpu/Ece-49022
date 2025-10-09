import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:aquarium_controller_app/models/fish_data.dart';
import 'package:aquarium_controller_app/models/fish_parameter.dart';

// Configuration for Adafruit IO MQTT Broker 
const String aioServer = 'io.adafruit.com';
const String aioUsername = 'XiaohanYu1'; // Your Adafruit IO Username
const String aioKey = 'xxxxxxxxxxxxxxxxx'; // Your Adafruit IO Key
const int aioPort = 1883;

// Control Feeds (App → ESP32)
const String heaterControlFeedName = 'HEATER_CTRL';
const String phControlFeedName = 'PH_CTRL';
const String pumpControlFeedName = 'PUMP_CTRL';

// Monitoring Feeds (ESP32 → App)
const String temperatureSensorFeedName = 'TEMP_SENSOR';
const String phSensorFeedName = 'PH_SENSOR';
const String systemStatusFeedName = 'SYS_STATUS';

// Legacy feeds (keeping for backward compatibility)
const String statusFeedName = 'aquarium-status';
const String commandFeedName = 'aquarium-command';

class MqttService with ChangeNotifier {
  MqttServerClient? _client;
  String _connectionStatus = 'Disconnected';
  String get connectionStatus => _connectionStatus;

  // Store data for all fish using a Map, with the fish ID as the key.
  final Map<String, FishData> _aquariumData = {};
  Map<String, FishData> get aquariumData => _aquariumData;
  
  // Control Topics (App → ESP32)
  final String heaterControlTopic = '$aioUsername/feeds/$heaterControlFeedName';
  final String phControlTopic = '$aioUsername/feeds/$phControlFeedName';
  final String pumpControlTopic = '$aioUsername/feeds/$pumpControlFeedName';
  
  // Monitoring Topics (ESP32 → App)
  final String temperatureSensorTopic = '$aioUsername/feeds/$temperatureSensorFeedName';
  final String phSensorTopic = '$aioUsername/feeds/$phSensorFeedName';
  final String systemStatusTopic = '$aioUsername/feeds/$systemStatusFeedName';
  
  // Legacy topics (keeping for backward compatibility)
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

  // MQTT Callbacks 
  void onConnected() {
    _connectionStatus = 'Connected to Adafruit IO';
    notifyListeners();
    debugPrint('MQTT Client Connected');

    // Subscribe to all monitoring topics to receive updates from the ESP32.
    _client!.subscribe(temperatureSensorTopic, MqttQos.atLeastOnce);
    _client!.subscribe(phSensorTopic, MqttQos.atLeastOnce);
    _client!.subscribe(systemStatusTopic, MqttQos.atLeastOnce);
    
    // Also subscribe to legacy topic for backward compatibility
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
    debugPrint('Processing message from topic: $topic');
    
    try {
      if (topic == temperatureSensorTopic) {
        _processTemperatureSensorMessage(payload);
      } else if (topic == phSensorTopic) {
        _processPhSensorMessage(payload);
      } else if (topic == systemStatusTopic) {
        _processSystemStatusMessage(payload);
      } else if (topic == statusTopic) {
        // Legacy support for aquarium-status topic
        _processLegacyStatusMessage(payload);
      } else {
        debugPrint('Unknown topic: $topic');
        return;
      }
      
      notifyListeners(); // Notify the UI that data has changed.
    } catch (e) {
      debugPrint('Error processing MQTT message: $e, payload: $payload');
    }
  }
  
  // Process temperature sensor data
  void _processTemperatureSensorMessage(String payload) {
    try {
      final dynamic data = jsonDecode(payload);
      if (data is Map<String, dynamic>) {
        final String fishId = data['fish_id'] ?? 'Unknown';
        final double temperature = (data['temperature'] as num? ?? 0).toDouble();
        // final String timestamp = data['timestamp'] ?? DateTime.now().toIso8601String();
        
        debugPrint('Temperature update for $fishId: ${temperature}°C');
        _updateFishTemperature(fishId, temperature);
      } else {
        // Handle simple numeric value
        final double temperature = (data as num).toDouble();
        debugPrint('Global temperature update: ${temperature}°C');
        _updateAllFishTemperature(temperature);
      }
    } catch (e) {
      debugPrint('Error processing temperature sensor message: $e');
    }
  }
  
  // Process pH sensor data
  void _processPhSensorMessage(String payload) {
    try {
      final dynamic data = jsonDecode(payload);
      if (data is Map<String, dynamic>) {
        final String fishId = data['fish_id'] ?? 'Unknown';
        final double ph = (data['ph'] as num? ?? 0).toDouble();
        // final String timestamp = data['timestamp'] ?? DateTime.now().toIso8601String();
        
        debugPrint('pH update for $fishId: $ph');
        _updateFishPh(fishId, ph);
      } else {
        // Handle simple numeric value
        final double ph = (data as num).toDouble();
        debugPrint('Global pH update: $ph');
        _updateAllFishPh(ph);
      }
    } catch (e) {
      debugPrint('Error processing pH sensor message: $e');
    }
  }
  
  // Process system status data
  void _processSystemStatusMessage(String payload) {
    try {
      final dynamic data = jsonDecode(payload);
      if (data is Map<String, dynamic>) {
        final String fishId = data['fish_id'] ?? 'Unknown';
        final String status = data['status'] ?? '';
        final bool pumpOn = data['pump_on'] as bool? ?? false;
        final String message = data['message'] ?? '';
        // final String timestamp = data['timestamp'] ?? DateTime.now().toIso8601String();
        
        debugPrint('System status for $fishId: $status, Pump: ${pumpOn ? 'ON' : 'OFF'}, Message: $message');
        _updateFishSystemStatus(fishId, pumpOn, status, message);
      }
    } catch (e) {
      debugPrint('Error processing system status message: $e');
    }
  }
  
  // Legacy support for aquarium-status topic
  void _processLegacyStatusMessage(String payload) {
    final dynamic decodedPayload = jsonDecode(payload);
    
    if (decodedPayload is List) {
      // Handle an array of fish data objects
      for (var fishJson in decodedPayload) {
        _upsertFishFromDevice(fishJson);
      }
    } else if (decodedPayload is Map<String, dynamic>) {
      // Handle a single fish data object
      _upsertFishFromDevice(decodedPayload);
    }
  }

  void _upsertFishFromDevice(Map<String, dynamic> fishJson) {
    final String fishId = fishJson['id'];
    final double tempActual = (fishJson['temp'] as num? ?? 0).toDouble();
    final double phActual = (fishJson['ph'] as num? ?? 0).toDouble();
    final double waterActual = (fishJson['water'] as num? ?? 0).toDouble();
    final bool waterOn = fishJson['water_on'] as bool? ?? false;

    if (_aquariumData.containsKey(fishId)) {
      final fish = _aquariumData[fishId]!;
      fish.temperature.actualValue = tempActual;
      fish.ph.actualValue = phActual;
      fish.waterLevel.actualValue = waterActual;
      fish.waterLevel.isOn = waterOn;

      // Recompute statuses based on 2% rule comparing displayed value vs actual value
      fish.temperature.status = _statusByTolerance(fish.temperature.value, fish.temperature.actualValue);
      fish.ph.status = _statusByTolerance(fish.ph.value, fish.ph.actualValue);
      fish.waterLevel.status = _statusByTolerance(fish.waterLevel.value, fish.waterLevel.actualValue);
    } else {
      // New fish entry: create with displayed values equal to actuals
      _aquariumData[fishId] = FishData(
        id: fishId,
        temperature: FishParameter(value: tempActual, actualValue: tempActual),
        ph: FishParameter(value: phActual, actualValue: phActual),
        waterLevel: FishParameter(value: waterActual, actualValue: waterActual, isOn: waterOn),
      );
    }
  }

  ParameterStatus _statusByTolerance(double displayed, double actual) {
    if (displayed == 0) {
      return ParameterStatus.adjusting;
    }
    final double diff = (displayed - actual).abs() / displayed;
    return diff > 0.02 ? ParameterStatus.adjusting : ParameterStatus.good;
  }
  
  // Helper methods for updating individual fish data
  void _updateFishTemperature(String fishId, double temperature) {
    if (_aquariumData.containsKey(fishId)) {
      final fish = _aquariumData[fishId]!;
      fish.temperature.actualValue = temperature;
      fish.temperature.status = _statusByTolerance(fish.temperature.value, fish.temperature.actualValue);
    } else {
      // Create new fish entry if it doesn't exist
      _aquariumData[fishId] = FishData(
        id: fishId,
        temperature: FishParameter(value: temperature, actualValue: temperature),
        ph: FishParameter(value: 7.0, actualValue: 7.0),
        waterLevel: FishParameter(value: 50.0, actualValue: 50.0),
      );
    }
  }
  
  void _updateFishPh(String fishId, double ph) {
    if (_aquariumData.containsKey(fishId)) {
      final fish = _aquariumData[fishId]!;
      fish.ph.actualValue = ph;
      fish.ph.status = _statusByTolerance(fish.ph.value, fish.ph.actualValue);
    } else {
      // Create new fish entry if it doesn't exist
      _aquariumData[fishId] = FishData(
        id: fishId,
        temperature: FishParameter(value: 25.0, actualValue: 25.0),
        ph: FishParameter(value: ph, actualValue: ph),
        waterLevel: FishParameter(value: 50.0, actualValue: 50.0),
      );
    }
  }
  
  void _updateFishSystemStatus(String fishId, bool pumpOn, String status, String message) {
    if (_aquariumData.containsKey(fishId)) {
      final fish = _aquariumData[fishId]!;
      fish.waterLevel.isOn = pumpOn;
      // You could add more status fields to FishData if needed
    }
  }
  
  void _updateAllFishTemperature(double temperature) {
    for (var fish in _aquariumData.values) {
      fish.temperature.actualValue = temperature;
      fish.temperature.status = _statusByTolerance(fish.temperature.value, fish.temperature.actualValue);
    }
  }
  
  void _updateAllFishPh(double ph) {
    for (var fish in _aquariumData.values) {
      fish.ph.actualValue = ph;
      fish.ph.status = _statusByTolerance(fish.ph.value, fish.ph.actualValue);
    }
  }

  // --- Publishing Commands ---
  
  // New specific control methods
  void publishHeaterControl(String fishId, String command) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final Map<String, dynamic> payload = {
        'fish_id': fishId,
        'command': command,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(payload));
      _client!.publishMessage(heaterControlTopic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Published heater control to $heaterControlTopic: $payload');
    } else {
      debugPrint('Cannot publish, MQTT client not connected.');
      connect(); // Attempt to reconnect.
    }
  }
  
  void publishPhControl(String fishId, String command, {int? durationSeconds}) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final Map<String, dynamic> payload = {
        'fish_id': fishId,
        'command': command,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (durationSeconds != null) {
        payload['duration_seconds'] = durationSeconds;
      }
      
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(payload));
      _client!.publishMessage(phControlTopic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Published pH control to $phControlTopic: $payload');
    } else {
      debugPrint('Cannot publish, MQTT client not connected.');
      connect(); // Attempt to reconnect.
    }
  }
  
  void publishPumpControl(String fishId, int state) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final Map<String, dynamic> payload = {
        'fish_id': fishId,
        'state': state, // 1 for ON, 0 for OFF
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(payload));
      _client!.publishMessage(pumpControlTopic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Published pump control to $pumpControlTopic: $payload');
    } else {
      debugPrint('Cannot publish, MQTT client not connected.');
      connect(); // Attempt to reconnect.
    }
  }
  
  // Legacy method (keeping for backward compatibility)
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

  // Helpers to update displayed values from UI
  void setDisplayedTemp(String fishId, double newValue) {
    final fish = _aquariumData[fishId];
    if (fish == null) return;
    fish.temperature.value = newValue;
    fish.temperature.status = _statusByTolerance(newValue, fish.temperature.actualValue);
    notifyListeners();
  }

  void setDisplayedPh(String fishId, double newValue) {
    final fish = _aquariumData[fishId];
    if (fish == null) return;
    fish.ph.value = newValue;
    fish.ph.status = _statusByTolerance(newValue, fish.ph.actualValue);
    notifyListeners();
  }

  void setDisplayedWater(String fishId, double newValue) {
    final fish = _aquariumData[fishId];
    if (fish == null) return;
    fish.waterLevel.value = newValue;
    fish.waterLevel.status = _statusByTolerance(newValue, fish.waterLevel.actualValue);
    notifyListeners();
  }

  // Sync displayed values to match actuals
  void syncDisplayedToActual(String fishId) {
    final fish = _aquariumData[fishId];
    if (fish == null) return;
    fish.temperature.value = fish.temperature.actualValue;
    fish.ph.value = fish.ph.actualValue;
    fish.waterLevel.value = fish.waterLevel.actualValue;
    fish.temperature.status = _statusByTolerance(fish.temperature.value, fish.temperature.actualValue);
    fish.ph.status = _statusByTolerance(fish.ph.value, fish.ph.actualValue);
    fish.waterLevel.status = _statusByTolerance(fish.waterLevel.value, fish.waterLevel.actualValue);
    notifyListeners();
  }

// --- For UI Development & Testing ---
void _loadInitialDummyData() {
    _aquariumData['Neon Tetra'] = FishData(
      id: 'Neon Tetra',
      temperature: FishParameter(value: 23.5, actualValue: 23.5, status: ParameterStatus.good),
      ph: FishParameter(value: 6.5, actualValue: 6.5, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 85.00, actualValue: 85.02, status: ParameterStatus.good, isOn: false),
    );
    _aquariumData['Betta'] = FishData(
      id: 'Betta',
      temperature: FishParameter(value: 26.0, actualValue: 26.0, status: ParameterStatus.good),
      ph: FishParameter(value: 7.0, actualValue: 7.0, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 88.24, actualValue: 88.24, status: ParameterStatus.good, isOn: false),
    );
    _aquariumData['Guppy'] = FishData(
      id: 'Guppy',
      temperature: FishParameter(value: 25.0, actualValue: 25.0, status: ParameterStatus.good),
      ph: FishParameter(value: 7.2, actualValue: 7.2, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 91.90, actualValue: 91.90, status: ParameterStatus.good, isOn: false),
    );
    _aquariumData['Goldfish'] = FishData(
      id: 'Goldfish',
      temperature: FishParameter(value: 22.0, actualValue: 22.0, status: ParameterStatus.good),
      ph: FishParameter(value: 7.5, actualValue: 7.5, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 96.40, actualValue: 96.40, status: ParameterStatus.good, isOn: false),
    );
    _aquariumData['Molly'] = FishData(
      id: 'Molly',
      temperature: FishParameter(value: 25.5, actualValue: 25.5, status: ParameterStatus.good),
      ph: FishParameter(value: 8.0, actualValue: 8.0, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 98.23, actualValue: 98.23, status: ParameterStatus.good, isOn: false),
    );
    _aquariumData['Platy'] = FishData(
      id: 'Platy',
      temperature: FishParameter(value: 24.0, actualValue: 24.0, status: ParameterStatus.good),
      ph: FishParameter(value: 7.8, actualValue: 7.8, status: ParameterStatus.good),
      waterLevel: FishParameter(value: 94.26, actualValue: 94.26, status: ParameterStatus.good, isOn: false),
    );
    notifyListeners();
  }
}