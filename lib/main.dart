import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SensorService {
  static const MethodChannel _channel =
      MethodChannel('com.example.movement_detection/sensor');
  static Function(double x, double y, double z, double distance,
      double totalDistance, bool isMoving)? onMovementDetected;

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
          final double x = data['x'];
          final double y = data['y'];
          final double z = data['z'];
          final double distance = data['distance'];
          final double totalDistance = data['totalDistance'];
          onMovementDetected?.call(x, y, z, distance, totalDistance, true);
        } else if (call.method == 'onStationaryDetected') {
          onMovementDetected?.call(0, 0, 0, 0, 0, false);
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
  double distance = 0.0, totalDistance = 0.0;
  String isSensorAvailble = 'No data';

  @override
  void initState() {
    super.initState();
    eventChannel.receiveBroadcastStream().listen((event) {
      setState(() {
        x = event['x'];
        y = event['y'];
        z = event['z'];
        status = event['status'];
        distance = event['distance'];
        totalDistance = event['totalDistance'];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        isSensorAvailble = await _sensorService.isAccelerometerAvailable()
            ? 'Accelerometer is available'
            : 'Accelerometer is not available';
      });
    });

    SensorService.onMovementDetected = (double x, double y, double z,
        double distance, double totalDistance, bool isMoving) {
      setState(() {
        this.x = x;
        this.y = y;
        this.z = z;
        this.distance = distance;
        this.totalDistance = totalDistance;
        status = isMoving ? "Moving" : "Stationary";
      });
    };
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
              Text(isSensorAvailble),
              const SizedBox(height: 10),
              Text('Status: $status',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text('X: ${x.toDouble().toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 20)),
              Text('Y: ${y.toDouble().toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 20)),
              Text('Z: ${z.toDouble().toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Text('Distance: ${distance.toStringAsFixed(2)} meters',
                  style: const TextStyle(fontSize: 20)),
              Text('Total Distance: ${totalDistance.toStringAsFixed(2)} meters',
                  style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
