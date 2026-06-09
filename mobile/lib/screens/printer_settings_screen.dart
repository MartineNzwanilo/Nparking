import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme.dart';
import '../services/printer_discovery_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../core/api_service.dart';

class NetworkPrinter {
  String id;
  String name;
  String ip;
  bool isDefault;
  bool printSimultaneously;

  NetworkPrinter({
    required this.id,
    required this.name,
    required this.ip,
    this.isDefault = false,
    this.printSimultaneously = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'isDefault': isDefault,
        'printSimultaneously': printSimultaneously,
      };

  factory NetworkPrinter.fromJson(Map<String, dynamic> json) => NetworkPrinter(
        id: json['id'],
        name: json['name'],
        ip: json['ip'],
        isDefault: json['isDefault'] ?? false,
        printSimultaneously: json['printSimultaneously'] ?? true,
      );
}

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  bool _isScanning = false;
  List<String> _discoveredPrinters = [];
  List<NetworkPrinter> _savedPrinters = [];
  final TextEditingController _manualIpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedPrinters();
  }

  Future<void> _loadSavedPrinters() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin) {
      try {
        final api = ApiService();
        final printers = await api.get('/printer') as List<dynamic>;
        setState(() {
          _savedPrinters = printers.map((e) => NetworkPrinter.fromJson(e)).toList();
        });
        
        // Also fetch sites for the dropdown if admin
        if (mounted) {
          context.read<AdminProvider>().fetchSites();
        }
      } catch (e) {
        print('Error fetching printers: $e');
      }
    } else {
      setState(() {
        _savedPrinters = auth.sitePrinters.map((e) => NetworkPrinter.fromJson(e)).toList();
      });
    }
  }

  Future<void> _addPrinter(String ip, String name, String siteId) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) return;
    
    try {
      final api = ApiService();
      await api.post('/printer', {
        'name': name.isEmpty ? 'Printer $ip' : name,
        'ip': ip,
        'siteId': siteId,
        'isDefault': _savedPrinters.isEmpty,
      });
      await _loadSavedPrinters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printer $name added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add printer: $e')),
        );
      }
    }
  }

  Future<void> _updatePrinter(String id, String name, String ip) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) return;

    try {
      final api = ApiService();
      await api.patch('/printer/$id', {
        'name': name.isEmpty ? 'Printer $ip' : name,
        'ip': ip,
      });
      await _loadSavedPrinters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update printer: $e')),
        );
      }
    }
  }

  Future<void> _removePrinter(String id) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) return;

    try {
      final api = ApiService();
      await api.delete('/printer/$id');
      await _loadSavedPrinters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete printer: $e')),
        );
      }
    }
  }

  void _showDeletePrinterDialog(NetworkPrinter printer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: const Text('Delete Printer'),
            content: Text('Are you sure you want to delete ${printer.name}?'),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                onPressed: isDeleting ? null : () async {
                  setStateDialog(() => isDeleting = true);
                  await _removePrinter(printer.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: isDeleting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.error, strokeWidth: 2))
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _setDefaultPrinter(String id) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) return;
    try {
      final api = ApiService();
      await api.patch('/printer/$id', {'isDefault': true});
      await _loadSavedPrinters();
    } catch (e) {}
  }

  Future<void> _toggleSimultaneous(String id, bool value) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) return;
    try {
      final api = ApiService();
      await api.patch('/printer/$id', {'printSimultaneously': value});
      await _loadSavedPrinters();
    } catch (e) {}
  }

  Future<void> _scanNetwork() async {
    setState(() {
      _isScanning = true;
      _discoveredPrinters.clear();
    });

    final ips = await PrinterDiscoveryService.discoverPrinters();

    if (mounted) {
      setState(() {
        _isScanning = false;
        _discoveredPrinters = ips;
      });
      
      if (ips.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No printers found on the local network.')),
        );
      }
    }
  }

  void _showAddNameDialog(String ip) {
    final ctrl = TextEditingController();
    String? selectedSiteId;
    
    showDialog(
      context: context,
      builder: (ctx) {
        final sites = context.read<AdminProvider>().sites;
        if (sites.isNotEmpty && selectedSiteId == null) {
          selectedSiteId = sites.first['id'];
        }
        bool isAdding = false;
        
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: const Text('Name this Printer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Main Gate, Exit Gate',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                if (sites.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Assign to Site',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedSiteId,
                    items: sites.map<DropdownMenuItem<String>>((site) {
                      return DropdownMenuItem<String>(
                        value: site['id'],
                        child: Text(site['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedSiteId = val;
                      });
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isAdding ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isAdding ? null : () async {
                  if (selectedSiteId == null && sites.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No sites available to assign printer.')),
                    );
                    return;
                  }
                  setStateDialog(() => isAdding = true);
                  await _addPrinter(ip, ctrl.text.trim(), selectedSiteId ?? context.read<AuthProvider>().siteId ?? '');
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: isAdding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditPrinterDialog(NetworkPrinter printer) {
    final nameCtrl = TextEditingController(text: printer.name);
    final ipCtrl = TextEditingController(text: printer.ip);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: const Text('Edit Printer Details'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Printer Name',
                      hintText: 'e.g., Main Gate, Exit Gate',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ipCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Printer IP Address',
                      hintText: 'e.g., 192.168.1.100',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    validator: (val) => val == null || val.trim().isEmpty ? 'IP/Hostname is required' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setStateDialog(() => isSaving = true);
                    final sanitized = ipCtrl.text.trim().replaceAll(' ', '.');
                    await _updatePrinter(printer.id, nameCtrl.text.trim(), sanitized);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Printers'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_savedPrinters.isNotEmpty) ...[
                const Text(
                  'Configured Printers (Assigned to Sites)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._savedPrinters.map((printer) => _buildPrinterCard(printer)),
                const Divider(height: 32),
              ],
              
              if (context.read<AuthProvider>().isAdmin) ...[
  
              const Text(
                'Discover Printers on Wi-Fi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure your phone and the ESC/POS printer are connected to the same Wi-Fi network.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanNetwork,
                icon: _isScanning 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.search),
                label: Text(_isScanning ? 'Scanning...' : 'Scan Network'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
  
              if (_discoveredPrinters.isNotEmpty) ...[
                const Text(
                  'Discovered Printers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _discoveredPrinters.length,
                  itemBuilder: (context, index) {
                    final ip = _discoveredPrinters[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(LucideIcons.printer, color: AppTheme.primary),
                        title: Text(ip),
                        subtitle: const Text('Port 9100'),
                        trailing: ElevatedButton(
                          onPressed: () => _showAddNameDialog(ip),
                          child: const Text('Add'),
                        ),
                      ),
                    );
                  },
                ),
              ] else if (!_isScanning) ...[
                // Manual Entry Fallback
                const SizedBox(height: 24),
                const Text(
                  'Manual Configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualIpController,
                        decoration: const InputDecoration(
                          labelText: 'Printer IP Address',
                          hintText: 'e.g., 192.168.1.100',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(LucideIcons.wifi),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_manualIpController.text.isNotEmpty) {
                          final sanitized = _manualIpController.text.trim().replaceAll(' ', '.');
                          _showAddNameDialog(sanitized);
                          _manualIpController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ],
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrinterCard(NetworkPrinter printer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: printer.isDefault ? AppTheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(LucideIcons.printer, size: 28, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(printer.ip, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                if (context.read<AuthProvider>().isAdmin)
                  IconButton(
                    icon: const Icon(LucideIcons.edit3, color: AppTheme.primary),
                    onPressed: () => _showEditPrinterDialog(printer),
                  ),
                if (context.read<AuthProvider>().isAdmin)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: AppTheme.error),
                    onPressed: () => _showDeletePrinterDialog(printer),
                  ),
              ],
            ),
            if (context.read<AuthProvider>().isAdmin) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Row(
                  children: [
                    Radio<String>(
                      value: printer.id,
                      groupValue: _savedPrinters.firstWhere((p) => p.isDefault, orElse: () => printer).id,
                      onChanged: (val) => _setDefaultPrinter(val!),
                    ),
                    const Text('Default'),
                  ],
                ),
                Row(
                  children: [
                    const Text('Print Simultaneously'),
                    Switch(
                      value: printer.printSimultaneously,
                      onChanged: (val) => _toggleSimultaneous(printer.id, val),
                    ),
                  ],
                ),
              ],
            ),
            ]
          ],
        ),
      ),
    );
  }
}
