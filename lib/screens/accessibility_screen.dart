import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({Key? key}) : super(key: key);

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  @override
  void initState() {
    super.initState();
    // Announce screen title when opened if voice narration is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accessibility = Provider.of<AccessibilityService>(context, listen: false);
      accessibility.triggerVoice('Accessibility Settings Screen');
    });
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityService>(context);
    final fontScale = accessibility.fontSizeMultiplier;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final highContrast = accessibility.highContrast;
    final touchTargetSize = accessibility.largeTouchTargets ? 80.0 : 60.0;
    final isSimplified = accessibility.simplifiedNavigation;

    final backgroundColor = highContrast
        ? (isDarkMode ? Colors.black : Colors.white)
        : (isDarkMode ? const Color(0xFF151718) : Colors.white);
    final textColor = highContrast
        ? (isDarkMode ? Colors.white : Colors.black)
        : (isDarkMode ? Colors.white : Colors.black);

    Widget sectionHeader(String text) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: isSimplified ? 20 : 12),
        child: Semantics(
          header: true,
          child: Text(
            text,
            style: TextStyle(
              fontSize: (isSimplified ? 22 : 18) * fontScale,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: isSimplified 
        ? AppBar(
            title: const Text('Accessibility'),
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            elevation: 0,
          )
        : null,
      body: Semantics(
        label: 'Accessibility Settings',
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSimplified) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Accessibility',
                    style: TextStyle(
                      fontSize: 30 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize your experience for maximum comfort',
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Visual Accessibility
                sectionHeader('Visual Accessibility'),

                _SettingRow(
                  title: 'High Contrast Mode',
                  description: 'Increase contrast for better visibility',
                  value: accessibility.highContrast,
                  onChanged: (value) => accessibility.setHighContrast(value),
                  fontScale: fontScale,
                  isDarkMode: isDarkMode,
                  highContrast: highContrast,
                  isSimplified: isSimplified,
                ),
                SizedBox(height: isSimplified ? 20 : 12),

                // Font Size Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Font Size',
                        style: TextStyle(
                          fontSize: (isSimplified ? 18 : 16) * fontScale,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (!isSimplified) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Adjust text size throughout the app',
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _FontSizeButton(
                            label: 'Normal',
                            value: 1.0,
                            isSelected: accessibility.fontSizeMultiplier == 1.0,
                            onTap: () => accessibility.setFontSize(1.0),
                            fontScale: fontScale,
                            touchTargetSize: touchTargetSize,
                          ),
                          const SizedBox(width: 8),
                          _FontSizeButton(
                            label: 'Medium',
                            value: 1.5,
                            isSelected: accessibility.fontSizeMultiplier == 1.5,
                            onTap: () => accessibility.setFontSize(1.5),
                            fontScale: fontScale,
                            touchTargetSize: touchTargetSize,
                          ),
                          const SizedBox(width: 8),
                          _FontSizeButton(
                            label: 'Large',
                            value: 2.0,
                            isSelected: accessibility.fontSizeMultiplier == 2.0,
                            onTap: () => accessibility.setFontSize(2.0),
                            fontScale: fontScale,
                            touchTargetSize: touchTargetSize,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Audio Accessibility
                sectionHeader('Audio Accessibility'),

                _SettingRow(
                  title: 'Voice Narration',
                  description: 'Read all text content aloud',
                  value: accessibility.voiceNarration,
                  onChanged: (value) => accessibility.setVoiceNarration(value),
                  fontScale: fontScale,
                  isDarkMode: isDarkMode,
                  highContrast: highContrast,
                  isSimplified: isSimplified,
                ),
                SizedBox(height: isSimplified ? 20 : 12),

                _SettingRow(
                  title: 'Haptic Feedback',
                  description: 'Vibration feedback for interactions',
                  value: accessibility.hapticFeedback,
                  onChanged: (value) => accessibility.setHapticFeedback(value),
                  fontScale: fontScale,
                  isDarkMode: isDarkMode,
                  highContrast: highContrast,
                  isSimplified: isSimplified,
                ),
                const SizedBox(height: 32),

                // Motor Accessibility
                sectionHeader('Motor Accessibility'),

                _SettingRow(
                  title: 'Large Touch Targets',
                  description: 'Increase button and tap area sizes',
                  value: accessibility.largeTouchTargets,
                  onChanged: (value) => accessibility.setLargeTouchTargets(value),
                  fontScale: fontScale,
                  isDarkMode: isDarkMode,
                  highContrast: highContrast,
                  isSimplified: isSimplified,
                ),
                SizedBox(height: isSimplified ? 20 : 12),

                _SettingRow(
                  title: 'Simplified Navigation',
                  description: 'Reduce gesture complexity',
                  value: accessibility.simplifiedNavigation,
                  onChanged: (value) => accessibility.setSimplifiedNavigation(value),
                  fontScale: fontScale,
                  isDarkMode: isDarkMode,
                  highContrast: highContrast,
                  isSimplified: isSimplified,
                ),
                const SizedBox(height: 32),

                // Mobility Accessibility
                sectionHeader('Mobility Accessibility'),

                _SettingRow(
                  title: 'Wheelchair-Friendly Filter',
                  description: 'Show only accessible heritage sites',
                  value: accessibility.wheelchairFriendlyOnly,
                  onChanged: (value) => accessibility.setWheelchairFriendly(value),
                  fontScale: fontScale,
                  isDarkMode: isDarkMode,
                  highContrast: highContrast,
                  isSimplified: isSimplified,
                ),
                const SizedBox(height: 32),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  height: touchTargetSize,
                  child: ElevatedButton(
                    onPressed: () {
                      accessibility.triggerHapticAndVoice('Reset Settings');
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Reset Settings',
                            style: TextStyle(fontSize: 18 * fontScale),
                          ),
                          content: Text(
                            'Are you sure you want to reset all accessibility settings to default?',
                            style: TextStyle(fontSize: 16 * fontScale),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                accessibility.triggerHapticAndVoice('Cancel reset');
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Cancel',
                                style: TextStyle(fontSize: 16 * fontScale),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                accessibility.resetToDefaults();
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 16 * fontScale,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSimplified ? 0 : 12),
                      ),
                    ),
                    child: Text(
                      'Reset to Defaults',
                      style: TextStyle(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Setting Row ----------------
class _SettingRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final Function(bool) onChanged;
  final double fontScale;
  final bool isDarkMode;
  final bool highContrast;
  final bool isSimplified;

  const _SettingRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.fontScale,
    required this.isDarkMode,
    required this.highContrast,
    required this.isSimplified,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = highContrast
        ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
        : (isDarkMode ? Colors.grey[900] : Colors.grey[50]);
    final textColor = highContrast
        ? (isDarkMode ? Colors.white : Colors.black)
        : (isDarkMode ? Colors.white : Colors.black);

    return Semantics(
      label: '$title: ${value ? 'Enabled' : 'Disabled'}',
      hint: isSimplified ? null : description,
      child: Container(
        padding: EdgeInsets.all(isSimplified ? 20 : 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(isSimplified ? 0 : 12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: isSimplified ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: (isSimplified ? 18 : 16) * fontScale,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (!isSimplified) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14 * fontScale,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: value,
              onChanged: (val) {
                onChanged(val);
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Font Size Button ----------------
class _FontSizeButton extends StatelessWidget {
  final String label;
  final double value;
  final bool isSelected;
  final VoidCallback onTap;
  final double fontScale;
  final double touchTargetSize;

  const _FontSizeButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
    required this.fontScale,
    required this.touchTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Font size $label',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: touchTargetSize * 0.8,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[400]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
