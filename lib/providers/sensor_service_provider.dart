import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sensorServiceProvider =
    ChangeNotifierProvider<SensorServiceNotifier>((ref) {
  return SensorServiceNotifier();
});

class SensorServiceNotifier extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('com.example.movement_detection/sensor');
  static const EventChannel _eventChannel =
      EventChannel('com.example.movement_detection/sensorStream');

  String status = "Stationary";
  double x = 0.0, y = 0.0, z = 0.0;
  bool isSensorAvailable = false;

  SensorServiceNotifier() {
    _initializeSensor();
  }

  Future<void> _initializeSensor() async {
    try {
      final bool available =
          await _channel.invokeMethod('isAccelerometerAvailable');
      isSensorAvailable = available;
      notifyListeners();
    } on PlatformException catch (e) {
      log("Failed to get accelerometer availability: '${e.message}'.");
    }
  }

  void _listenToSensorStream() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      // Check if the event contains the new status
      if (event['status'] == "User has not moved for 2 minutes") {
        status = event['status'] as String;
        notifyListeners();
        return;
      }

      // Handle normal sensor data
      try {
        x = (event['x'] as num?)?.toDouble() ?? 0.0;
        y = (event['y'] as num?)?.toDouble() ?? 0.0;
        z = (event['z'] as num?)?.toDouble() ?? 0.0;
        status = event['status'] as String;
        notifyListeners();
      } catch (e) {
        log("Error parsing sensor event: $e");
      }
    });
  }

  Future<void> startMovementDetection() async {
    try {
      await _channel.invokeMethod('startMovementDetection');
      _listenToSensorStream();
    } on PlatformException catch (e) {
      log("Failed to start movement detection: '${e.message}'.");
    }
  }

  Future<void> stopMovementDetection() async {
    try {
      await _channel.invokeMethod('stopMovementDetection');
      _resetValues();
    } on PlatformException catch (e) {
      log("Failed to stop movement detection: '${e.message}'.");
    }
  }

  void _resetValues() {
    status = "Stationary";
    x = 0.0;
    y = 0.0;
    z = 0.0;
    notifyListeners();
  }
}
