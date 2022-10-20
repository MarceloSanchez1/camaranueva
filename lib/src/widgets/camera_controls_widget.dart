import 'package:camerawesome/controllers/sensor_config.dart';
import 'package:camerawesome/src/builder/camera_widget_builder.dart';
import 'package:flutter/material.dart';

import '../controllers/camera_setup.dart';

class CameraControlsWidget extends StatelessWidget {
  final CameraSetup cameraSetup;
  final SensorConfig sensorConfig;
  final LineBuilder? top;
  final LineBuilder? middle;
  final LineBuilder? bottom;

  const CameraControlsWidget({
    super.key,
    required this.cameraSetup,
    required this.sensorConfig,
    this.top,
    this.middle,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (top != null) top!(cameraSetup, sensorConfig) else SizedBox(),
        if (middle != null) Expanded(child: middle!(cameraSetup, sensorConfig)),
        if (bottom != null) bottom!(cameraSetup, sensorConfig) else SizedBox(),
      ],
    );
  }
}