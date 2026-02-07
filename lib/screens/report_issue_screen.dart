import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({Key? key}) : super(key: key);

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedPhoto;
  String? _photoBase64;
  String _selectedCategory = 'road_damage';
  Position? _currentLocation;
  String _address = '';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> categories = [
    {'value': 'road_damage', 'label': 'Road Damage', 'icon': '🚧'},
    {'value': 'waste_management', 'label': 'Waste Management', 'icon': '🗑️'},
    {'value': 'street_lighting', 'label': 'Street Lighting', 'icon': '💡'},
    {'value': 'public_facilities', 'label': 'Public Facilities', 'icon': '🏛️'},
    {'value': 'accessibility_issues', 'label': 'Accessibility Issues', 'icon': '♿'},
    {'value': 'other', 'label': 'Other', 'icon': '📝'},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentLocation = position);

      // Try to get address (optional)
      try {
        // You can use geocoding package here
        setState(() =>
            _address = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
      } catch (e) {
        print('Geocoding error: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        setState(() {
          _selectedPhoto = File(image.path);
          _photoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_photoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take or select a photo')),
      );
      return;
    }

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService.createIssue(
        category: _selectedCategory,
        photoBase64: _photoBase64!,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        address: _address.isNotEmpty ? _address : null,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedPhoto = null;
          _photoBase64 = null;
          _selectedCategory = 'road_damage';
          _descriptionController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityService>(context);
    final fontScale = accessibility.fontSizeMultiplier;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final highContrast = accessibility.highContrast;
    final touchTargetSize = accessibility.largeTouchTargets ? 80.0 : 60.0;

    final backgroundColor = highContrast
        ? (isDarkMode ? Colors.black : Colors.white)
        : (isDarkMode ? const Color(0xFF151718) : Colors.white);
    final textColor = highContrast
        ? (isDarkMode ? Colors.white : Colors.black)
        : (isDarkMode ? Colors.white : Colors.black);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Text(
                'Report City Issue',
                style: TextStyle(
                  fontSize: 30 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help improve our city by reporting problems',
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Photo Section
              Text(
                'Photo *',
                style: TextStyle(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              if (_selectedPhoto != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _selectedPhoto!,
                        height: 256,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedPhoto = null;
                          _photoBase64 = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '×',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: Text('Take Photo',
                            style: TextStyle(fontSize: 16 * fontScale)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: Size.fromHeight(touchTargetSize),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.image),
                        label: Text('Choose Photo',
                            style: TextStyle(fontSize: 16 * fontScale)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          minimumSize: Size.fromHeight(touchTargetSize),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              // Category Selection
              Text(
                'Category *',
                style: TextStyle(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${cat['icon']} ${cat['label']}',
                        style: TextStyle(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.blue : textColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Location Section
              Text(
                'Location *',
                style: TextStyle(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: _isLoadingLocation
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Getting location...',
                            style: TextStyle(
                              fontSize: 14 * fontScale,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    : _currentLocation != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current Location',
                                    style: TextStyle(
                                      fontSize: 16 * fontScale,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _address,
                                style: TextStyle(
                                  fontSize: 14 * fontScale,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _getCurrentLocation,
                                child: Text(
                                  'Refresh Location',
                                  style: TextStyle(
                                    fontSize: 14 * fontScale,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: _getCurrentLocation,
                            child: Text(
                              'Get Current Location',
                              style: TextStyle(
                                fontSize: 16 * fontScale,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
              ),
              const SizedBox(height: 32),

              // Description
              Text(
                'Description (Optional)',
                style: TextStyle(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: TextStyle(fontSize: 16 * fontScale),
                decoration: InputDecoration(
                  hintText: 'Add any additional details...',
                  hintStyle: TextStyle(fontSize: 16 * fontScale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: touchTargetSize,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  'Your report will be reviewed by city authorities. You can track the status of your reports in this screen after submission.',
                  style: TextStyle(
                    fontSize: 14 * fontScale,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
