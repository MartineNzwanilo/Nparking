import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../services/printing_service.dart';

class LodgemanDashboardScreen extends StatefulWidget {
  const LodgemanDashboardScreen({super.key});

  @override
  State<LodgemanDashboardScreen> createState() => _LodgemanDashboardScreenState();
}

class _LodgemanDashboardScreenState extends State<LodgemanDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String _currentStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final statuses = ['PENDING', 'APPROVED', 'REJECTED'];
        setState(() {
          _currentStatus = statuses[_tabController.index];
        });
        _fetchRequests();
      }
    });
    _fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final data = await api.get('/sessions/lodge/requests?status=$_currentStatus');
      setState(() {
        _requests = data;
      });
    } catch (e) {
      debugPrint('Failed to fetch lodge requests: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showApproveDialog(String sessionId, String plateNumber) {
    final roomController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Approve Free Parking', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approving free parking for $plateNumber. Please enter the room number:', style: TextStyle(color: AppTheme.textSecondary(context))),
            const SizedBox(height: 16),
            TextField(
              controller: roomController,
              decoration: InputDecoration(
                labelText: 'Room Number',
                prefixIcon: const Icon(LucideIcons.doorOpen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (roomController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _handleApprove(sessionId, roomController.text.trim());
            },
            child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String sessionId, String plateNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
        content: Text('Are you sure you want to reject the free parking request for $plateNumber?', style: TextStyle(color: AppTheme.textSecondary(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleReject(sessionId);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(String sessionId, String roomNumber) async {
    try {
      final api = ApiService();
      await api.post('/sessions/$sessionId/lodge-approve', {'roomNumber': roomNumber});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved.'), backgroundColor: AppTheme.success));
      _fetchRequests();
    } catch (e) {
      debugPrint('Error approving: $e');
    }
  }

  Future<void> _handleReject(String sessionId) async {
    try {
      final api = ApiService();
      await api.post('/sessions/$sessionId/lodge-reject', {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.')));
      _fetchRequests();
    } catch (e) {
      debugPrint('Error rejecting: $e');
    }
  }

  Future<void> _printReceipt(Map<String, dynamic> req) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Printing authorization for ${req['vehicle']?['plateNumber']}...'), backgroundColor: AppTheme.primary)
    );
    try {
      await PrintingService.printLodgeAuthorization(context, req);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printed successfully!'), backgroundColor: AppTheme.success)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e'), backgroundColor: AppTheme.error)
        );
      }
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withOpacity(0.8), letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final plate = req['vehicle']?['plateNumber'] ?? 'Unknown';
    final category = req['vehicle']?['category']?['name'] ?? 'Vehicle';
    final watchmanName = req['watchman']?['name'] ?? 'Unknown';
    final checkInTime = req['checkIn'] != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(req['checkIn'])) : 'Unknown';
    final roomNumber = req['lodgeRoomNumber'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;
    if (_currentStatus == 'PENDING') {
      statusColor = AppTheme.warning;
      statusIcon = LucideIcons.clock;
    } else if (_currentStatus == 'APPROVED') {
      statusColor = AppTheme.success;
      statusIcon = LucideIcons.checkCircle;
    } else {
      statusColor = AppTheme.error;
      statusIcon = LucideIcons.xCircle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.car, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plate, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary(context))),
                      Text(category, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context))),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 6),
                    Text(_currentStatus, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: AppTheme.textSecondary(context)),
              const SizedBox(width: 8),
              Text('Check-in: $checkInTime', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.user, size: 14, color: AppTheme.textSecondary(context)),
              const SizedBox(width: 8),
              Text('Watchman: $watchmanName', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary(context))),
            ],
          ),
          if (roomNumber != null && roomNumber.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.doorOpen, size: 14, color: AppTheme.success),
                const SizedBox(width: 8),
                Text('Room No: $roomNumber', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.success)),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (_currentStatus == 'PENDING')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showRejectDialog(req['id'], plate),
                    icon: const Icon(LucideIcons.xCircle, size: 18),
                    label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showApproveDialog(req['id'], plate),
                    icon: const Icon(LucideIcons.checkCircle, size: 18),
                    label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          if (_currentStatus == 'APPROVED')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _printReceipt(req),
                icon: const Icon(LucideIcons.printer, size: 18),
                label: const Text('Print Authorization Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _currentStatus == 'PENDING' ? _requests.length : 0; // Rough local stat
    final approvedCount = _currentStatus == 'APPROVED' ? _requests.length : 0; // Rough local stat

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Lodge Dashboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [
          IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _fetchRequests),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary(context),
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStatCard('TOTAL ${_currentStatus.toUpperCase()}', '${_requests.length}', LucideIcons.car, _currentStatus == 'PENDING' ? AppTheme.warning : (_currentStatus == 'APPROVED' ? AppTheme.success : AppTheme.error)),
                const SizedBox(width: 16),
                _buildStatCard('ACTION REQ', _currentStatus == 'PENDING' ? '${_requests.length}' : '0', LucideIcons.bellRing, AppTheme.primary),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.checkCircle, size: 64, color: AppTheme.textSecondary(context).withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('No $_currentStatus requests', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchRequests,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(_requests[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
