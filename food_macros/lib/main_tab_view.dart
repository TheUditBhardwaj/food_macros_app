// lib/main_tab_view.dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For persistence
import 'dart:convert'; // For JSON encoding/decoding
import 'package:intl/intl.dart'; // For date comparison (add to pubspec.yaml if not there)

import 'models/analysis_result.dart';
import 'tabs/scan_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/goals_tab.dart';
import 'utils/app_colors.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _currentIndex = 0;
  final List<AnalysisResult> _recentAnalyses = [];
  final List<AnalysisResult> _favorites = [];

  // Aggregated daily totals
  double _currentDailyCalories = 0.0;
  double _currentDailyProtein = 0.0;
  double _currentDailyCarbs = 0.0;
  double _currentDailyFat = 0.0;

  late Future<void> _initDataFuture; // To manage async data loading at startup

  @override
  void initState() {
    super.initState();
    _initDataFuture = _loadAnalysesAndAggregate(); // Load data and then aggregate
  }

  // Combines loading and aggregation for initial setup
  Future<void> _loadAnalysesAndAggregate() async {
    await _loadAnalyses(); // Load from preferences
    _aggregateDailyIntake(); // Then aggregate for today
  }

  // --- Persistence Methods ---
  Future<void> _loadAnalyses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? recentAnalysesJson = prefs.getStringList('recentAnalyses');
    final List<String>? favoritesJson = prefs.getStringList('favorites');

    setState(() {
      _recentAnalyses.clear();
      if (recentAnalysesJson != null) {
        for (var jsonString in recentAnalysesJson) {
          final Map<String, dynamic> map = json.decode(jsonString);
          // Reconstruct AnalysisResult (handle File path, might need path_provider package for robust image path handling)
          File? imageFile;
          if (map['imagePath'] != null) {
            imageFile = File(map['imagePath']);
          }
          _recentAnalyses.add(AnalysisResult(
            foodItem: map['foodItem'],
            protein: map['protein'],
            fat: map['fat'],
            carbs: map['carbs'],
            fiber: map['fiber'],
            sugar: map['sugar'],
            calories: map['calories'],
            servingSize: map['servingSize'],
            timestamp: DateTime.parse(map['timestamp']),
            image: imageFile,
          ));
        }
      }

      _favorites.clear();
      if (favoritesJson != null) {
        for (var jsonString in favoritesJson) {
          final Map<String, dynamic> map = json.decode(jsonString);
          File? imageFile;
          if (map['imagePath'] != null) {
            imageFile = File(map['imagePath']);
          }
          _favorites.add(AnalysisResult(
            foodItem: map['foodItem'],
            protein: map['protein'],
            fat: map['fat'],
            carbs: map['carbs'],
            fiber: map['fiber'],
            sugar: map['sugar'],
            calories: map['calories'],
            servingSize: map['servingSize'],
            timestamp: DateTime.parse(map['timestamp']),
            image: imageFile,
          ));
        }
      }
    });
  }

  Future<void> _saveAnalyses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> recentAnalysesJson = _recentAnalyses.map((result) => json.encode({
      'foodItem': result.foodItem,
      'protein': result.protein,
      'fat': result.fat,
      'carbs': result.carbs,
      'fiber': result.fiber,
      'sugar': result.sugar,
      'calories': result.calories,
      'servingSize': result.servingSize,
      'timestamp': result.timestamp.toIso8601String(),
      'imagePath': result.image?.path,
    })).toList();
    await prefs.setStringList('recentAnalyses', recentAnalysesJson);

    final List<String> favoritesJson = _favorites.map((result) => json.encode({
      'foodItem': result.foodItem,
      'protein': result.protein,
      'fat': result.fat,
      'carbs': result.carbs,
      'fiber': result.fiber,
      'sugar': result.sugar,
      'calories': result.calories,
      'servingSize': result.servingSize,
      'timestamp': result.timestamp.toIso8601String(),
      'imagePath': result.image?.path,
    })).toList();
    await prefs.setStringList('favorites', favoritesJson);
  }

  void _addAnalysis(AnalysisResult result) {
    setState(() {
      _recentAnalyses.insert(0, result);
      // Optional: limit history size
      if (_recentAnalyses.length > 50) { // Keep more history
        _recentAnalyses.removeLast();
      }
    });
    _saveAnalyses(); // Save after adding a new analysis
    _aggregateDailyIntake(); // Re-aggregate current day's totals
  }

  void _toggleFavorite(AnalysisResult result) {
    setState(() {
      if (_favorites.any((fav) => fav.foodItem == result.foodItem)) {
        _favorites.removeWhere((fav) => fav.foodItem == result.foodItem);
      } else {
        _favorites.add(result);
      }
    });
    _saveAnalyses(); // Save after toggling favorite status
  }

  // --- Daily Aggregation Logic ---
  void _aggregateDailyIntake() {
    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;

    final now = DateTime.now();
    // Use DateFormat to compare only the date part, ignoring time
    final todayFormatter = DateFormat('yyyy-MM-dd');

    for (var result in _recentAnalyses) {
      if (todayFormatter.format(result.timestamp) == todayFormatter.format(now)) {
        totalCalories += result.calories;
        totalProtein += result.protein;
        totalCarbs += result.carbs;
        totalFat += result.fat;
      }
    }

    setState(() {
      _currentDailyCalories = totalCalories;
      _currentDailyProtein = totalProtein;
      _currentDailyCarbs = totalCarbs;
      _currentDailyFat = totalFat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ScanTab(
        onAnalysisComplete: _addAnalysis,
        favorites: _favorites,
        onToggleFavorite: _toggleFavorite,
      ),
      HistoryTab(
        recentAnalyses: _recentAnalyses,
        favorites: _favorites,
        onToggleFavorite: _toggleFavorite,
      ),
      GoalsTab( // Pass the calculated daily totals to GoalsTab
        currentCalories: _currentDailyCalories,
        currentProtein: _currentDailyProtein,
        currentCarbs: _currentDailyCarbs,
        currentFat: _currentDailyFat,
      ),
      // const ProfileTab(), // If you've added this, uncomment it
    ];

    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withOpacity(0.9),
        activeColor: CupertinoTheme.of(context).primaryColor,
        inactiveColor: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.camera),
            activeIcon: Icon(CupertinoIcons.camera_fill),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock),
            activeIcon: Icon(CupertinoIcons.clock_fill),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.graph_circle),
            activeIcon: Icon(CupertinoIcons.graph_circle_fill),
            label: 'Goals',
          ),
          // BottomNavigationBarItem( // If you added ProfileTab
          //   icon: Icon(CupertinoIcons.profile_circled),
          //   activeIcon: Icon(CupertinoIcons.profile_circled_fill),
          //   label: 'Profile',
          // ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            // Use FutureBuilder to wait for _initDataFuture before displaying content
            // This ensures data is loaded from SharedPreferences before widgets try to use it.
            return FutureBuilder<void>(
              future: _initDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading data: ${snapshot.error}',
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    );
                  }
                  return tabs[index]; // Data loaded, show the tab content
                } else {
                  return Center( // Show a loading indicator while data loads
                    child: CupertinoActivityIndicator(
                      radius: 20.0,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}