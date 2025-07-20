// lib/main.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Still needed for some utility like Color, Icons
import 'package:flutter/widgets.dart'; // Add this if not present, needed for WidgetsBinding

import '/main_tab_view.dart';
import '/utils/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the platform brightness directly from MediaQuery
    final Brightness platformBrightness = MediaQuery.of(context).platformBrightness;
    final bool isDark = platformBrightness == Brightness.dark;

    // Define the light CupertinoThemeData (as you already have)
    const CupertinoThemeData lightTheme = CupertinoThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.systemBlue, // Correct usage of systemBlue
      barBackgroundColor: AppColors.lightBackground,
      textTheme: CupertinoTextThemeData(
        navLargeTitleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
        navTitleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        textStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        actionTextStyle: TextStyle(
          color: AppColors.systemBlue, // Correct usage of systemBlue
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        pickerTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 21,
          fontWeight: FontWeight.w400,
        ),
      ),
    );

    // Define the dark CupertinoThemeData (as you already have)
    const CupertinoThemeData darkTheme = CupertinoThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.systemBlue, // Correct usage of systemBlue
      barBackgroundColor: AppColors.darkBackground,
      textTheme: CupertinoTextThemeData(
        navLargeTitleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
        navTitleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        textStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        actionTextStyle: TextStyle(
          color: AppColors.systemBlue, // Correct usage of systemBlue
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        pickerTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 21,
          fontWeight: FontWeight.w400,
        ),
      ),
    );

    return CupertinoApp(
      title: 'NutriScan',
      debugShowCheckedModeBanner: false,
      // Pass the selected theme data directly to the 'theme' parameter
      theme: isDark ? darkTheme : lightTheme,
      home: const MainTabView(),
    );
  }
}