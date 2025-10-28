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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildParameterControl(
                    context,
                    mqttService,
                    Icons.thermostat,
                    'Temp',
                    fish.temperature,
                    // Temperature: only a plus button
                    onIncrease: () {
                      mqttService.setDisplayedTemp(fishId, fish.temperature.value + 0.3);
                      mqttService.publishHeaterControl(fishId, fish.temperature.value + 0.3);
                    },
                    isDecimal: true,
                    incrementLabel: '+0.3',
                    unit: '°C',
                  ),
                  _buildParameterControl(
                    context,
                    mqttService,
                    Icons.opacity,
                    'pH',
                    fish.ph,
                    onDecrease: () {
                      mqttService.setDisplayedPh(fishId, fish.ph.value - 0.1);
                      mqttService.publishPhControl(fishId, fish.ph.value - 0.1);
                    },
                    onIncrease: () {
                      mqttService.setDisplayedPh(fishId, fish.ph.value + 0.1);
                      mqttService.publishPhControl(fishId, fish.ph.value + 0.1);
                    },
                    isDecimal: true,
                    incrementLabel: '±0.1',
                    unit: '',
                  ),
                  _buildWaterPumpControl(
                    context,
                    Icons.water_drop,
                    'Water',
                    fish.waterLevel,
                    (isOn) {
                      // Publish a command to control the water pump using the new feed structure.
                      mqttService.publishPumpControl(fishId, isOn ? 1 : 0);
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildLegend(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
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
      MqttService mqttService,
      IconData icon,
      String label,
      FishParameter parameter, {
        VoidCallback? onDecrease,
        VoidCallback? onIncrease,
        bool isDecimal = false,
        String incrementLabel = '',
        String unit = '',
      }) {
    return Card(
      color: Colors.blue.shade600,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
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
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Actual: ', style: TextStyle(color: Colors.white70)),
                    Text(
                      isDecimal ? parameter.actualValue.toStringAsFixed(2) : parameter.actualValue.round().toString(),
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                    if (unit.isNotEmpty) Text(' $unit', style: const TextStyle(color: Colors.white38)),
                    const SizedBox(width: 16),
                    Text(incrementLabel, style: const TextStyle(color: Colors.white30)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => mqttService.syncDisplayedToActual((context.findAncestorWidgetOfExactType<FishSettingsScreen>() as FishSettingsScreen).fishId),
                      icon: const Icon(Icons.sync, size: 16, color: Colors.white70),
                      label: const Text('Sync to Actual', style: TextStyle(color: Colors.white70)),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onDecrease != null)
                  SizedBox(
                    width: 60,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onDecrease,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('-', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (onDecrease != null) const SizedBox(width: 30),
                if (onIncrease != null)
                  SizedBox(
                    width: 60,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onIncrease,
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
      color: Colors.blue.shade600,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text('$label Pump: ', style: const TextStyle(fontSize: 18, color: Colors.white)),
                Text(
                  parameter.isOn ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: parameter.isOn ? Colors.green.shade300 : Colors.red.shade300
                  ),
                ),
                const Spacer(),
                StatusIndicator(status: parameter.status, size: 14),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        _legendRow(ParameterStatus.good, 'Displayed matches actual (within 2%)'),
        const SizedBox(height: 4),
        _legendRow(ParameterStatus.adjusting, 'Displayed differs > 2% from actual'),
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
