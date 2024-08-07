import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SensorService {
  static const MethodChannel _channel =
      MethodChannel('com.example.movement_detection/sensor');
  static Function(double x, double y, double z, bool isMoving)?
      onMovementDetected;

  Future<bool> isAccelerometerAvailable() async {
    try {
      final bool isAvailable =
          await _channel.invokeMethod('isAccelerometerAvailable');
      return isAvailable;
    } on PlatformException catch (e) {
      log("Failed to get accelerometer availability: '${e.message}'.");
      return false;
    }
  }

  Future<void> startMovementDetection() async {
    try {
      await _channel.invokeMethod('startMovementDetection');
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onMovementDetected') {
          final Map<String, dynamic> data = call.arguments;
          final double x = data['x'].toDouble(); // Ensuring double type
          final double y = data['y'].toDouble(); // Ensuring double type
          final double z = data['z'].toDouble(); // Ensuring double type
          onMovementDetected?.call(x, y, z, true);
        } else if (call.method == 'onStationaryDetected') {
          onMovementDetected?.call(0, 0, 0, false);
        }
      });
    } on PlatformException catch (e) {
      log("Failed to start movement detection: '${e.message}'.");
    }
  }

  Future<void> stopMovementDetection() async {
    try {
      await _channel.invokeMethod('stopMovementDetection');
    } on PlatformException catch (e) {
      log("Failed to stop movement detection: '${e.message}'.");
    }
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MovementDetectionPage(),
    );
  }
}

class MovementDetectionPage extends StatefulWidget {
  const MovementDetectionPage({super.key});

  @override
  MovementDetectionPageState createState() => MovementDetectionPageState();
}

class MovementDetectionPageState extends State<MovementDetectionPage> {
  static const eventChannel =
      EventChannel('com.example.movement_detection/sensorStream');
  final SensorService _sensorService = SensorService();

  String status = "Stationary";
  double x = 0.0, y = 0.0, z = 0.0;
  String isSensorAvailable = 'No data';

  @override
  void initState() {
    super.initState();
    _sensorService.isAccelerometerAvailable().then((available) {
      setState(() {
        isSensorAvailable = available
            ? 'Accelerometer is available'
            : 'Accelerometer is not available';
      });
    });

    eventChannel.receiveBroadcastStream().listen((event) {
      setState(() {
        x = (event['x'] as num).toDouble(); // Ensuring double type
        y = (event['y'] as num).toDouble(); // Ensuring double type
        z = (event['z'] as num).toDouble(); // Ensuring double type
        status = event['status'] as String;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement Detection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isSensorAvailable),
              const SizedBox(height: 10),
              Text('Status: $status',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text('X: ${x.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 20)),
              Text('Y: ${y.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 20)),
              Text('Z: ${z.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
