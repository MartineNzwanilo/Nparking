import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../widgets/complex_animations.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/printing_service.dart';
import '../core/api_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Check-Ins', 'Check-Outs'];
  
  bool _isSelectionMode = false;
  final Set<String> _selectedSessionIds = {};
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30)),
      end: DateTime(now.year, now.month, now.day),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ActivityProvider>().fetchActivities(
          startDate: _selectedDateRange!.start,
          endDate: _selectedDateRange!.end,
        );
      }
    });
  }

  String _getSessionId(String activityId) {
    if (activityId.startsWith('in_')) return activityId.substring(3);
    if (activityId.startsWith('out_')) return activityId.substring(4);
    return activityId;
  }

  void _toggleSelection(String sessionId) {
    setState(() {
      if (_selectedSessionIds.contains(sessionId)) {
        _selectedSessionIds.remove(sessionId);
        if (_selectedSessionIds.isEmpty) _isSelectionMode = false;
      } else {
        _isSelectionMode = true;
        _selectedSessionIds.add(sessionId);
      }
    });
  }

  String _formatRelativeTime(BuildContext context, String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return context.t.tr('justNow');
      if (diff.inHours < 1) {
        return context.t.tr('minutesAgo', {'minutes': '${diff.inMinutes}'});
      }
      if (diff.inDays < 1) {
        return context.t.tr('hoursAgo', {'hours': '${diff.inHours}'});
      }
      return context.t.tr('daysAgo', {'days': '${diff.inDays}'});
    } catch (e) {
      return '';
    }
  }

  void _showReceiptPreview(BuildContext context, Map<String, dynamic> activity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top sheet bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.t.tr('receiptPreview'),
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(LucideIcons.x, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Digital receipt card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "NPS TICKET",
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activity['title']?.toString() ?? context.t.tr('unknownReceipt'),
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity['subtitle']?.toString() ?? '',
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      _buildDashedLine(context),
                      const SizedBox(height: 20),
                      
                      // Key-Value Receipt Details
                      _buildReceiptRow(context, context.t.tr('statusLabel'), activity['type']?.toString() ?? '', isValueAccent: true),
                      const SizedBox(height: 12),
                      if (activity['propertiesLeft'] != null && activity['propertiesLeft'].toString().trim().isNotEmpty) ...[
                        _buildReceiptRow(context, 'Properties', activity['propertiesLeft'].toString()),
                        const SizedBox(height: 12),
                      ],
                      _buildReceiptRow(context, context.t.tr('timestampLabel'), activity['timestamp']?.toString().substring(0, 16) ?? ''),
                      
                      const SizedBox(height: 20),
                      _buildDashedLine(context),
                      const SizedBox(height: 20),
                      
                      // Mock Barcode
                      Center(
                        child: Opacity(
                          opacity: isDark ? 0.75 : 0.9,
                          child: Column(
                            children: [
                              Container(
                                height: 45,
                                width: 220,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark 
                                        ? [Colors.white24, Colors.white10, Colors.white24, Colors.white12]
                                        : [Colors.black54, Colors.black26, Colors.black54, Colors.black12],
                                    stops: const [0.15, 0.45, 0.75, 1.0],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "SYS-${_getSessionId(activity['id'].toString()).toUpperCase()}",
                                style: const TextStyle(fontSize: 10, letterSpacing: 3.0, color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final sessionId = _getSessionId(activity['id'].toString());
                            try {
                              final api = ApiService();
                              final session = await api.get('/sessions/$sessionId');
                              Navigator.pop(ctx);
                              await PrintingService.showPrintDialog(context, session);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to load full ticket for printing.')),
                                );
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.printer, color: Colors.white, size: 16),
                          label: const Text(
                            'Print Ticket',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary(context),
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final receiptText = [
                              "=== NPS RECEIPT ===",
                              '${context.t.tr('titleLabel')}: ${activity['title'] ?? context.t.tr('notAvailable')}',
                              '${context.t.tr('detailsLabel')}: ${activity['subtitle'] ?? context.t.tr('notAvailable')}',
                              '${context.t.tr('statusLabel')}: ${activity['type'] ?? context.t.tr('notAvailable')}',
                              '${context.t.tr('timestampLabel')}: ${activity['timestamp'] ?? context.t.tr('notAvailable')}',
                            ].join('\n');
                            Clipboard.setData(ClipboardData(text: receiptText));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.t.tr('receiptCopied'))),
                            );
                          },
                          icon: const Icon(LucideIcons.copy, size: 16),
                          label: Text(
                            context.t.tr('copyReceipt'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      if (context.read<AuthProvider>().isAdmin) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: BorderSide(color: AppTheme.error.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Theme.of(context).cardTheme.color,
                                  title: Text(context.t.tr('confirmDelete'), style: TextStyle(color: AppTheme.textPrimary(context))),
                                  content: Text(
                                    context.t.tr('areYouSureDeleteActivity'),
                                    style: TextStyle(color: AppTheme.textSecondary(context)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(context.t.tr('cancel'), style: TextStyle(color: AppTheme.textSecondary(context))),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(context.t.tr('delete')),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                Navigator.pop(context); // Close receipt sheet
                                try {
                                  final sessionId = _getSessionId(activity['id'].toString());
                                  await context.read<ActivityProvider>().deleteActivity(sessionId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(context.t.tr('activityDeleted'))),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(context.t.tr('failedDeleteActivity'))),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(LucideIcons.trash2, size: 16),
                            label: Text(
                              context.t.tr('deleteActivity'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDashedLine(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 
                ? (isDark ? Colors.white12 : Colors.black12) 
                : Colors.transparent,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(BuildContext context, String key, String value, {bool isValueAccent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: isValueAccent ? AppTheme.primary : AppTheme.textPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _selectedSessionIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Theme.of(context).cardTheme.color,
                    title: Text(context.t.tr('confirmBulkDelete'), style: TextStyle(color: AppTheme.textPrimary(context))),
                    content: Text(
                      context.t.tr('areYouSureBulkDelete'),
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.t.tr('cancel'), style: TextStyle(color: AppTheme.textSecondary(context))),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(context.t.tr('delete')),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  try {
                    await context.read<ActivityProvider>().bulkDeleteActivities(_selectedSessionIds.toList());
                    setState(() {
                      _selectedSessionIds.clear();
                      _isSelectionMode = false;
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.t.tr('activitiesDeleted'))),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.t.tr('failedDeleteActivities'))),
                      );
                    }
                  }
                }
              },
              backgroundColor: AppTheme.error,
              icon: const Icon(LucideIcons.trash2, color: Colors.white),
              label: Text(
                'Delete ${_selectedSessionIds.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t.tr('activity'),
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendarDays, color: AppTheme.primary),
            onPressed: () async {
              final initialRange = _selectedDateRange ?? DateTimeRange(
                start: DateTime.now(),
                end: DateTime.now(),
              );
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final newRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: initialRange,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: isDark 
                          ? const ColorScheme.dark(
                              primary: AppTheme.primary,
                              onPrimary: Colors.white,
                              surface: Color(0xFF1E1E1E),
                              onSurface: Colors.white,
                            )
                          : const ColorScheme.light(
                              primary: AppTheme.primary,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                    ),
                    child: child!,
                  );
                },
              );
              if (newRange != null && mounted) {
                setState(() {
                  _selectedDateRange = newRange;
                });
                context.read<ActivityProvider>().fetchActivities(
                  startDate: newRange.start,
                  endDate: newRange.end,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.printer, color: AppTheme.primary),
            onPressed: () async {
              final activities = context.read<ActivityProvider>().activities.cast<Map<String, dynamic>>();
              if (activities.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.t.tr('noReceiptYet'))),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing Activity Report...')),
              );
              try {
                await PrintingService.printActivityReport(context, activities);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to print: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters (Tesla Horizontal Style)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: _filters.map((filter) {
                  bool isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        _filterLabel(context, filter),
                        style: TextStyle(
                          color: isSelected 
                              ? (isDark ? Colors.black : Colors.white) 
                              : AppTheme.textPrimary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: isDark ? Colors.white : Colors.black,
                      backgroundColor: Theme.of(context).cardTheme.color,
                      side: BorderSide(
                        color: isSelected 
                            ? (isDark ? Colors.white : Colors.black) 
                            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.08)),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Activity List
            Expanded(
              child: Consumer<ActivityProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }
                  final activities = provider.activities.cast<Map<String, dynamic>>();
                  
                  final filteredActivities = activities.where((a) {
                    if (_selectedFilter == 'Check-Ins' && a['type'] != 'Check-In') return false;
                    if (_selectedFilter == 'Check-Outs' && a['type'] != 'Check-Out') return false;
                    
                    if (_selectedDateRange != null) {
                      final date = DateTime.tryParse(a['timestamp'] ?? '')?.toLocal();
                      if (date != null) {
                        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day, 0, 0, 0);
                        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59, 999);
                        if (date.isBefore(start) || date.isAfter(end)) return false;
                      }
                    }
                    return true;
                  }).toList();

                  if (filteredActivities.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => provider.fetchActivities(
                        startDate: _selectedDateRange?.start,
                        endDate: _selectedDateRange?.end,
                      ),
                      color: AppTheme.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: CameraScanningCarAnimation(
                            title: context.t.tr('noRecentActivity'),
                            subtitle: context.t.tr('noActivityFound'),
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchActivities(
                      startDate: _selectedDateRange?.start,
                      endDate: _selectedDateRange?.end,
                    ),
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: filteredActivities.length,
                      itemBuilder: (context, index) {
                        final activity = filteredActivities[index];
                        final isCheckIn = activity['type'] == 'Check-In';
                        final color = isCheckIn ? AppTheme.primary : AppTheme.success;
                        final icon = isCheckIn ? LucideIcons.logIn : LucideIcons.logOut;

                        final sessionId = _getSessionId(activity['id'].toString());
                        final isSelected = _selectedSessionIds.contains(sessionId);

                        return GestureDetector(
                          onLongPress: () {
                            if (context.read<AuthProvider>().isAdmin) {
                              _toggleSelection(sessionId);
                            }
                          },
                          onTap: () {
                            if (_isSelectionMode && context.read<AuthProvider>().isAdmin) {
                              _toggleSelection(sessionId);
                            } else {
                              _showReceiptPreview(context, activity);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.primary.withOpacity(0.08) 
                                  : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isSelectionMode && context.read<AuthProvider>().isAdmin)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                                    child: Checkbox(
                                      value: isSelected,
                                      activeColor: AppTheme.primary,
                                      onChanged: (val) {
                                        _toggleSelection(sessionId);
                                      },
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 22),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              activity['title'] ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppTheme.textPrimary(context),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatRelativeTime(context, activity['timestamp']),
                                            style: TextStyle(
                                              color: AppTheme.textSecondary(context),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        activity['subtitle'] ?? '',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary(context),
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () async {
                                            final sessionId = _getSessionId(activity['id'].toString());
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Reprinting ticket...')),
                                            );
                                            try {
                                              final session = await context.read<VehicleProvider>().fetchSessionDetails(sessionId);
                                              await PrintingService.printTicket(context, session);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Failed to reprint ticket: $e')),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(LucideIcons.printer, size: 14, color: AppTheme.primary),
                                          label: Text(
                                            context.t.tr('reprintTicket'),
                                            style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(BuildContext context, String filter) {
    switch (filter) {
      case 'All':
        return context.t.tr('all');
      case 'Check-Ins':
        return context.t.tr('checkIns');
      case 'Check-Outs':
        return context.t.tr('checkOuts');
      default:
        return filter;
    }
  }
}
