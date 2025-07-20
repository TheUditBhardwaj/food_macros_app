// lib/models/analysis_result.dart
import 'dart:io'; // Required for the 'File' type

class AnalysisResult {
  final String foodItem;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double calories;
  final String servingSize;
  final DateTime timestamp;
  final File? image; // Optional: stores the actual image file path for display

  // Constructor to initialize all properties
  AnalysisResult({
    required this.foodItem,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sugar,
    required this.calories,
    required this.servingSize,
    required this.timestamp,
    this.image, // 'this.image' is not required as it's optional
  });
}