import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For general Colors and sometimes Icons
import 'package:shared_preferences/shared_preferences.dart';

import '/utils/app_colors.dart';

class GoalsTab extends StatefulWidget {
  const GoalsTab({super.key});

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  // Default goals, loaded from SharedPreferences
  double _dailyCaloriesGoal = 2000.0;
  double _proteinGoal = 150.0;
  double _carbsGoal = 200.0;
  double _fatGoal = 70.0;

  // Mock current intake for demonstration (would come from daily history aggregation)
  double _currentCalories = 1200.0;
  double _currentProtein = 80.0;
  double _currentCarbs = 150.0;
  double _currentFat = 40.0;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _loadCurrentIntake(); // Load mock current intake too
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyCaloriesGoal = prefs.getDouble('dailyCaloriesGoal') ?? 2000.0;
      _proteinGoal = prefs.getDouble('proteinGoal') ?? 150.0;
      _carbsGoal = prefs.getDouble('carbsGoal') ?? 200.0;
      _fatGoal = prefs.getDouble('fatGoal') ?? 70.0;
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dailyCaloriesGoal', _dailyCaloriesGoal);
    await prefs.setDouble('proteinGoal', _proteinGoal);
    await prefs.setDouble('carbsGoal', _carbsGoal);
    await prefs.setDouble('fatGoal', _fatGoal);
  }

  // Mock loading for current intake (replace with real aggregation from history)
  Future<void> _loadCurrentIntake() async {
    // In a real app, this would query your AnalysisResult history for today's date
    // and sum up the macros. For now, it's static.
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async load
    setState(() {
      // These values would dynamically update based on scanned foods for the current day
      _currentCalories = 1200.0;
      _currentProtein = 80.0;
      _currentCarbs = 150.0;
      _currentFat = 40.0;
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Goals'),
        backgroundColor: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withOpacity(0.9),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await _loadGoals();
                await _loadCurrentIntake(); // Refresh current intake as well
              },
              builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
                return Center(
                  child: CupertinoActivityIndicator(
                    radius: 15.0,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                );
              },
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Set your daily nutrition goals:',
                      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                  ),
                  _buildGoalSlider(
                    context,
                    label: 'Calories',
                    value: _dailyCaloriesGoal,
                    min: 1000,
                    max: 4000,
                    divisions: 60, // (4000-1000)/50 = 60
                    unit: 'kcal',
                    color: AppColors.systemOrange,
                    onChanged: (newValue) {
                      setState(() {
                        _dailyCaloriesGoal = newValue;
                      });
                      _saveGoals();
                    },
                    isDark: isDark,
                  ),
                  _buildGoalSlider(
                    context,
                    label: 'Protein',
                    value: _proteinGoal,
                    min: 50,
                    max: 300,
                    divisions: 250,
                    unit: 'g',
                    color: AppColors.systemBlue,
                    onChanged: (newValue) {
                      setState(() {
                        _proteinGoal = newValue;
                      });
                      _saveGoals();
                    },
                    isDark: isDark,
                  ),
                  _buildGoalSlider(
                    context,
                    label: 'Carbohydrates',
                    value: _carbsGoal,
                    min: 100,
                    max: 500,
                    divisions: 400,
                    unit: 'g',
                    color: AppColors.systemGreen,
                    onChanged: (newValue) {
                      setState(() {
                        _carbsGoal = newValue;
                      });
                      _saveGoals();
                    },
                    isDark: isDark,
                  ),
                  _buildGoalSlider(
                    context,
                    label: 'Fat',
                    value: _fatGoal,
                    min: 20,
                    max: 150,
                    divisions: 130,
                    unit: 'g',
                    color: AppColors.systemPurple,
                    onChanged: (newValue) {
                      setState(() {
                        _fatGoal = newValue;
                      });
                      _saveGoals();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 30),
                  CupertinoListSection.insetGrouped(
                    header: Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                      child: Text(
                        'Today\'s Progress',
                        style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                    ),
                    backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    children: [
                      _buildProgressTile(
                        context,
                        label: 'Calories Intake',
                        currentValue: _currentCalories,
                        goalValue: _dailyCaloriesGoal,
                        color: AppColors.systemOrange,
                        icon: CupertinoIcons.flame,
                        isDark: isDark,
                      ),
                      _buildProgressTile(
                        context,
                        label: 'Protein Intake',
                        currentValue: _currentProtein,
                        goalValue: _proteinGoal,
                        color: AppColors.systemBlue,
                        icon: CupertinoIcons.bolt,
                        isDark: isDark,
                      ),
                      _buildProgressTile(
                        context,
                        label: 'Carbs Intake',
                        currentValue: _currentCarbs,
                        goalValue: _carbsGoal,
                        color: AppColors.systemGreen,
                        icon: CupertinoIcons.leaf_arrow_circlepath,
                        isDark: isDark,
                      ),
                      _buildProgressTile(
                        context,
                        label: 'Fat Intake',
                        currentValue: _currentFat,
                        goalValue: _fatGoal,
                        color: AppColors.systemPurple,
                        icon: CupertinoIcons.drop,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      '💡 Tip: Your daily progress will be calculated based on your scanned food items!',
                      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for a goal setting slider
  Widget _buildGoalSlider(
      BuildContext context, {
        required String label,
        required double value,
        required double min,
        required double max,
        required int divisions,
        required String unit,
        required Color color,
        required ValueChanged<double> onChanged,
        required bool isDark,
      }) {
    return CupertinoListSection.insetGrouped(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      children: [
        CupertinoListTile(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          title: Text(
            label,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${value.toStringAsFixed(0)}$unit',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText).withOpacity(0.8),
              fontSize: 15,
            ),
          ),
          trailing: SizedBox(
            width: 150, // Adjust width as needed
            child: CupertinoSlider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              activeColor: color,
              thumbColor: color,
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for a single progress tile in the "Today's Progress" section
  Widget _buildProgressTile(
      BuildContext context, {
        required String label,
        required double currentValue,
        required double goalValue,
        required Color color,
        required IconData icon,
        required bool isDark,
      }) {
    final progress = goalValue > 0 ? currentValue / goalValue : 0.0;
    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          color: isDark ? AppColors.darkText : AppColors.lightText,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${currentValue.toStringAsFixed(0)}g / ${goalValue.toStringAsFixed(0)}g',
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          color: (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText).withOpacity(0.8),
          fontSize: 15,
        ),
      ),
      trailing: SizedBox(
        width: 80, // Adjust width as needed
        child: CupertinoProgressBar( // This is the new widget
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          progressColor: progress > 1.0 ? AppColors.systemOrange : color, // Orange if over goal
        ),
      ),
    );
  }

  // Custom Cupertino-style Linear Progress Bar (if CupertinoProgressBar isn't found)
  // This is a fallback if `CupertinoProgressBar` does not exist as a built-in widget.
  // In a previous version, this was `_buildMacroBar` in scan_tab.dart
  Widget CupertinoProgressBar({required double value, required Color backgroundColor, required Color progressColor}) {
    return Container(
      height: 6, // Or adjust as needed
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: progressColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}