import 'package:flutter/material.dart';
import 'screens/wifi_list.dart'; // Import the Wi-Fi list screen

void main() {
  runApp(MyApp()); // Launch the app
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wi-Fi Signal Strength', // App title
      theme: ThemeData(
        primarySwatch: Colors.blue, // Theme color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WifiListScreen(), // Set the Wi-Fi list screen as the home screen
    );
  }
}