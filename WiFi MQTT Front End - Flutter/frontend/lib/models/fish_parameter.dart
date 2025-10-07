// Enum to represent the status of a parameter.
enum ParameterStatus { good, adjusting, highLow }

class FishParameter {
  double value;
  ParameterStatus status;
  bool isOn; // For toggle controls like a water pump.

  FishParameter({required this.value, this.status = ParameterStatus.good, this.isOn = false});
}
