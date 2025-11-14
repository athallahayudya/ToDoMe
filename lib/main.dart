import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // <-- 1. Impor LoginScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do Me',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false, // Hilangkan banner "DEBUG"
      
      // Catatan: Arahkan 'home' ke LoginScreen
      home: const LoginScreen(), 
    );
  }
}