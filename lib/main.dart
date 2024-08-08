import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/sensor_service_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MovementDetectionPage(),
    );
  }
}

class MovementDetectionPage extends ConsumerWidget {
  const MovementDetectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorService = ref.watch(sensorServiceProvider);

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
              Text(sensorService.isSensorAvailable
                  ? 'Accelerometer is available'
                  : 'Accelerometer is not available'),
              const SizedBox(height: 10),
              Text('Status: ${sensorService.status}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Alert: ${sensorService.alert}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              Text('X: ${sensorService.x.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 20)),
              Text('Y: ${sensorService.y.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 20)),
              Text('Z: ${sensorService.z.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await sensorService.startMovementDetection();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsetsDirectional.all(8),
                      child: const Center(
                        child: Text(
                          'Start',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await sensorService.stopMovementDetection();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsetsDirectional.all(8),
                      child: const Center(
                        child: Text(
                          'Stop',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await sensorService.resetAlert();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsetsDirectional.all(8),
                      child: const Center(
                        child: Text(
                          'Rest Alert',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
