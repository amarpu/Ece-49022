import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aquarium_controller_app/models/fish_data.dart';
import 'package:aquarium_controller_app/models/fish_parameter.dart';
import 'package:aquarium_controller_app/services/mqtt_service.dart';
import 'package:aquarium_controller_app/screens/fish_settings_screen.dart';
import 'package:aquarium_controller_app/widgets/status_indicator.dart';

class AquariumDashboardScreen extends StatelessWidget {
  const AquariumDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aquarium Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Removes the back button
      ),
      body: Consumer<MqttService>(
        builder: (context, mqttService, child) {
          final List<FishData> fishList =
              mqttService.aquariumData.values.toList()
                ..sort((a, b) => a.id.compareTo(b.id)); // Sort by Fish ID

          return Column(
            children: [
              _buildWaterQualityIndicators(),
              Expanded(
                child: fishList.isEmpty
                    ? const Center(
                        child: Text(
                          'No fish data received yet.\nWaiting for ESP32...',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    // FIX: Adjusted padding to give a good centered look
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60.0),
                        child: GridView.builder(
                          padding: const EdgeInsets.only(top: 12.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 1.0,
                            mainAxisSpacing: 1.0,
                            // FIX: Increased aspect ratio significantly. This makes the cards
                            // much wider than they are tall, effectively shrinking their height.
                            childAspectRatio: 2.0,
                          ),
                          itemCount: fishList.length,
                          itemBuilder: (context, index) {
                            final fish = fishList[index];
                            return _buildFishCard(context, fish);
                          },
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    mqttService.connect();
                  },
                  child: const Text('Refresh Fish Values'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWaterQualityIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Water Quality: ',
              style: TextStyle(color: Colors.white, fontSize: 20)),
          _buildQualityItem('Ammonium', ParameterStatus.highLow),
          const SizedBox(width: 15),
          _buildQualityItem('Nitrate', ParameterStatus.adjusting),
          const SizedBox(width: 15),
          _buildQualityItem('Nitrite', ParameterStatus.good),
        ],
      ),
    );
  }

  Widget _buildQualityItem(String label, ParameterStatus status) {
    return Row(
      children: [
        StatusIndicator(status: status, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildFishCard(BuildContext context, FishData fish) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FishSettingsScreen(fishId: fish.id),
          ),
        );
      },
      child: Card(
        color: Colors.blue.shade700,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fish.id,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white54, height: 8),
              _buildParameterRow(
                  Icons.thermostat,
                  'Temp',
                  '${fish.temperature.value.toStringAsFixed(2)}°',
                  fish.temperature.status),
              _buildParameterRow(Icons.opacity, 'pH',
                  fish.ph.value.toStringAsFixed(2), fish.ph.status),
              _buildParameterRow(
                  Icons.water_drop,
                  'Water',
                  '${fish.waterLevel.value.toStringAsFixed(2)}%',
                  fish.waterLevel.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterRow(
      IconData icon, String label, String value, ParameterStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 5),
          Text('$label: ',
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusIndicator(status: status, size: 8),
        ],
      ),
    );
  }
}

