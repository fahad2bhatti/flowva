import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flowva/app/app.dart';
import 'package:flowva/firebase_options.dart';
import 'package:flowva/data/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← zaroori
  );
  FirebaseService.enableOfflinePersistence(); // ← offline support
  runApp(const FlowvaApp());
}