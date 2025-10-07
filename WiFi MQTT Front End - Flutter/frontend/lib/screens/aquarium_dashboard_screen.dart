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
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Constrain content to a pleasant max width and center
                          final double maxContentWidth = 1000;
                          final double contentWidth = constraints.maxWidth > maxContentWidth
                              ? maxContentWidth
                              : constraints.maxWidth;

                          // Cap at 3 columns on wide screens
                          int crossAxisCount = 1;
                          if (contentWidth >= 740) {
                            crossAxisCount = 3;
                          } else if (contentWidth >= 520) {
                            crossAxisCount = 2;
                          }

                          return Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: contentWidth,
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16.0,
                                  mainAxisSpacing: 16.0,
                                  // Make cards square
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: fishList.length,
                                itemBuilder: (context, index) {
                                  final fish = fishList[index];
                                  return _buildFishCard(context, fish);
                                },
                              ),
                            ),
                          );
                        },
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
              style: TextStyle(color: Colors.white, fontSize: 22)),
          _buildQualityItem('Ammonium', ParameterStatus.good),
          const SizedBox(width: 15),
          _buildQualityItem('Nitrate', ParameterStatus.good),
          const SizedBox(width: 15),
          _buildQualityItem('Nitrite', ParameterStatus.good),
        ],
      ),
    );
  }

  Widget _buildQualityItem(String label, ParameterStatus status) {
    return Row(
      children: [
        StatusIndicator(status: status, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
        color: Colors.blue.shade600, // lighter than previous shade
        elevation: 6, // subtle shadow
        shadowColor: Colors.black.withOpacity(0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fish.id,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white54, height: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusIndicator(status: status, size: 10),
        ],
      ),
    );
  }
}

