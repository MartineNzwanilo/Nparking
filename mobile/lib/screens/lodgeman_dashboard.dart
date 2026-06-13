import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class LodgemanDashboardScreen extends StatefulWidget {
  const LodgemanDashboardScreen({super.key});

  @override
  State<LodgemanDashboardScreen> createState() => _LodgemanDashboardScreenState();
}

class _LodgemanDashboardScreenState extends State<LodgemanDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final data = await api.get('/sessions/lodge/requests');
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
        title: const Text('Approve Free Parking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approving free parking for $plateNumber. Please enter the room number:'),
            const SizedBox(height: 12),
            TextField(
              controller: roomController,
              decoration: InputDecoration(
                labelText: 'Room Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () {
              if (roomController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _handleApprove(sessionId, roomController.text.trim());
            },
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String sessionId, String plateNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text('Are you sure you want to reject the free parking request for $plateNumber?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              _handleReject(sessionId);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lodge Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _fetchRequests),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.checkCircle, size: 48, color: AppTheme.success.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No pending requests', style: TextStyle(color: AppTheme.textSecondary(context))),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final plate = req['vehicle']?['plateNumber'] ?? 'Unknown';
                    final watchmanName = req['watchman']?['name'] ?? 'Unknown';
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(plate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('PENDING', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Requested by: $watchmanName', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.error.withOpacity(0.1),
                                    foregroundColor: AppTheme.error,
                                    elevation: 0,
                                  ),
                                  onPressed: () => _showRejectDialog(req['id'], plate),
                                  icon: const Icon(LucideIcons.xCircle, size: 18),
                                  label: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _showApproveDialog(req['id'], plate),
                                  icon: const Icon(LucideIcons.checkCircle, size: 18),
                                  label: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
