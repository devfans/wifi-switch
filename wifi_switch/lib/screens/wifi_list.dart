import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:plugin_wifi_connect/plugin_wifi_connect.dart';
import 'package:network_info_plus/network_info_plus.dart'; // Import the package

class WifiListScreen extends StatefulWidget {
  @override
  _WifiListScreenState createState() => _WifiListScreenState();
}

class _WifiListScreenState extends State<WifiListScreen> {
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  List<WiFiAccessPoint> _wifiList = [];
  String _statusLog = "";

  // Store the current connected Wi-Fi access point's details
  String? _currentSSID;
  String? _currentBSSID;
  String? _currentIP;
  String? _currentIPv6;
  WiFiAccessPoint? _currentAccessPoint; // Track the current access point

  final NetworkInfo _networkInfo = NetworkInfo(); // NetworkInfo instance

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndScan();
    _initNetworkInfo(); // Get the current connected Wi-Fi details if any
  }

  Future<void> _initNetworkInfo() async {
    String? wifiName, wifiBSSID, wifiIPv4, wifiIPv6;
    WiFiStandards? wifiStandard;

    try {
      // Request necessary permissions and fetch Wi-Fi details
      if (await Permission.locationWhenInUse.request().isGranted) {
        wifiName = await _networkInfo.getWifiName();
        wifiBSSID = await _networkInfo.getWifiBSSID();
      } else {
        wifiName = 'Unauthorized to get Wifi Name';
        wifiBSSID = 'Unauthorized to get Wifi BSSID';
      }
    } catch (e) {
      wifiName = 'Failed to get Wifi Name';
      wifiBSSID = 'Failed to get Wifi BSSID';
    }

    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } catch (e) {
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    try {
      wifiIPv6 = await _networkInfo.getWifiIPv6();
    } catch (e) {
      wifiIPv6 = 'Failed to get Wifi IPv6';
    }

    // Update current connected Wi-Fi info
    setState(() {
      _currentSSID = wifiName;
      _currentBSSID = wifiBSSID;
      _currentIP = wifiIPv4;
      _currentIPv6 = wifiIPv6;
    });

    // Call to update the current Wi-Fi info based on SSID and BSSID
    _updateCurrentWifiInfo();
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
        // Sort Wi-Fi networks by signal strength (ascending)
        results.sort((a, b) => b.level.compareTo(a.level));

        setState(() {
          _wifiList = results;
          _statusLog = "Wi-Fi networks scanned successfully!";
        });
        // Update access points and match the current network by SSID and BSSID
        _updateCurrentWifiInfo();

      });

      // Start scanning for Wi-Fi networks
      final can = await WiFiScan.instance.canStartScan();
      if (can != CanStartScan.yes) {
        _statusLog = "Wi-Fi networks scan not started!";
        return;
      } else {
        _statusLog = "Wi-Fi networks scan can start!";
      }

      // Call startScan API
      final result = await WiFiScan.instance.startScan();
      // Reset access points.
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

  // Function to update the current Wi-Fi network's information in the list
  void _updateCurrentWifiInfo() {
    if (_currentSSID == null || _currentBSSID == null) return; // No connected Wi-Fi info

    // Find the current Wi-Fi access point in the list
    for (var network in _wifiList) {
      if (network.ssid == _currentSSID && network.bssid == _currentBSSID) {
        // Update current Wi-Fi info with the matching SSID and BSSID
        setState(() {
          _currentAccessPoint = network; // Track the current connected access point
          _statusLog = "Found connected to ${network.ssid}";
        });
        return; // Once found, exit the loop
      }
    }
    setState(() {
      _currentAccessPoint = null; // Track the current connected access point
      _statusLog = "Found no connection currently!";
    });
  }

  // Helper function to determine Wi-Fi standard based on the WiFiAccessPoint standard property
  String getWiFiStandard(WiFiStandards standard) {
    switch (standard) {
      case WiFiStandards.n:
        return 'Wi-Fi 4 (802.11n)';
      case WiFiStandards.ac:
        return 'Wi-Fi 5 (802.11ac)';
      case WiFiStandards.ax:
        return 'Wi-Fi 6 (802.11ax)';
      default:
        return 'Unknown Standard';
    }
  }

  // Function to connect to a Wi-Fi network
  Future<void> _connectToWiFi(WiFiAccessPoint network) async {
    try {
      setState(() {
        _statusLog = "Connecting to ${network.ssid}...";
      });

      // Connect to the Wi-Fi network using plugin_wifi_connect
      final result = await PluginWifiConnect.connect(network.ssid!); // Provide the password here if it's required

      if (result == true) {
        setState(() {
          _statusLog = "Successfully connected to ${network.ssid}!";
        });

        
      } else {
        setState(() {
          _statusLog = "Failed to connect to ${network.ssid}.";
        });
      }
    } catch (e) {
      setState(() {
        _statusLog = "Error connecting to ${network.ssid}: $e";
      });
    }
    // Re-fetch the current connected Wi-Fi info after a successful connection
    _initNetworkInfo();
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
            // Display current connected Wi-Fi network in a card
              Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  title: Text(
                    "Connected to: ${_currentSSID?? 'Unknown'}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("BSSID: ${_currentBSSID ?? 'Unknown'}"),
                      Text("Frequency: ${_currentAccessPoint?.frequency ?? 'Unknown'} MHz"),
                      Text("IP: ${_currentIP ?? 'Unknown'}"),
                      Text("IPv6: ${_currentIPv6 ?? 'Unknown'}"),
                      Text("Signal Strength: ${_currentAccessPoint?.level ?? 'Unknown'} dBm"),
                      Text("Standard: ${_currentAccessPoint != null ? getWiFiStandard(_currentAccessPoint!.standard) : 'Unknown'}"),
                    ],
                  ),
                ),
              ),
            // Status Log Section
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

                  // Check if the network is saved and connected
                  bool isSaved = network.ssid == _currentSSID;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    color: isSaved ? Colors.white : Colors.grey[300], // Mark unsaved
                    child: ListTile(
                      title: Text(
                        network.ssid ?? 'Unknown SSID',
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BSSID: ${network.bssid ?? 'Unknown BSSID'}',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Signal Strength: ${network.level} dBm',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Frequency: ${network.frequency} MHz',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            'Wi-Fi Standard: ${getWiFiStandard(network.standard)}',
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.wifi),
                        onPressed: () => _connectToWiFi(network),
                      ),
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
