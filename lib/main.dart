import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flowva/core/theme/theme_provider.dart';
import 'package:flowva/core/constants/app_colors.dart';
import 'package:flowva/core/theme/app_theme.dart';
import 'package:flowva/features/auth/controllers/auth_controller.dart';
import 'package:flowva/features/auth/screens/splash_screen.dart';
import 'package:flowva/features/auth/screens/login_screen.dart';
import 'package:flowva/features/auth/screens/signup_screen.dart';
import 'package:flowva/features/auth/screens/forgot_password_screen.dart';
import 'package:flowva/features/groups/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Initialization Info: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Flowva',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/home': (context) => const HomeScreen(),
            },
            home: StreamBuilder<User?>(
              stream: AuthController.instance.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  final User? user = snapshot.data;
                  if (user != null) {
                    return const HomeScreen();
                  } else {
                    return const SplashScreen();
                  }
                }
                return const Scaffold(
                  backgroundColor: AppColors.primaryBackground,
                  body: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}