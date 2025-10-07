// Enum to represent the status of a parameter.
enum ParameterStatus { good, adjusting, highLow }

class FishParameter {
  // Displayed or target value shown in the UI
  double value;
  // Actual value reported from the device via MQTT
  double actualValue;
  ParameterStatus status;
  bool isOn; // For toggle controls like a water pump.

  FishParameter({
    required this.value,
    this.actualValue = 0.0,
    this.status = ParameterStatus.good,
    this.isOn = false,
  });
}
