import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aquarium_controller_app/models/fish_data.dart';
import 'package:aquarium_controller_app/models/fish_parameter.dart';
import 'package:aquarium_controller_app/services/mqtt_service.dart';
import 'package:aquarium_controller_app/widgets/status_indicator.dart';

class FishSettingsScreen extends StatelessWidget {
  final String fishId;
  const FishSettingsScreen({super.key, required this.fishId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$fishId Settings'),
        centerTitle: true,
      ),
      body: Consumer<MqttService>(
        builder: (context, mqttService, child) {
          final FishData? fish = mqttService.aquariumData[fishId];

          if (fish == null) {
            return Center(
              child: Text('Data for $fishId not found.', style: const TextStyle(color: Colors.white)),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildParameterControl(
                    context,
                    Icons.thermostat,
                    'Temp',
                    fish.temperature,
                    (newValue) {
                      // Publish a command to set the temperature.
                      mqttService.publishCommand({
                        'fish_id': fishId,
                        'command': 'set_temp',
                        'value': newValue,
                      });
                    },
                    isDecimal: true,
                    increment: 0.1,
                    unit: '°C',
                  ),
                  _buildParameterControl(
                    context,
                    Icons.opacity,
                    'pH',
                    fish.ph,
                    (newValue) {
                      // Publish a command to set the pH.
                      mqttService.publishCommand({
                        'fish_id': fishId,
                        'command': 'set_ph',
                        'value': newValue,
                      });
                    },
                    isDecimal: true,
                    increment: 0.01,
                    unit: '',
                  ),
                  _buildWaterPumpControl(
                    context,
                    Icons.water_drop,
                    'Water',
                    fish.waterLevel,
                    (isOn) {
                      // Publish a command to toggle the water pump/filter.
                      mqttService.publishCommand({
                        'fish_id': fishId,
                        'command': 'toggle_pump',
                        'value': isOn,
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildLegend(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // The 'Enter' button can simply navigate back.
                        // Commands are sent instantly when +/- or On/Off are pressed.
                        Navigator.of(context).pop();
                      },
                      child: const Text('Back to Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParameterControl(
      BuildContext context,
      IconData icon,
      String label,
      FishParameter parameter,
      Function(double) onValueChange, {
        bool isDecimal = false,
        double increment = 1.0,
        String unit = '',
      }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text('$label: ', style: const TextStyle(fontSize: 18, color: Colors.white)),
                Text(
                  isDecimal ? parameter.value.toStringAsFixed(2) : parameter.value.round().toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(' $unit', style: const TextStyle(fontSize: 18, color: Colors.white70)),
                const Spacer(),
                StatusIndicator(status: parameter.status, size: 14),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      double newValue = (parameter.value - increment);
                      onValueChange(newValue);
                    },
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('-', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 30),
                SizedBox(
                  width: 60,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      double newValue = (parameter.value + increment);
                      onValueChange(newValue);
                    },
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('+', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterPumpControl(
      BuildContext context,
      IconData icon,
      String label,
      FishParameter parameter,
      Function(bool) onToggle,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text('$label Level: ', style: const TextStyle(fontSize: 18, color: Colors.white)),
                Text(
                  '${parameter.value.toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                StatusIndicator(status: parameter.status, size: 14),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 150,
              height: 44,
              child: ElevatedButton.icon(
                icon: Icon(parameter.isOn ? Icons.power_settings_new : Icons.power_off_outlined),
                label: Text(parameter.isOn ? 'Pump ON' : 'Pump OFF'),
                onPressed: () => onToggle(!parameter.isOn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: parameter.isOn ? Colors.green.shade600 : Colors.red.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        _legendRow(ParameterStatus.good, 'Levels are good'),
        const SizedBox(height: 4),
        _legendRow(ParameterStatus.adjusting, 'Levels are adjusting'),
        const SizedBox(height: 4),
        _legendRow(ParameterStatus.highLow, 'Levels are too high/low'),
      ],
    );
  }

  Widget _legendRow(ParameterStatus status, String text) {
     return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatusIndicator(status: status),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
