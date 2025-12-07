import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CameraHomeScreen extends StatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  State<CameraHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends State<CameraHomeScreen> {
  late List<CameraDescription> cameras;
  late CameraDescription firstCamera;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      firstCamera = cameras.first;
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to initialize camera: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera Error')),
        body: Center(child: Text(_error!)),
      );
    }
    return TakePictureScreen(camera: firstCamera);
  }
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Leaf Image'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                // Overlay guide
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 90.0),
                    child: Text(
                      "Align the leaf within the box",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            if (!context.mounted) return;

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AnalysisScreen(imagePath: image.path),
              ),
            );
          } catch (e) {
            debugPrint('Error taking picture: $e');
          }
        },
        child: const Icon(Icons.camera_alt, size: 28),
      ),
    );
  }
}

class AnalysisScreen extends StatefulWidget {
  final String imagePath;
  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isAnalyzing = true;
  List<ImageSection> _sections = [];
  String _result = '';
  String _recommendation = '';

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final File imageFile = File(widget.imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();

      final img.Image? image = await _decodeImageInIsolate(imageBytes);
      if (image == null) {
        setState(() {
          _isAnalyzing = false;
          _result = 'Failed to process image';
        });
        return;
      }

      final int sectionWidth = image.width ~/ 2;
      final int sectionHeight = image.height ~/ 2;
      List<ImageSection> sections = [];

      for (int y = 0; y < 2; y++) {
        for (int x = 0; x < 2; x++) {
          final img.Image sectionImage = img.copyCrop(
            image,
            x: x * sectionWidth,
            y: y * sectionHeight,
            width: sectionWidth,
            height: sectionHeight,
          );

          final ColorAnalysis analysis = _analyzeColor(sectionImage);

          sections.add(ImageSection(
            image: sectionImage,
            analysis: analysis,
            position: '${x + 1}-${y + 1}',
          ));
        }
      }

      final double avgGreenness = sections
              .map((s) => s.analysis.greenIntensity)
              .reduce((a, b) => a + b) /
          sections.length;
      final bool needsNitrogen = avgGreenness < 0.6;

      setState(() {
        _isAnalyzing = false;
        _sections = sections;
        _result = needsNitrogen
            ? '⚠️ Nitrogen Deficiency Detected'
            : '✅ Healthy Nitrogen Levels';
        _recommendation = needsNitrogen
            ? 'Apply nitrogen-based fertilizer to improve plant health.'
            : 'No additional nitrogen needed at this time.';
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _result = 'Error analyzing image: $e';
      });
    }
  }

  Future<img.Image?> _decodeImageInIsolate(List<int> imageBytes) async {
    return await compute(_decodeImage, Uint8List.fromList(imageBytes));
  }

  static img.Image? _decodeImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  ColorAnalysis _analyzeColor(img.Image image) {
    int totalPixels = image.width * image.height;
    int greenSum = 0;
    int yellowSum = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final int r = pixel.r.toInt();
        final int g = pixel.g.toInt();
        final int b = pixel.b.toInt();

        final hsv = _rgbToHsv(r, g, b);
        final double hue = hsv[0];
        final double saturation = hsv[1];
        final double value = hsv[2];

        if (saturation > 0.2 && value > 0.2) {
          if (hue >= 80 && hue <= 150) {
            greenSum++;
          } else if (hue >= 40 && hue < 80) {
            yellowSum++;
          }
        }
      }
    }

    return ColorAnalysis(
      greenIntensity: greenSum / totalPixels,
      yellowIntensity: yellowSum / totalPixels,
    );
  }

  List<double> _rgbToHsv(int r, int g, int b) {
    double rf = r / 255.0, gf = g / 255.0, bf = b / 255.0;
    double maxVal = [rf, gf, bf].reduce(max);
    double minVal = [rf, gf, bf].reduce(min);
    double delta = maxVal - minVal;

    double hue = 0.0;
    if (delta != 0) {
      if (maxVal == rf) {
        hue = 60 * (((gf - bf) / delta) % 6);
      } else if (maxVal == gf) {
        hue = 60 * (((bf - rf) / delta) + 2);
      } else {
        hue = 60 * (((rf - gf) / delta) + 4);
      }
    }
    if (hue < 0) hue += 360;

    double saturation = maxVal == 0 ? 0 : delta / maxVal;
    return [hue, saturation, maxVal];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaf Analysis'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isAnalyzing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Original Image:',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(widget.imagePath)),
                  ),
                  const SizedBox(height: 24),

                  Text('Analysis Result:',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    color: _result.contains('Deficiency')
                        ? Colors.orange[100]
                        : Colors.green[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            _result,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _result.contains('Deficiency')
                                  ? Colors.orange[900]
                                  : Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _recommendation,
                            style: const TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Section Analysis:',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children:
                        _sections.map((s) => _buildSectionCard(s)).toList(),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.arrow_back),
        label: const Text("Retake"),
      ),
    );
  }

  Widget _buildSectionCard(ImageSection section) {
    final analysis = section.analysis;
    final String status = analysis.greenIntensity > 0.7
        ? 'Healthy'
        : analysis.greenIntensity > 0.5
            ? 'Moderate'
            : 'Deficient';

    final Color statusColor = analysis.greenIntensity > 0.7
        ? Colors.green
        : analysis.greenIntensity > 0.5
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text('Section ${section.position}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                  (255 * (1 - analysis.greenIntensity)).toInt(),
                  (255 * analysis.greenIntensity).toInt(),
                  0,
                  1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${(analysis.greenIntensity * 100).toStringAsFixed(1)}% green',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(status,
                style: TextStyle(
                    color: statusColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class ImageSection {
  final img.Image image;
  final ColorAnalysis analysis;
  final String position;

  ImageSection({
    required this.image,
    required this.analysis,
    required this.position,
  });
}

class ColorAnalysis {
  final double greenIntensity;
  final double yellowIntensity;

  ColorAnalysis({
    required this.greenIntensity,
    required this.yellowIntensity,
  });
}
