import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_tts/flutter_tts.dart'; // For voice narration

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

  // TTS instance
  final FlutterTts _flutterTts = FlutterTts();

  bool get highContrast => _highContrast;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get voiceNarration => _voiceNarration;
  bool get hapticFeedback => _hapticFeedback;
  bool get largeTouchTargets => _largeTouchTargets;
  bool get simplifiedNavigation => _simplifiedNavigation;
  bool get wheelchairFriendlyOnly => _wheelchairFriendlyOnly;

  AccessibilityService() {
    _loadSettings();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  // ------------------ Load/Save ------------------
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

  // ------------------ Setters ------------------
  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
    triggerHapticAndVoice('High Contrast Mode ${value ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  Future<void> setFontSize(double multiplier) async {
    _fontSizeMultiplier = multiplier;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, multiplier);
    triggerHapticAndVoice(
      'Font size set to ${multiplier == 1.0 ? 'Normal' : multiplier == 1.5 ? 'Medium' : 'Large'}',
    );
    notifyListeners();
  }

  Future<void> setVoiceNarration(bool value) async {
    // We update the value first so triggerHapticAndVoice can check the new state
    _voiceNarration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceNarrationKey, value);
    
    // For the toggle itself, we always provide feedback for the action
    if (_hapticFeedback) HapticFeedback.mediumImpact();
    
    // If turning ON, speak it. If turning OFF, speak it one last time.
    await _flutterTts.speak('Voice narration ${value ? 'enabled' : 'disabled'}');
    
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackKey, value);
    
    // Always trigger haptic for the toggle itself if it's being turned ON
    if (value) HapticFeedback.mediumImpact();
    
    triggerVoice('Haptic feedback ${value ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  Future<void> setLargeTouchTargets(bool value) async {
    _largeTouchTargets = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_largeTouchTargetsKey, value);
    triggerHapticAndVoice('Large touch targets ${value ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  Future<void> setSimplifiedNavigation(bool value) async {
    _simplifiedNavigation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simplifiedNavigationKey, value);
    triggerHapticAndVoice('Simplified navigation ${value ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  Future<void> setWheelchairFriendly(bool value) async {
    _wheelchairFriendlyOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wheelchairFriendlyKey, value);
    triggerHapticAndVoice('Wheelchair-friendly filter ${value ? 'enabled' : 'disabled'}');
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

    // Trigger feedback for reset action
    if (_hapticFeedback) HapticFeedback.mediumImpact();
    // Since voice is reset to false, we speak the reset message once
    await _flutterTts.speak('Accessibility settings reset to default');
    
    notifyListeners();
  }

  // ------------------ Haptic & Voice ------------------
  /// Public method to trigger haptic feedback and TTS based on settings
  void triggerHapticAndVoice(String text) {
    if (_hapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    if (_voiceNarration) {
      _flutterTts.speak(text);
    }
  }

  /// Public method to trigger only voice narration based on setting
  void triggerVoice(String text) {
    if (_voiceNarration) {
      _flutterTts.speak(text);
    }
  }

  /// Public method to trigger only haptic feedback based on setting
  void triggerHaptic() {
    if (_hapticFeedback) {
      HapticFeedback.mediumImpact();
    }
  }
}
