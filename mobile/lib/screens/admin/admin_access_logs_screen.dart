import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';

class AdminAccessLogsScreen extends StatefulWidget {
  const AdminAccessLogsScreen({super.key});

  @override
  State<AdminAccessLogsScreen> createState() => _AdminAccessLogsScreenState();
}

class _AdminAccessLogsScreenState extends State<AdminAccessLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAccessLogs();
    });
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return '—';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }

  String _getRelativeTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final logs = adminProv.accessLogs;
    final isLoading = adminProv.isLoadingAccessLogs;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Access Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => adminProv.fetchAccessLogs(),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.history,
                          size: 48,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white10
                              : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No access logs registered yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final action = log['action']?.toString() ?? 'LOGIN';
                      final isLogin = action == 'LOGIN';
                      final userName = log['user']?['name']?.toString() ?? 'Unknown User';
                      final userPhone = log['user']?['phone']?.toString() ?? '';
                      final details = log['details']?.toString() ?? '';
                      final relativeTime = _getRelativeTime(log['createdAt']?.toString());
                      final exactTime = _formatTimestamp(log['createdAt']?.toString());

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Action Indicator Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isLogin ? AppTheme.success.withOpacity(0.15) : AppTheme.error.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isLogin ? LucideIcons.logIn : LucideIcons.logOut,
                                color: isLogin ? AppTheme.success : AppTheme.error,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Log Meta Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userName,
                                          style: TextStyle(
                                            color: AppTheme.textPrimary(context),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (relativeTime.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          relativeTime,
                                          style: TextStyle(
                                            color: AppTheme.textSecondary(context),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (userPhone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      userPhone,
                                      style: TextStyle(
                                        color: AppTheme.textSecondary(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    details,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary(context).withOpacity(0.85),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    exactTime,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context).withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
