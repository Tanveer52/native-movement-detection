import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class SensorService {
  static const MethodChannel _channel =
      MethodChannel('com.example.movement_detection/sensor');

  Future<bool> isAccelerometerAvailable() async {
    try {
      final bool isAvailable =
          await _channel.invokeMethod('isAccelerometerAvailable');
      return isAvailable;
    } on PlatformException catch (e) {
      print("Failed to get accelerometer availability: '${e.message}'.");
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
          // Handle movement data
          print('Movement detected: x=$x, y=$y, z=$z');
        }
      });
    } on PlatformException catch (e) {
      print("Failed to start movement detection: '${e.message}'.");
    }
  }

  Future<void> stopMovementDetection() async {
    try {
      await _channel.invokeMethod('stopMovementDetection');
    } on PlatformException catch (e) {
      print("Failed to stop movement detection: '${e.message}'.");
    }
  }
}

class MyHomePage extends StatelessWidget {
  final SensorService _sensorService = SensorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Availability'),
      ),
      body: Center(
        child: FutureBuilder<bool>(
          future: _sensorService.isAccelerometerAvailable(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(snapshot.data == true
                      ? 'Accelerometer is available'
                      : 'Accelerometer is not available'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _sensorService.startMovementDetection();
                    },
                    child: Text('Start Movement Detection'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _sensorService.stopMovementDetection();
                    },
                    child: Text('Stop Movement Detection'),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
