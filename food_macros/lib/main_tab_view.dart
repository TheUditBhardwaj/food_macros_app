// lib/main_tab_view.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '/models/analysis_result.dart';
import '/tabs/scan_tab.dart';
import '/tabs/history_tab.dart';
import '/tabs/goals_tab.dart';
import '/utils/app_colors.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _currentIndex = 0;
  final List<AnalysisResult> _recentAnalyses = [];
  final List<AnalysisResult> _favorites = [];

  void _addAnalysis(AnalysisResult result) {
    setState(() {
      _recentAnalyses.insert(0, result);
      if (_recentAnalyses.length > 20) {
        _recentAnalyses.removeLast();
      }
    });
  }

  void _toggleFavorite(AnalysisResult result) {
    setState(() {
      if (_favorites.any((fav) => fav.foodItem == result.foodItem)) {
        _favorites.removeWhere((fav) => fav.foodItem == result.foodItem);
      } else {
        _favorites.add(result);
      }
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
      const GoalsTab(),
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
            // --- FIX STARTS HERE ---
            icon: Icon(CupertinoIcons.graph_circle), // A good alternative for 'Goals'
            activeIcon: Icon(CupertinoIcons.graph_circle_fill), // Filled variant
            // --- FIX ENDS HERE ---
            label: 'Goals',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return tabs[index];
          },
        );
      },
    );
  }
}