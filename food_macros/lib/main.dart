import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart'; // For lookupMimeType
import 'package:http_parser/http_parser.dart'; // For MediaType

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Macros Finder',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const FoodMacrosHomePage(),
    );
  }
}

class FoodMacrosHomePage extends StatefulWidget {
  const FoodMacrosHomePage({super.key});

  @override
  State<FoodMacrosHomePage> createState() => _FoodMacrosHomePageState();
}

class _FoodMacrosHomePageState extends State<FoodMacrosHomePage> {
  File? _image;
  bool _isLoading = false;
  Map<String, dynamic>? _macroData;
  String _errorMessage = '';

  final ImagePicker _picker = ImagePicker();
  // IMPORTANT: Replace with your actual backend API URL.
  // Using 10.0.2.2 for Android emulator to access host machine's localhost.
  // For physical devices, replace with your computer's local IP address (e.g., '192.168.1.100').
  // Ensure the port (8000 or 8080) matches your backend's running port.
  static const String _backendApiUrl = 'http://10.0.2.2:8000/predict_macros/';

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _macroData = null; // Clear previous results
        _errorMessage = ''; // Clear previous errors
        // --- DEBUG PRINTS FOR IMAGE INFO ---
        print('Picked file path: ${pickedFile.path}');
        print('Picked file name: ${pickedFile.name}');
        print('Picked file MIME type (from picker): ${pickedFile.mimeType}');
        // --- END DEBUG PRINTS ---
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      setState(() {
        _errorMessage = 'Please select an image first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_backendApiUrl));

      // Determine MIME type
      String? mimeType = lookupMimeType(_image!.path);
      print('Determined MIME type for upload: $mimeType'); // Debug print

      // Split mimeType into primary and sub type
      MediaType? mediaType;
      if (mimeType != null) {
        final parts = mimeType.split('/');
        if (parts.length == 2) {
          mediaType = MediaType(parts[0], parts[1]);
        }
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // This 'file' key must match the name in your FastAPI endpoint's File(...)
          _image!.path,
          contentType: mediaType, // Explicitly set content type
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        setState(() {
          _macroData = json.decode(responseData);
          print('Backend Response: $_macroData'); // For debugging
        });
      } else {
        final errorResponse = await response.stream.bytesToString();
        // Attempt to parse JSON error message
        Map<String, dynamic> errorMap;
        try {
          errorMap = json.decode(errorResponse);
        } catch (e) {
          errorMap = {'detail': 'Could not parse error response: $errorResponse'};
        }
        setState(() {
          _errorMessage =
          'Error: ${response.statusCode}\n${errorMap['detail'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to the server: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Macros Finder 📸'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _image == null
                ? Container(
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: Text(
                  'No image selected',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
                : Image.file(
              _image!,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadImage,
              icon: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isLoading ? 'Analyzing...' : 'Find Macros'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            if (_macroData != null)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(top: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results for: ${_macroData!['food_item']}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      _buildMacroRow(
                          'Protein:', _macroData!['protein_g']?.toStringAsFixed(1) ?? 'N/A', 'g 💪'),
                      _buildMacroRow(
                          'Fat:', _macroData!['fat_g']?.toStringAsFixed(1) ?? 'N/A', 'g 🥑'),
                      _buildMacroRow(
                          'Carbohydrates:', _macroData!['carbs_g']?.toStringAsFixed(1) ?? 'N/A', 'g 🍚'),
                      // --- NEW FIELDS ADDED BELOW ---
                      _buildMacroRow(
                          'Fiber:', _macroData!['fiber_g']?.toStringAsFixed(1) ?? 'N/A', 'g 🧵'),
                      _buildMacroRow(
                          'Sugar:', _macroData!['sugar_g']?.toStringAsFixed(1) ?? 'N/A', 'g 🍭'),
                      // --- END NEW FIELDS ---
                      _buildMacroRow(
                          'Calories:', _macroData!['calories_kcal']?.toStringAsFixed(1) ?? 'N/A', 'kcal 🔥'),
                      _buildMacroRow(
                          'Serving Size:', _macroData!['serving_size'] ?? 'N/A', ''), // Display serving size
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            '$value $unit',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}