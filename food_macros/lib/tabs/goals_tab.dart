// lib/tabs/goals_tab.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/utils/app_colors.dart';

class GoalsTab extends StatefulWidget {
  // Add parameters to receive current daily intake from MainTabView
  final double currentCalories;
  final double currentProtein;
  final double currentCarbs;
  final double currentFat;

  const GoalsTab({
    super.key,
    this.currentCalories = 0.0, // Provide defaults
    this.currentProtein = 0.0,
    this.currentCarbs = 0.0,
    this.currentFat = 0.0,
  });

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  // Default goals, loaded from SharedPreferences
  double _dailyCaloriesGoal = 2000.0;
  double _proteinGoal = 150.0;
  double _carbsGoal = 200.0;
  double _fatGoal = 70.0;

  // The 'current intake' values are now received via widget properties, not internal state
  // double _currentCalories = 1200.0; // REMOVE or COMMENT OUT THIS LINE
  // double _currentProtein = 80.0;    // REMOVE or COMMENT OUT THIS LINE
  // double _currentCarbs = 150.0;     // REMOVE or COMMENT OUT THIS LINE
  // double _currentFat = 40.0;        // REMOVE or COMMENT OUT THIS LINE

  @override
  void initState() {
    super.initState();
    _loadGoals(); // Only load goals, current intake comes from parent
    // _loadCurrentIntake(); // REMOVE or COMMENT OUT THIS LINE, as it's no longer needed
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

  // The _loadCurrentIntake method is no longer needed in GoalsTab
  // Future<void> _loadCurrentIntake() async { /* ... */ } // REMOVE THIS METHOD

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    final progress = widget.currentCalories / _dailyCaloriesGoal; // Use widget.currentCalories
    final remaining = _dailyCaloriesGoal - widget.currentCalories; // Use widget.currentCalories

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
                // We no longer call _loadCurrentIntake here, MainTabView handles aggregation.
                // You might want to signal MainTabView to re-aggregate if it's not done automatically on data change.
                // For now, this just ensures goals are reloaded if changed externally.
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
                    divisions: 60,
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
                        currentValue: widget.currentCalories, // Use widget.currentCalories
                        goalValue: _dailyCaloriesGoal,
                        color: AppColors.systemOrange,
                        icon: CupertinoIcons.flame,
                        isDark: isDark,
                      ),
                      _buildProgressTile(
                        context,
                        label: 'Protein Intake',
                        currentValue: widget.currentProtein, // Use widget.currentProtein
                        goalValue: _proteinGoal,
                        color: AppColors.systemBlue,
                        icon: CupertinoIcons.bolt,
                        isDark: isDark,
                      ),
                      _buildProgressTile(
                        context,
                        label: 'Carbs Intake',
                        currentValue: widget.currentCarbs, // Use widget.currentCarbs
                        goalValue: _carbsGoal,
                        color: AppColors.systemGreen,
                        icon: CupertinoIcons.leaf_arrow_circlepath,
                        isDark: isDark,
                      ),
                      _buildProgressTile(
                        context,
                        label: 'Fat Intake',
                        currentValue: widget.currentFat, // Use widget.currentFat
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
                      '💡 Tip: Your daily progress updates automatically as you scan food!',
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

  // Helper widget for a goal setting slider (no changes)
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

  // Helper widget for a single progress tile in the "Today's Progress" section (no changes)
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
        child: CupertinoProgressBar(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          progressColor: progress > 1.0 ? AppColors.systemOrange : color, // Orange if over goal
        ),
      ),
    );
  }

  // Custom Cupertino-style Linear Progress Bar (as defined previously)
  Widget CupertinoProgressBar({required double value, required Color backgroundColor, required Color progressColor}) {
    return Container(
      height: 6,
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