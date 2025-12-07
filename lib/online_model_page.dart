import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';

class OnlineModelPage extends StatefulWidget {
  const OnlineModelPage({super.key});

  @override
  State<OnlineModelPage> createState() => _OnlineModelPageState();
}

class _OnlineModelPageState extends State<OnlineModelPage> {
  File? _image;
  String _result = "";
  bool _isLoading = false;
  final picker = ImagePicker();

  String? apiUrl; // 🚀 Will be fetched from Firebase dynamically
  final DatabaseReference urlRef = FirebaseDatabase.instance.ref("url");

  @override
  void initState() {
    super.initState();
    _listenToApiUrl();
  }

  /// 🔹 Listen to Firebase for ngrok URL changes
  void _listenToApiUrl() {
    urlRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        String rawUrl = event.snapshot.value.toString();

        // Extract only the ngrok https://xxxx.ngrok-free.app part
        final regex = RegExp(r'https:\/\/[a-z0-9\-]+\.ngrok\-free\.app');
        final match = regex.firstMatch(rawUrl);

        if (match != null) {
          setState(() {
            apiUrl = "${match.group(0)!}/predict";
          });
          debugPrint("✅ API URL updated: $apiUrl");
        }
      }
    });
  }

  // Function to get color based on prediction
  Color _getStatusColor(String prediction) {
    if (prediction.contains("ALL Present")) return Colors.green;
    if (prediction.contains("NAB")) return Colors.orange;
    if (prediction.contains("PAB")) return Colors.orange;
    if (prediction.contains("KAB")) return Colors.orange;
    if (prediction.contains("ZNAB")) return Colors.orange;
    if (prediction.contains("ALLAB")) return Colors.red;
    return Colors.grey;
  }

  // Function to get icon based on prediction
  IconData _getStatusIcon(String prediction) {
    if (prediction.contains("ALL Present")) return Icons.check_circle;
    if (prediction.contains("NAB")) return Icons.warning;
    if (prediction.contains("PAB")) return Icons.warning;
    if (prediction.contains("KAB")) return Icons.warning;
    if (prediction.contains("ZNAB")) return Icons.warning;
    if (prediction.contains("ALLAB")) return Icons.error;
    return Icons.help;
  }

  // Function to get explanation for each condition
  String _getExplanation(String prediction) {
    switch (prediction) {
      case "ALL Present":
        return "✅ Your plant is healthy! All essential nutrients are present in adequate amounts.";
      case "NAB":
        return "⚠️ Nitrogen Deficiency\n• Yellowing leaves\n• Stunted growth\n• Apply nitrogen-rich fertilizer";
      case "PAB":
        return "⚠️ Phosphorus Deficiency\n• Purple leaves\n• Poor root development\n• Apply phosphorus fertilizer";
      case "KAB":
        return "⚠️ Potassium Deficiency\n• Brown leaf edges\n• Weak stems\n• Apply potassium-rich fertilizer";
      case "ZNAB":
        return "⚠️ Zinc Deficiency\n• Small leaves\n• Rosette formation\n• Apply zinc sulfate";
      case "ALLAB":
        return "❌ Multiple Deficiencies\n• Severe nutrient lack\n• Requires comprehensive fertilizer\n• Consult agricultural expert";
      default:
        return "Please analyze a plant leaf image";
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = "";
        _isLoading = true;
      });
      await _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    if (apiUrl == null) {
      setState(() {
        _isLoading = false;
        _result = "Error: API URL not loaded yet";
      });
      return;
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl!));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final predictedClass = data['predicted_class'];

        setState(() {
          _isLoading = false;
          _result = predictedClass;
        });
      } else {
        setState(() {
          _isLoading = false;
          _result = "Error: Server returned status ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = "Connection failed: Please check your internet connection";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌿 Plant Health Analyzer"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // URL Status Banner
            if (apiUrl == null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: const Text(
                  "⚠️ Waiting for API URL from Firebase...",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  "✅ Connected to API:\n$apiUrl",
                  style: const TextStyle(color: Colors.green),
                ),
              ),

            // Image Preview
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          "Select a plant leaf image",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 30),

            // Analyze Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: Icon(_isLoading ? Icons.hourglass_top : Icons.analytics),
              label: Text(_isLoading ? "Analyzing..." : "Analyze Plant Leaf"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 30),

            // Results Section
            if (_result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getStatusColor(_result).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _getStatusColor(_result), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getStatusIcon(_result),
                            color: _getStatusColor(_result), size: 30),
                        const SizedBox(width: 10),
                        Text(
                          "Analysis Result",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_result),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _result,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _getExplanation(_result),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
            else if (_isLoading)
              const Column(
                children: [
                  SizedBox(height: 20),
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 15),
                  Text("Analyzing your plant leaf...", style: TextStyle(fontSize: 16)),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.eco, size: 40, color: Colors.green),
                    SizedBox(height: 10),
                    Text(
                      "Welcome to Plant Health Analyzer!",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Upload a clear photo of a plant leaf to detect nutrient deficiencies and get recommendations.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
