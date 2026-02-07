import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import 'ar_explorer_screen.dart';
import 'report_issue_screen.dart';
import 'accessibility_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key, required this.onTabSelected}) : super(key: key);
  final Function(int) onTabSelected;

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityService>(context);
    final fontScale = accessibility.fontSizeMultiplier;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final highContrast = accessibility.highContrast;

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
              // Hero Section
              Center(
                child: Column(
                  children: [
                    Semantics(
                      label: 'CityConnect app title',
                      child: Text(
                        'CityConnect',
                        style: TextStyle(
                          fontSize: 36 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your inclusive smart city companion',
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Action Cards
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              // AR Explorer Card
              _QuickActionCard(
                title: 'Explore Heritage',
                description: 'Scan landmarks with AR',
                icon: Icons.camera_alt,
                color: Colors.blue,
                onTap: () => _navigateToTab(1), 
                fontScale: fontScale,
                highContrast: highContrast,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),

              // Report Issue Card
              _QuickActionCard(
                title: 'Report Issue',
                description: 'Report city problems',
                icon: Icons.warning_amber,
                color: Colors.amber,
                onTap: () => _navigateToTab(2), 
                fontScale: fontScale,
                highContrast: highContrast,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),

              // Accessibility Card
              _QuickActionCard(
                title: 'Accessibility',
                description: 'Customize your experience',
                icon: Icons.accessibility,
                color: Colors.green,
                onTap: () => _navigateToTab(3), 
                fontScale: fontScale,
                highContrast: highContrast,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 32),

              // Info Section
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
                  'Explore cultural heritage through AR, report city issues, and enjoy a fully accessible experience designed for everyone.',
                  style: TextStyle(
                    fontSize: 16 * fontScale,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Accessibility Status
              if (accessibility.highContrast ||
                  accessibility.voiceNarration ||
                  accessibility.fontSizeMultiplier > 1 ||
                  accessibility.wheelchairFriendlyOnly)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accessibility Features Active:',
                        style: TextStyle(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (accessibility.highContrast)
                        Text(
                          '• High Contrast Mode',
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: textColor,
                          ),
                        ),
                      if (accessibility.voiceNarration)
                        Text(
                          '• Voice Narration',
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: textColor,
                          ),
                        ),
                      if (accessibility.fontSizeMultiplier > 1)
                        Text(
                          '• Large Font (${accessibility.fontSizeMultiplier}x)',
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: textColor,
                          ),
                        ),
                      if (accessibility.wheelchairFriendlyOnly)
                        Text(
                          '• Wheelchair-Friendly Filter',
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: textColor,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // void _navigateToTab(BuildContext context, int index) {
  //   // This will be handled by the parent MainScreen
  //   // You can use a callback or state management
  // }
  void _navigateToTab(int index) {
    onTabSelected(index);
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double fontScale;
  final bool highContrast;
  final bool isDarkMode;

  const _QuickActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.fontScale,
    required this.highContrast,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = highContrast
        ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
        : (isDarkMode ? Colors.grey[900] : Colors.grey[50]);
    final textColor = highContrast
        ? (isDarkMode ? Colors.white : Colors.black)
        : (isDarkMode ? Colors.white : Colors.black);

    final touchTargetSize =
        Provider.of<AccessibilityService>(context).largeTouchTargets
            ? 80.0
            : 60.0;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14 * fontScale,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
