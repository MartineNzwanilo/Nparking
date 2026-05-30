import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';

class AdminWatchmenScreen extends StatefulWidget {
  const AdminWatchmenScreen({super.key});

  @override
  State<AdminWatchmenScreen> createState() => _AdminWatchmenScreenState();
}

class _AdminWatchmenScreenState extends State<AdminWatchmenScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
      context.read<AdminProvider>().fetchSites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditUserDialog(BuildContext context, [Map<String, dynamic>? editingUser]) {
    final isEdit = editingUser != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: editingUser?['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: editingUser?['phone']?.toString() ?? '');
    final emailController = TextEditingController(text: editingUser?['email']?.toString() ?? '');
    final passwordController = TextEditingController();

    String selectedRole = editingUser?['role']?.toString() ?? 'WATCHMAN';
    String? selectedSiteId = editingUser?['site']?['id']?.toString() ?? editingUser?['siteId']?.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sites = context.watch<AdminProvider>().sites;

            // Ensure site ID exists in active list, else fallback to null
            final siteIds = sites.map((s) => s['id']?.toString()).toList();
            if (selectedSiteId != null && !siteIds.contains(selectedSiteId)) {
              selectedSiteId = null;
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                isEdit ? 'Edit Staff Member' : 'Register Staff Member',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      // Full Name
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(LucideIcons.user, size: 18),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Phone Number
                      TextFormField(
                        controller: phoneController,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(LucideIcons.phone, size: 18),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Email (Optional)
                      TextFormField(
                        controller: emailController,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address (Optional)',
                          prefixIcon: const Icon(LucideIcons.mail, size: 18),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: passwordController,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: isEdit ? 'New Password (Leave blank to keep)' : 'Password',
                          prefixIcon: const Icon(LucideIcons.lock, size: 18),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (v) {
                          if (!isEdit && (v == null || v.trim().isEmpty)) {
                            return 'Password is required for registration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                        decoration: InputDecoration(
                          labelText: 'Access Role',
                          prefixIcon: const Icon(LucideIcons.briefcase, size: 18),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'WATCHMAN', child: Text('Watchman / Operator')),
                          DropdownMenuItem(value: 'ADMIN', child: Text('System Administrator')),
                        ],
                        onChanged: (val) => setDialogState(() => selectedRole = val ?? 'WATCHMAN'),
                      ),
                      const SizedBox(height: 12),

                      // Site Selection Dropdown
                      DropdownButtonFormField<String?>(
                        value: selectedSiteId,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                        decoration: InputDecoration(
                          labelText: 'Assigned Site Location',
                          prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Global (All Sites)')),
                          ...sites.map((s) => DropdownMenuItem<String?>(
                                value: s['id']?.toString(),
                                child: Text(s['name']?.toString() ?? 'Unnamed Site'),
                              )),
                        ],
                        onChanged: (val) => setDialogState(() => selectedSiteId = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final data = <String, dynamic>{
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'email': emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                      'role': selectedRole,
                      'siteId': selectedSiteId,
                    };
                    if (passwordController.text.isNotEmpty) {
                      data['password'] = passwordController.text;
                    }

                    try {
                      final adminProv = context.read<AdminProvider>();
                      if (isEdit) {
                        await adminProv.updateUser(editingUser['id'], data);
                      } else {
                        await adminProv.createUser(data);
                      }
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit ? 'Staff member details updated.' : 'Staff member registered.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Operation failed. Check credentials/phone availability.'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEdit ? 'SAVE' : 'REGISTER', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Access?'),
        content: Text('Are you sure you want to suspend access credentials for ${user['name']}? they will no longer be able to log in to operators screens.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<AdminProvider>().deleteUser(user['id']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Staff member ${user['name']} suspended.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to suspend staff member.')),
                  );
                }
              }
            },
            child: const Text('SUSPEND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'OP';
    if (parts.length == 1) {
      final val = parts.first;
      return val.length >= 2 ? val.substring(0, 2).toUpperCase() : val.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final users = adminProv.users;
    final isLoading = adminProv.isLoadingUsers;

    final filteredUsers = users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final phone = (u['phone'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Staff Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: AppTheme.primary),
            onPressed: () => _showAddEditUserDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Search operators by name, phone...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
                    prefixIcon: Icon(LucideIcons.search, size: 18, color: AppTheme.textSecondary(context)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.users,
                                size: 48,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white10
                                    : Colors.black12,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No staff members found',
                                style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filteredUsers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final u = filteredUsers[index];
                            final initials = _getInitials(u['name']?.toString() ?? '');
                            final isAdmin = u['role'] == 'ADMIN';
                            final siteName = u['site']?['name']?.toString() ?? 'Global (All Sites)';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isAdmin ? AppTheme.warning.withOpacity(0.15) : AppTheme.primary.withOpacity(0.15),
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: isAdmin ? AppTheme.warning : AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                u['name']?.toString() ?? 'Unnamed Operator',
                                                style: TextStyle(
                                                  color: AppTheme.textPrimary(context),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isAdmin ? AppTheme.warning.withOpacity(0.15) : AppTheme.primary.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                u['role']?.toString() ?? 'WATCHMAN',
                                                style: TextStyle(
                                                  color: isAdmin ? AppTheme.warning : AppTheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          u['phone']?.toString() ?? '',
                                          style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(LucideIcons.mapPin, size: 12, color: AppTheme.textSecondary(context)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                siteName,
                                                style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(LucideIcons.edit3, color: AppTheme.textSecondary(context), size: 18),
                                        onPressed: () => _showAddEditUserDialog(context, u),
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.userX, color: AppTheme.error, size: 18),
                                        onPressed: () => _confirmDeleteUser(context, u),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
