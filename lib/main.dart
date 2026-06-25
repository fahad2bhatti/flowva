import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flowva/app/app.dart';
import 'package:flowva/firebase_options.dart';
import 'package:flowva/data/services/firebase_service.dart';
import 'package:flowva/data/services/notification_service.dart';

// ✅ Global NavigatorKey — GoRouter + NotificationService dono use karenge
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseService.enableOfflinePersistence();

  // ✅ NotificationService ko navigatorKey do, phir initialize karo
  NotificationService.instance.setNavigatorKey(navigatorKey);
  await NotificationService.instance.initialize();

  runApp(const FlowvaApp());
}