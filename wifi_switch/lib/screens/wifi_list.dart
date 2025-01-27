import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'dart:async'; // Add this import
import 'package:permission_handler/permission_handler.dart';

class WifiListScreen extends StatefulWidget {
  @override
  _WifiListScreenState createState() => _WifiListScreenState();
}

class _WifiListScreenState extends State<WifiListScreen> {
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  List<WiFiAccessPoint> _wifiList = [];
  String _statusLog = "";

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndScan();
  }

  // Check permissions and request them if necessary
  Future<void> _checkPermissionsAndScan() async {
    // Check if location permission is granted
    PermissionStatus locationPermission = await Permission.location.status;

    // If not granted, request it
    if (!locationPermission.isGranted) {
      PermissionStatus permissionStatus = await Permission.location.request();

      // If permission is still not granted, exit the function
      if (!permissionStatus.isGranted) {
        setState(() {
          _statusLog = "Location permission is required to scan Wi-Fi networks.";
        });
        return;
      }
    }

    // Proceed with scanning Wi-Fi networks
    setState(() {
      _statusLog = "Location permission granted. Scanning Wi-Fi networks...";
    });

    _startWiFiScan();
  }

  // Function to start the Wi-Fi scan
  Future<void> _startWiFiScan() async {
    try {
      setState(() {
        _statusLog = "Scanning Wi-Fi networks...";
      });

      subscription = WiFiScan.instance.onScannedResultsAvailable.listen((results) {
        // update accessPoints
        setState(() {
          _wifiList = results;
          _statusLog = "Wi-Fi networks scanned successfully!";
        });
      });

      // Start scanning for Wi-Fi networks
      final can = await WiFiScan.instance.canStartScan();
      // if can-not, then show error
      if (can != CanStartScan.yes) {
                  _statusLog = "Wi-Fi networks scan not started!";
                  return;
      } else {
                  _statusLog = "Wi-Fi networks scan can start!";
      }
      // call startScan API
      final result = await WiFiScan.instance.startScan();
      // reset access points.
      setState(() {
        _wifiList = <WiFiAccessPoint>[];
        _statusLog = "Wi-Fi networks scan started!";
      });
    } catch (e) {
      setState(() {
        _statusLog = "Error scanning Wi-Fi networks: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Available Wi-Fi Networks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Log:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _statusLog,
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _wifiList.length,
                itemBuilder: (context, index) {
                  WiFiAccessPoint network = _wifiList[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        network.ssid ?? 'Unknown SSID',
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            'Signal Strength: ${network.level} dBm',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Frequency: ${network.frequency} MHz',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.wifi),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
