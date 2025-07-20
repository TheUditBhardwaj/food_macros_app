import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For Icons.favorite, etc.
import 'package:intl/intl.dart'; // Add to pubspec.yaml if not already there
import '/models/analysis_result.dart';
import '/utils/app_colors.dart';

class HistoryTab extends StatefulWidget {
  final List<AnalysisResult> recentAnalyses;
  final List<AnalysisResult> favorites;
  final Function(AnalysisResult) onToggleFavorite;

  const HistoryTab({
    super.key,
    required this.recentAnalyses,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('History'),
        backgroundColor: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withOpacity(0.9),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Pull-to-refresh control
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                // In a real app, you might refetch data from persistent storage.
                // For this example, we just simulate a delay.
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) { // Check if the widget is still in the tree before calling setState
                  setState(() {}); // Trigger rebuild to show any changes
                }
              },
              builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
                return Center( // Center the indicator
                  child: CupertinoActivityIndicator(
                    radius: 15.0,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                );
              },
            ),

            if (widget.favorites.isNotEmpty)
              SliverToBoxAdapter( // Wrap CupertinoListSection in SliverToBoxAdapter
                child: _buildSection(
                  context,
                  title: 'Favorites',
                  results: widget.favorites,
                  isDark: isDark,
                ),
              ),
            if (widget.recentAnalyses.isNotEmpty)
              SliverToBoxAdapter( // Wrap CupertinoListSection in SliverToBoxAdapter
                child: _buildSection(
                  context,
                  title: 'Recent Analyses',
                  results: widget.recentAnalyses,
                  isDark: isDark,
                ),
              ),
            if (widget.favorites.isEmpty && widget.recentAnalyses.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No history or favorites yet. Scan some food!',
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required List<AnalysisResult> results,
        required bool isDark,
      }) {
    return CupertinoListSection.insetGrouped(
      header: Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
        child: Text(
          title,
          style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            fontSize: 15, // Match iOS section header size
          ),
        ),
      ),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground, // Section background
      children: results.map((result) {
        final isFavorite = widget.favorites.any((fav) => fav.foodItem == result.foodItem);
        return CupertinoListTile(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard, // Tile background
          title: Text(
            result.foodItem,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${result.calories.toStringAsFixed(0)} kcal',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText).withOpacity(0.8),
              fontSize: 15,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => widget.onToggleFavorite(result),
                child: Icon(
                  isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: isFavorite ? AppColors.systemPink : CupertinoTheme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                CupertinoIcons.right_chevron,
                color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
                size: 20,
              ),
            ],
          ),
          onTap: () {
            _showAnalysisDetails(context, result, isDark);
          },
        );
      }).toList(),
    );
  }

  void _showAnalysisDetails(
      BuildContext context, AnalysisResult result, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            result.foodItem,
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          message: Column(
            // Use _buildLinearProgressBar here
            children: [
              Text(
                '${result.calories.toStringAsFixed(0)} kcal',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Fixed property names: protein, carbs, fat
              _buildLinearProgressBar('Protein', result.protein, AppColors.systemBlue, isDark),
              _buildLinearProgressBar('Carbohydrates', result.carbs, AppColors.systemGreen, isDark),
              _buildLinearProgressBar('Fat', result.fat, AppColors.systemPurple, isDark),
              _buildLinearProgressBar('Fiber', result.fiber, AppColors.systemTeal, isDark),
              _buildLinearProgressBar('Sugar', result.sugar, AppColors.systemPink, isDark),
            ],
          ),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              isDefaultAction: true,
              child: Text(
                'OK',
                style: CupertinoTheme.of(context).textTheme.actionTextStyle.copyWith(
                  color: AppColors.systemBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Moved and adapted _buildMacroBar from scan_tab.dart, renamed for clarity
  Widget _buildLinearProgressBar(
      String label, double value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                // Max 1.0 (100%), scale value appropriately based on some max expected.
                // For a bar in a detailed view, a fixed max like 100g or 200g might make sense
                // or percentage of daily value if you calculate it. For now, just a raw value scale.
                widthFactor: (value / 100.0).clamp(0.0, 1.0), // Example: scale up to 100g
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              '${value.toStringAsFixed(1)}g',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showExportOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Export History'),
        message: const Text('Choose an export format'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              print('Export to CSV tapped');
            },
            child: const Text('Export as CSV'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              print('Export to JSON tapped');
            },
            child: const Text('Export as JSON'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}