import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // optional: extra debug logs
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 BLE Scanner (Filtered)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ScanPage(),
    );
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;

  // Track connection states
  final Map<DeviceIdentifier, BluetoothConnectionState> connectionStates = {};

  @override
  void initState() {
    super.initState();

    // Listen for scan results
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() => scanResults = results);

      // Debug log
      for (var r in results) {
        debugPrint(
            'Found device: ${r.advertisementData.localName.isNotEmpty ? r.advertisementData.localName : "Unknown"} '
            '(${r.device.remoteId}), rssi: ${r.rssi}');
      }
    });

    // Listen to scanning state
    _isScanningSub = FlutterBluePlus.isScanning.listen((s) {
      if (!mounted) return;
      setState(() => isScanning = s);
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    super.dispose();
  }

  Future<void> startScan() async {
    final supported = await FlutterBluePlus.isSupported;
    if (supported == false) {
      debugPrint('❌ Bluetooth not supported on this device');
      return;
    }

    debugPrint('🔍 Starting unfiltered scan...');
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 4),
    );
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      debugPrint('🔗 Connecting to ${device.remoteId}...');
      await device.connect(timeout: const Duration(seconds: 10));
      setState(() {
        connectionStates[device.remoteId] = BluetoothConnectionState.connected;
      });

      debugPrint('✅ Connected to ${device.remoteId}');

      // === Number 1: Discover and list services + characteristics ===
      final services = await device.discoverServices();
      for (var s in services) {
        debugPrint('🔧 Service: ${s.uuid}');
        for (var c in s.characteristics) {
          debugPrint(
              '   📝 Characteristic: ${c.uuid}, props: ${c.properties}');
        }
      }
    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      setState(() {
        connectionStates[device.remoteId] =
            BluetoothConnectionState.disconnected;
      });
    }
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      debugPrint('🔌 Disconnecting from ${device.remoteId}...');
      await device.disconnect();
      setState(() {
        connectionStates[device.remoteId] =
            BluetoothConnectionState.disconnected;
      });
      debugPrint('✅ Disconnected from ${device.remoteId}');
    } catch (e) {
      debugPrint('❌ Disconnection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ESP32 BLE Scanner')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: isScanning ? null : startScan,
              child: isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Start Scan'),
            ),
          ),
          Expanded(
            child: ListView(
              children: scanResults.map((r) {
                final device = r.device;
                final state = connectionStates[device.remoteId] ??
                    BluetoothConnectionState.disconnected;

                return ListTile(
                  title: Text(
                    r.advertisementData.localName.isNotEmpty
                        ? r.advertisementData.localName
                        : 'Unknown Device',
                  ),
                  subtitle: Text(
                    '${device.remoteId}\nStatus: ${state.toString().split(".").last}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${r.rssi} dBm'),
                      const SizedBox(width: 12),
                      if (state == BluetoothConnectionState.disconnected)
                        ElevatedButton(
                          onPressed: () => connectToDevice(device),
                          child: const Text('Connect'),
                        )
                      else if (state == BluetoothConnectionState.connected)
                        ElevatedButton(
                          onPressed: () => disconnectFromDevice(device),
                          child: const Text('Disconnect'),
                        )
                      else
                        const Text('Connecting...'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
