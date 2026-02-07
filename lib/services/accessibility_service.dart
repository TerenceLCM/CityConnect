import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService extends ChangeNotifier {
  static const String _highContrastKey = 'high_contrast';
  static const String _fontSizeKey = 'font_size';
  static const String _voiceNarrationKey = 'voice_narration';
  static const String _hapticFeedbackKey = 'haptic_feedback';
  static const String _largeTouchTargetsKey = 'large_touch_targets';
  static const String _simplifiedNavigationKey = 'simplified_navigation';
  static const String _wheelchairFriendlyKey = 'wheelchair_friendly';

  bool _highContrast = false;
  double _fontSizeMultiplier = 1.0;
  bool _voiceNarration = false;
  bool _hapticFeedback = true;
  bool _largeTouchTargets = false;
  bool _simplifiedNavigation = false;
  bool _wheelchairFriendlyOnly = false;

  bool get highContrast => _highContrast;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get voiceNarration => _voiceNarration;
  bool get hapticFeedback => _hapticFeedback;
  bool get largeTouchTargets => _largeTouchTargets;
  bool get simplifiedNavigation => _simplifiedNavigation;
  bool get wheelchairFriendlyOnly => _wheelchairFriendlyOnly;

  AccessibilityService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _fontSizeMultiplier = prefs.getDouble(_fontSizeKey) ?? 1.0;
    _voiceNarration = prefs.getBool(_voiceNarrationKey) ?? false;
    _hapticFeedback = prefs.getBool(_hapticFeedbackKey) ?? true;
    _largeTouchTargets = prefs.getBool(_largeTouchTargetsKey) ?? false;
    _simplifiedNavigation = prefs.getBool(_simplifiedNavigationKey) ?? false;
    _wheelchairFriendlyOnly = prefs.getBool(_wheelchairFriendlyKey) ?? false;
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
    notifyListeners();
  }

  Future<void> setFontSize(double multiplier) async {
    _fontSizeMultiplier = multiplier;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, multiplier);
    notifyListeners();
  }

  Future<void> setVoiceNarration(bool value) async {
    _voiceNarration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceNarrationKey, value);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackKey, value);
    notifyListeners();
  }

  Future<void> setLargeTouchTargets(bool value) async {
    _largeTouchTargets = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_largeTouchTargetsKey, value);
    notifyListeners();
  }

  Future<void> setSimplifiedNavigation(bool value) async {
    _simplifiedNavigation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simplifiedNavigationKey, value);
    notifyListeners();
  }

  Future<void> setWheelchairFriendly(bool value) async {
    _wheelchairFriendlyOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wheelchairFriendlyKey, value);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _highContrast = false;
    _fontSizeMultiplier = 1.0;
    _voiceNarration = false;
    _hapticFeedback = true;
    _largeTouchTargets = false;
    _simplifiedNavigation = false;
    _wheelchairFriendlyOnly = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
