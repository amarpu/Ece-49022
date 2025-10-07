import 'package:flutter/material.dart';
import 'package:aquarium_controller_app/models/fish_parameter.dart';

// A reusable widget for the colored status circles.
class StatusIndicator extends StatelessWidget {
  final ParameterStatus status;
  final double size;

  const StatusIndicator({super.key, required this.status, this.size = 12.0});

  Color _getColor(ParameterStatus status) {
    switch (status) {
      case ParameterStatus.good:
        return Colors.greenAccent.shade400;
      case ParameterStatus.adjusting:
        return Colors.yellowAccent.shade400;
      case ParameterStatus.highLow:
        return Colors.redAccent.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColor(status),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getColor(status).withOpacity(0.5),
            blurRadius: 4.0,
          ),
        ],
      ),
    );
  }
}
