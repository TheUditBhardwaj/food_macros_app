// lib/tabs/scan_tab.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '/utils/app_colors.dart'; // Ensure this import is present
import '/models/analysis_result.dart';

class ScanTab extends StatefulWidget {
  final Function(AnalysisResult) onAnalysisComplete;
  final List<AnalysisResult> favorites;
  final Function(AnalysisResult) onToggleFavorite;

  const ScanTab({
    super.key,
    required this.onAnalysisComplete,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> with TickerProviderStateMixin {
  File? _image;
  bool _isLoading = false;
  AnalysisResult? _currentResult;
  String _errorMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ImagePicker _picker = ImagePicker();
  static const String _backendApiUrl = 'http://10.0.2.2:8090/predict_macros/';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _currentResult = null;
        _errorMessage = '';
      });

      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_backendApiUrl));

      String? mimeType = lookupMimeType(_image!.path);
      MediaType? mediaType;
      if (mimeType != null) {
        final parts = mimeType.split('/');
        if (parts.length == 2) {
          mediaType = MediaType(parts[0], parts[1]);
        }
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _image!.path,
          contentType: mediaType,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final macroData = json.decode(responseData);

        final result = AnalysisResult(
          foodItem: macroData['food_item'] ?? 'Unknown Food',
          protein: macroData['protein_g']?.toDouble() ?? 0.0,
          fat: macroData['fat_g']?.toDouble() ?? 0.0,
          carbs: macroData['carbs_g']?.toDouble() ?? 0.0,
          fiber: macroData['fiber_g']?.toDouble() ?? 0.0,
          sugar: macroData['sugar_g']?.toDouble() ?? 0.0,
          calories: macroData['calories_kcal']?.toDouble() ?? 0.0,
          servingSize: macroData['serving_size'] ?? 'N/A',
          timestamp: DateTime.now(),
          image: _image,
        );

        setState(() {
          _currentResult = result;
        });

        widget.onAnalysisComplete(result);
      } else {
        final errorResponse = await response.stream.bytesToString();
        Map<String, dynamic> errorMap;
        try {
          errorMap = json.decode(errorResponse);
        } catch (e) {
          errorMap = {'detail': 'Server did not return a valid error message'};
        }
        setState(() {
          _errorMessage = errorMap['detail'] ?? 'Analysis failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to server: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImageSourcePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Add Food Photo'),
        message: const Text('Choose how you\'d like to add a photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: Row( // Removed const to allow dynamic icon color
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, color: AppColors.systemBlue), // Fixed: AppColors.systemBlue
                SizedBox(width: 8),
                Text('Take Photo'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: Row( // Removed const
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, color: AppColors.systemBlue), // Fixed: AppColors.systemBlue
                SizedBox(width: 8),
                Text('Photo Library'),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NutriScan',
                          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover nutrition in your food',
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText, // Fixed: AppColors.darkSecondaryText
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.systemBlue.withOpacity(0.1), // Fixed: AppColors.systemBlue
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      color: AppColors.systemBlue, // Fixed: AppColors.systemBlue
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Camera Section / Image Preview
              if (_image == null) ...[
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: GestureDetector(
                        onTap: _showImageSourcePicker,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.systemBlue.withOpacity(0.3), // Fixed: AppColors.systemBlue
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.systemBlue.withOpacity(0.1), // Fixed: AppColors.systemBlue
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  CupertinoIcons.camera,
                                  color: AppColors.systemBlue, // Fixed: AppColors.systemBlue
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to scan food',
                                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                  color: AppColors.systemBlue, // Fixed: AppColors.systemBlue
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Take a photo or choose from library',
                                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText, // Fixed: AppColors.darkSecondaryText
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                // Image Preview with overlay
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Image.file(
                          _image!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        if (_isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CupertinoActivityIndicator(radius: 20, color: Colors.white),
                                  SizedBox(height: 16),
                                  Text(
                                    'Analyzing nutrition...',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _showImageSourcePicker,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                CupertinoIcons.refresh,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.systemRed.withOpacity(0.1), // Fixed: AppColors.systemRed
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.systemRed.withOpacity(0.3)), // Fixed: AppColors.systemRed
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle,
                          color: AppColors.systemRed, size: 20), // Fixed: AppColors.systemRed
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            color: AppColors.systemRed, // Fixed: AppColors.systemRed
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Results
              if (_currentResult != null && !_isLoading) ...[
                const SizedBox(height: 24),
                _buildNutritionCard(),
                const SizedBox(height: 16),
                _buildMacroVisualization(),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionCard() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final isFavorite = widget.favorites.any((fav) => fav.foodItem == _currentResult!.foodItem);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentResult!.foodItem,
                      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Per ${_currentResult!.servingSize}',
                      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText, // Fixed: AppColors.darkSecondaryText
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => widget.onToggleFavorite(_currentResult!),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isFavorite
                        ? AppColors.systemPink.withOpacity(0.1) // Fixed: AppColors.systemPink
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: isFavorite ? AppColors.systemPink : AppColors.systemBlue, // Fixed: AppColors.systemPink & systemBlue
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Calories highlight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.systemOrange.withOpacity(0.1), // Fixed: AppColors.systemOrange
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.systemOrange.withOpacity(0.2), // Fixed: AppColors.systemOrange
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.flame, color: AppColors.systemOrange, size: 20), // Fixed: AppColors.systemOrange
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calories',
                        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText, // Fixed: AppColors.darkSecondaryText
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${_currentResult!.calories.toStringAsFixed(0)} kcal',
                        style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                          color: AppColors.systemOrange, // Fixed: AppColors.systemOrange
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Macronutrients grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMacroTile('Protein', _currentResult!.protein, 'g',
                  AppColors.systemBlue, CupertinoIcons.bolt), // Fixed: AppColors.systemBlue
              _buildMacroTile('Carbs', _currentResult!.carbs, 'g',
                  AppColors.systemGreen, CupertinoIcons.leaf_arrow_circlepath), // Fixed: AppColors.systemGreen
              _buildMacroTile('Fat', _currentResult!.fat, 'g',
                  AppColors.systemPurple, CupertinoIcons.drop), // Fixed: AppColors.systemPurple
              _buildMacroTile('Fiber', _currentResult!.fiber, 'g',
                  AppColors.systemTeal, CupertinoIcons.waveform_path), // Fixed: AppColors.systemTeal
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroTile(String label, double value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value.toStringAsFixed(1),
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroVisualization() {
    final total = _currentResult!.protein + _currentResult!.carbs + _currentResult!.fat;
    if (total == 0) return const SizedBox.shrink();

    final proteinPercent = _currentResult!.protein / total;
    final carbsPercent = _currentResult!.carbs / total;
    final fatPercent = _currentResult!.fat / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro Breakdown',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 16),

          _buildMacroBar('Protein', proteinPercent, AppColors.systemBlue), // Fixed: AppColors.systemBlue
          const SizedBox(height: 12),
          _buildMacroBar('Carbohydrates', carbsPercent, AppColors.systemGreen), // Fixed: AppColors.systemGreen
          const SizedBox(height: 12),
          _buildMacroBar('Fat', fatPercent, AppColors.systemPurple), // Fixed: AppColors.systemPurple
        ],
      ),
    );
  }

  Widget _buildMacroBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: percentage.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}