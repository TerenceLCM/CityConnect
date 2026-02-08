import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import 'report_issue_screen.dart';
import 'package:geocoding/geocoding.dart';

class IssuesFeedScreen extends StatefulWidget {
  const IssuesFeedScreen({Key? key}) : super(key: key);

  @override
  State<IssuesFeedScreen> createState() => _IssuesFeedScreenState();
}

class _IssuesFeedScreenState extends State<IssuesFeedScreen> {
  late Future<List<Map<String, dynamic>>> _issuesFuture;
  String _selectedFilter = 'all'; // all, pending, in_progress, resolved

  final List<Map<String, String>> statusFilters = [
    {'value': 'all', 'label': 'All Issues'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'in_progress', 'label': 'In Progress'},
    {'value': 'resolved', 'label': 'Resolved'},
  ];

  final Map<String, Color> statusColors = {
    'pending': Colors.orange,
    'in_progress': Colors.blue,
    'resolved': Colors.green,
  };

  final Map<String, String> categoryLabels = {
    'road_damage': '🚧 Road Damage',
    'waste_management': '🗑️ Waste Management',
    'street_lighting': '💡 Street Lighting',
    'public_facilities': '🏛️ Public Facilities',
    'accessibility_issues': '♿ Accessibility Issues',
    'other': '📝 Other',
  };

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  void _loadIssues() {
    setState(() {
      _issuesFuture = ApiService.getIssuesList(
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
    });
  }

  String _formatDate(String dateString) {
    try {
      // Parse the string as UTC
      final dateUtc = DateTime.parse(dateString).toUtc();

      // Convert to KL time (UTC+8)
      final date = dateUtc.add(const Duration(hours: 8));

      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  Future<String> _getLocationString(double? lat, double? lng) async {
  if (lat == null || lng == null) return 'Unknown location';
  try {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      final areaParts = [
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ].where((e) => e != null && e!.isNotEmpty).join(', ');
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} ($areaParts)';
    }
  } catch (e, st) {
    debugPrint('Geocoding failed: $e\n$st');
    return 'Unknown location';
  }
  return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}

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
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Title Row with Add Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Issues Feed',
                      style: TextStyle(
                        fontSize: 30 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: textColor,
                      tooltip: 'Report New Issue',
                      iconSize: 28,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportIssueScreen()),
                        );
                        if (result == true) {
                          _loadIssues();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'See what issues are being reported in your city',
                  style: TextStyle(
                    fontSize: 16 * fontScale,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statusFilters.map((filter) {
                  final isSelected = _selectedFilter == filter['value'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        filter['label']!,
                        style: TextStyle(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter['value']!);
                        _loadIssues();
                      },
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      selectedColor: Colors.blue.withOpacity(0.2),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Issues List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _issuesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading issues...',
                          style: TextStyle(fontSize: 16 * fontScale),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading issues',
                          style: TextStyle(
                            fontSize: 16 * fontScale,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final issues = snapshot.data ?? [];

                if (issues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Colors.green.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No issues reported',
                          style: TextStyle(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Great! Your city is in good shape.',
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    final status = issue['status'] ?? 'pending';
                    final category = issue['category'] ?? 'other';

                    return _IssueCard(
                      issue: issue,
                      status: status,
                      category: category,
                      categoryLabel:
                          categoryLabels[category] ?? '📝 ${category}',
                      statusColor: statusColors[status] ?? Colors.grey,
                      fontScale: fontScale,
                      isDarkMode: isDarkMode,
                      highContrast: highContrast,
                      formatDate: _formatDate,
                      getLocationString: _getLocationString,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final Map<String, dynamic> issue;
  final String status;
  final String category;
  final String categoryLabel;
  final Color statusColor;
  final double fontScale;
  final bool isDarkMode;
  final bool highContrast;
  final String Function(String) formatDate;
  final Future<String> Function(double?, double?) getLocationString;

  const _IssueCard({
    required this.issue,
    required this.status,
    required this.category,
    required this.categoryLabel,
    required this.statusColor,
    required this.fontScale,
    required this.isDarkMode,
    required this.highContrast,
    required this.formatDate,
    required this.getLocationString,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = highContrast
        ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
        : (isDarkMode ? Colors.grey[900] : Colors.grey[50]);
    final textColor = highContrast
        ? (isDarkMode ? Colors.white : Colors.black)
        : (isDarkMode ? Colors.white : Colors.black);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    categoryLabel,
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            if (issue['description'] != null && issue['description'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  issue['description'],
                  style: TextStyle(
                    fontSize: 14 * fontScale,
                    color: textColor,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Location and Time
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                child: FutureBuilder<String>(
                  future: getLocationString(
                    issue['latitude'],
                    issue['longitude'],
                  ),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Loading location...',
                      style: TextStyle(
                        fontSize: 12 * fontScale,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ],
          ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  formatDate(issue['createdAt'] ?? ''),
                  style: TextStyle(
                    fontSize: 12 * fontScale,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // Photo Indicator
            if (issue['photoBase64'] != null)
              // Photo Indicator
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GestureDetector(
                  onTap: () {
                    try {
                      String base64String = issue['photoBase64'] ?? '';

                      if (base64String.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No image available')),
                        );
                        return;
                      }

                      // 🔹 Remove data:image/... prefix if exists
                      if (base64String.contains(',')) {
                        base64String = base64String.split(',')[1];
                      }

                      // 🔹 Remove whitespace / line breaks
                      base64String = base64String.replaceAll(RegExp(r'\s+'), '');

                      // 🔹 Fix padding
                      while (base64String.length % 4 != 0) {
                        base64String += '=';
                      }

                      final bytes = base64Decode(base64String);

                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            backgroundColor: Colors.black,
                            child: InteractiveViewer(
                              child: Image.memory(
                                bytes,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Image decode failed: $e')),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.image, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        'Photo attached',
                        style: TextStyle(
                          fontSize: 12 * fontScale,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          // decoration: TextDecoration
                          //     .underline, // optional: looks clickable
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // View Details Button
            // const SizedBox(height: 12),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     onPressed: () {
            //       // Show issue details modal
            //       _showIssueDetails(context);
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.blue.withOpacity(0.2),
            //       foregroundColor: Colors.blue,
            //     ),
            //     child: Text(
            //       'View Details',
            //       style: TextStyle(
            //         fontSize: 14 * fontScale,
            //         fontWeight: FontWeight.w600,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  void _showIssueDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Issue Details',
                  style: TextStyle(
                    fontSize: 20 * fontScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Category: $categoryLabel',
                  style: TextStyle(fontSize: 14 * fontScale),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${status.replaceAll('_', ' ').toUpperCase()}',
                  style: TextStyle(
                    fontSize: 14 * fontScale,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Location: ${getLocationString(issue['latitude'], issue['longitude'])}',
                  style: TextStyle(fontSize: 14 * fontScale),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reported: ${formatDate(issue['createdAt'] ?? '')}',
                  style: TextStyle(fontSize: 14 * fontScale),
                ),
                if (issue['description'] != null &&
                    issue['description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description:',
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          issue['description'],
                          style: TextStyle(fontSize: 14 * fontScale),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
 