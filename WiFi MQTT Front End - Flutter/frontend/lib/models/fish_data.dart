import 'package:aquarium_controller_app/models/fish_parameter.dart';

class FishData {
  String id; // e.g., "Fish 1"
  FishParameter temperature;
  FishParameter ph;
  FishParameter waterLevel;

  FishData({
    required this.id,
    required this.temperature,
    required this.ph,
    required this.waterLevel,
  });

  // Factory constructor to create FishData from a JSON map (e.g., from an MQTT message).
  factory FishData.fromJson(String id, Map<String, dynamic> json) {
    return FishData(
      id: id,
      temperature: FishParameter(
        value: (json['temp'] as num? ?? 0).toDouble(),
        status: _getStatus(json['temp_status'] as String? ?? 'good'),
      ),
      ph: FishParameter(
        value: (json['ph'] as num? ?? 0).toDouble(),
        status: _getStatus(json['ph_status'] as String? ?? 'good'),
      ),
      waterLevel: FishParameter(
        value: (json['water'] as num? ?? 0).toDouble(),
        status: _getStatus(json['water_status'] as String? ?? 'good'),
        isOn: json['water_on'] as bool? ?? false, // Control for water pump/filter
      ),
    );
  }

  // Helper method to convert a status string to an enum.
  static ParameterStatus _getStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'good':
        return ParameterStatus.good;
      case 'adjusting':
        return ParameterStatus.adjusting;
      case 'highlow':
        return ParameterStatus.highLow;
      default:
        return ParameterStatus.good;
    }
  }
}
