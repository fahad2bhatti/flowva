import 'package:flutter/material.dart';
import 'routes.dart';
import '../core/theme/app_theme.dart';



class FlowvaApp extends StatelessWidget {
  const FlowvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flowva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      
    );
  }
}


