import 'dart:async';

import 'package:flutter/services.dart';

class WifiInfoFlutter {
  static const MethodChannel _channel = MethodChannel('wifi_info_flutter');

  // Get the current Wi-Fi SSID (network name)
  static Future<String> getWifiName() async {
    final String wifiName = await _channel.invokeMethod('getWifiName');
    return wifiName;
  }

  // Get the current Wi-Fi signal strength (in dBm)
  static Future<int> getWifiSignalStrength() async {
    final int signalStrength = await _channel.invokeMethod('getWifiSignalStrength');
    return signalStrength;
  }

  // Scan available networks and return a list of networks
  static Future<List<Map<String, dynamic>>> scanNetworks() async {
    final List<dynamic> networks = await _channel.invokeMethod('scanNetworks');
    return networks.map((network) => Map<String, dynamic>.from(network)).toList();
  }

  // Get the IP address of the current Wi-Fi connection
  static Future<String> getWifiIP() async {
    final String ipAddress = await _channel.invokeMethod('getWifiIP');
    return ipAddress;
  }
}