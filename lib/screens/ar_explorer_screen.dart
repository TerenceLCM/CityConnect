import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';

class ARExplorerScreen extends StatefulWidget {
  const ARExplorerScreen({Key? key}) : super(key: key);

  @override
  State<ARExplorerScreen> createState() => _ARExplorerScreenState();
}

class _ARExplorerScreenState extends State<ARExplorerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool _isDetecting = false;
  Map<String, dynamic>? _detectedSite;
  bool _showInfo = false;
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  File? _selectedPhoto;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        setState(() {
          _selectedPhoto = File(image.path);
          _photoBase64 = base64Encode(bytes);
        });

        // Detect MIME type
        final path = image.path.toLowerCase();
        String mimeType;

        if (path.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (path.endsWith('.heic') || path.endsWith('.heif')) {
          mimeType = 'image/heic';
        } else {
          mimeType = 'image/jpeg';
        }

        // You can call your detection API here if you want
        final result = await ApiService.detectHeritage(_photoBase64!, mimeType);
        if (result['detected'] == true && result['site'] != null) {
          setState(() {
            _detectedSite = result['site'];
            _showInfo = true;
          });

          final accessibility =
              Provider.of<AccessibilityService>(context, listen: false);
          if (accessibility.voiceNarration) {
            _speakSiteInfo(result['site']);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No heritage site detected.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras![0],
          ResolutionPreset.high,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Camera initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || _isDetecting) return;

    setState(() => _isDetecting = true);

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // Convert to base64
      final base64Image = base64Encode(bytes);

      // Detect MIME type from file extension
      final path = image.path.toLowerCase();
      String mimeType;

      if (path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.endsWith('.heic') || path.endsWith('.heif')) {
        mimeType = 'image/heic';
      } else {
        mimeType = 'image/jpeg';
      }

      // Call detection API
      final result = await ApiService.detectHeritage(base64Image, mimeType);

      if (result['detected'] == true && result['site'] != null) {
        setState(() {
          _detectedSite = result['site'];
          _showInfo = true;
        });

        // Speak narration if enabled
        final accessibility =
            Provider.of<AccessibilityService>(context, listen: false);
        if (accessibility.voiceNarration) {
          _speakSiteInfo(result['site']);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No heritage site detected. Try pointing at a landmark.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Detection error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detection failed: $e')),
        );
      }
    } finally {
      setState(() => _isDetecting = false);
    }
  }

  Future<void> _speakSiteInfo(Map<String, dynamic> site) async {
    final text = '${site['name']}. ${site['description']}';
    await _tts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityService>(context);
    final fontScale = accessibility.fontSizeMultiplier;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final highContrast = accessibility.highContrast;
    final touchTargetSize = accessibility.largeTouchTargets ? 80.0 : 60.0;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(fontSize: 16 * fontScale),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera View
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),

          // Top Bar
          // Gallery Button at bottom-left
          Positioned(
            bottom: 48,
            left: 16, // small padding from left
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
            ),
          ),

          // Viewfinder Frame
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Corner brackets
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.blue, width: 4),
                          left: BorderSide(color: Colors.blue, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.blue, width: 4),
                          right: BorderSide(color: Colors.blue, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.blue, width: 4),
                          left: BorderSide(color: Colors.blue, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.blue, width: 4),
                          right: BorderSide(color: Colors.blue, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Capture Button
                GestureDetector(
                  onTap: _isDetecting ? null : _captureAndDetect,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.blue, width: 4),
                    ),
                    child: _isDetecting
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isDetecting ? 'Detecting...' : 'Tap to Detect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * fontScale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Info Card Overlay
          if (_showInfo && _detectedSite != null)
            Positioned(
              bottom: 200,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _detectedSite!['name'] ?? 'Heritage Site',
                            style: TextStyle(
                              fontSize: 22 * fontScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showInfo = false),
                          child: const Text(
                            '×',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_detectedSite!['historicalPeriod'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _detectedSite!['historicalPeriod'],
                          style: TextStyle(
                            fontSize: 12 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      _detectedSite!['description'] ?? '',
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _speakSiteInfo(_detectedSite!),
                            icon: const Icon(Icons.mic),
                            label: Text('Listen',
                                style: TextStyle(fontSize: 16 * fontScale)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: Size.fromHeight(touchTargetSize),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _stopSpeaking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: Size.fromHeight(touchTargetSize),
                            ),
                            child: Text('Stop',
                                style: TextStyle(fontSize: 16 * fontScale)),
                          ),
                        ),
                      ],
                    ),
                    if (_detectedSite!['isWheelchairAccessible'] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '♿ Wheelchair Accessible',
                            style: TextStyle(
                              fontSize: 12 * fontScale,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
