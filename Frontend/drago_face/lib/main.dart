import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const DragoAIApp());
}

class DragoAIApp extends StatelessWidget {
  const DragoAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drago AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const ChatScreen(),
    );
  }
}