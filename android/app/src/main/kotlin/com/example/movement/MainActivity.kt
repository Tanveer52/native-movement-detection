package com.example.movement

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.pow
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.movement_detection/sensor"
    private val EVENT_CHANNEL = "com.example.movement_detection/sensorStream"
    
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var accelerometerListener: SensorEventListener? = null

    private val alpha = 0.8f // Low-pass filter constant
    private var gravity = FloatArray(3) { 0f }
    private val stepSize = 0.2f // Step size for significant change detection
    private var lastValues = FloatArray(3) { 0f }
    private var eventSink: EventChannel.EventSink? = null
    private var totalDistance = 0.0
    private var initialized = false

    private val movementThreshold = 0.01 // Threshold for considering a change significant

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        // Set up MethodChannel
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

        // Set up EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startMovementDetection()
                }

                override fun onCancel(arguments: Any?) {
                    stopMovementDetection()
                }
            }
        )
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

                    if (!initialized) {
                        lastValues[0] = x
                        lastValues[1] = y
                        lastValues[2] = z
                        initialized = true
                        return
                    }

                    val deltaX = Math.abs(x - lastValues[0])
                    val deltaY = Math.abs(y - lastValues[1])
                    val deltaZ = Math.abs(z - lastValues[2])

                    if (deltaX > movementThreshold || deltaY > movementThreshold || deltaZ > movementThreshold) {
                        val distance = calculateDistance(x, y, z, lastValues[0], lastValues[1], lastValues[2])
                        if (distance >= 0.75) {
                            totalDistance += distance
                            Log.d("MainActivity", "Significant movement detected - x: $x, y: $y, z: $z, distance: $distance")

                            // Send data through MethodChannel (if needed)
                            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                                .invokeMethod("onMovementDetected", mapOf("x" to x, "y" to y, "z" to z, "distance" to distance, "totalDistance" to totalDistance))

                            // Send data through EventChannel
                            eventSink?.success(mapOf("x" to x, "y" to y, "z" to z, "distance" to distance, "totalDistance" to totalDistance, "status" to "Moving"))

                            // Update last values
                            lastValues[0] = x
                            lastValues[1] = y
                            lastValues[2] = z
                        } else {
                            // Send data through EventChannel
                            eventSink?.success(mapOf("x" to x, "y" to y, "z" to z, "distance" to distance, "totalDistance" to totalDistance, "status" to "Stationary"))
                            Log.d("MainActivity", "No significant movement")
                        }
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
        eventSink = null
    }

    private fun lowPassFilter(input: FloatArray, output: FloatArray): FloatArray {
        for (i in input.indices) {
            output[i] = alpha * output[i] + (1 - alpha) * input[i]
        }
        return output
    }

    private fun calculateDistance(x1: Float, y1: Float, z1: Float, x2: Float, y2: Float, z2: Float): Double {
        return sqrt((x2 - x1).toDouble().pow(2) + (y2 - y1).toDouble().pow(2) + (z2 - z1).toDouble().pow(2))
    }
}
