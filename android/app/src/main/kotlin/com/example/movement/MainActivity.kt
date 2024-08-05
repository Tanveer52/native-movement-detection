package com.example.movement

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.movement_detection/sensor"
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var accelerometerListener: SensorEventListener? = null

    private val alpha = 0.8f // Low-pass filter constant
    private var gravity = FloatArray(3) { 0f }
    private val stepSize = 0.2f // Step size for significant change detection
    private var lastValues = FloatArray(3) { 0f }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccelerometerAvailable" -> {
                    val isAvailable = isAccelerometerAvailable()
                    Log.d("MainActivity", "isAccelerometerAvailable: $isAvailable")
                    result.success(isAvailable)
                }
                "startMovementDetection" -> {
                    Log.d("MainActivity", "startMovementDetection called")
                    startMovementDetection()
                    result.success(null)
                }
                "stopMovementDetection" -> {
                    Log.d("MainActivity", "stopMovementDetection called")
                    stopMovementDetection()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccelerometerAvailable(): Boolean {
        return accelerometer != null
    }

    private fun startMovementDetection() {
        if (accelerometer != null && accelerometerListener == null) {
            accelerometerListener = object : SensorEventListener {
                override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}

                override fun onSensorChanged(event: SensorEvent) {
                    val filteredValues = lowPassFilter(event.values.clone(), gravity)
                    val x = filteredValues[0]
                    val y = filteredValues[1]
                    val z = filteredValues[2]

                    if (isSignificantMovement(x, y, z)) {
                        Log.d("MainActivity", "Significant movement detected - x: $x, y: $y, z: $z")

                        // Process the movement data as needed
                        // For example, you can send the data back to Flutter:
                        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                            .invokeMethod("onMovementDetected", mapOf("x" to x, "y" to y, "z" to z))
                    } else {
                        Log.d("MainActivity", "No significant movement")
                    }
                }
            }
            sensorManager.registerListener(accelerometerListener, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)
            Log.d("MainActivity", "Accelerometer listener registered")
        } else {
            Log.d("MainActivity", "Accelerometer not available or listener already registered")
        }
    }

    private fun stopMovementDetection() {
        if (accelerometerListener != null) {
            sensorManager.unregisterListener(accelerometerListener)
            Log.d("MainActivity", "Accelerometer listener unregistered")
            accelerometerListener = null
        } else {
            Log.d("MainActivity", "No accelerometer listener to unregister")
        }
    }

    private fun lowPassFilter(input: FloatArray, output: FloatArray): FloatArray {
        for (i in input.indices) {
            output[i] = alpha * output[i] + (1 - alpha) * input[i]
        }
        return output
    }

    private fun isSignificantMovement(x: Float, y: Float, z: Float): Boolean {
        val deltaX = Math.abs(x - lastValues[0])
        val deltaY = Math.abs(y - lastValues[1])
        val deltaZ = Math.abs(z - lastValues[2])

        val isSignificant = deltaX > stepSize || deltaY > stepSize || deltaZ > stepSize

        if (isSignificant) {
            lastValues[0] = x
            lastValues[1] = y
            lastValues[2] = z
        }

        return isSignificant
    }
}