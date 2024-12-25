import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gemini_ai_app/screens/chatScreen.dart';

String? apiKey; // Define a global variable to hold the API key

Future<void> main() async {
  // Ensure that Flutter is initialized before running asynchronous code
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Retrieve the API key from dotenv
  apiKey = dotenv.env['API_KEY'];

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatScreen(),
    );
  }
}
