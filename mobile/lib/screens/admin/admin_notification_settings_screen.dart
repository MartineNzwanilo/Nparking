import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';

class AdminNotificationSettingsScreen extends StatefulWidget {
  const AdminNotificationSettingsScreen({super.key});

  @override
  State<AdminNotificationSettingsScreen> createState() => _AdminNotificationSettingsScreenState();
}

class _AdminNotificationSettingsScreenState extends State<AdminNotificationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _enableEmailAlerts = false;
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController();
  final _smtpUserController = TextEditingController();
  final _smtpPasswordController = TextEditingController();

  bool _enableWhatsappAlerts = false;
  final _twilioAccountSidController = TextEditingController();
  final _twilioAuthTokenController = TextEditingController();
  final _twilioWhatsappNumController = TextEditingController();

  bool _enableSmsAlerts = false;
  final _twilioSmsNumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final adminProv = context.read<AdminProvider>();
      await adminProv.fetchSystemSettings();
      final settings = adminProv.systemSettings;
      if (settings != null) {
        setState(() {
          _enableEmailAlerts = settings['enableEmailAlerts'] ?? false;
          _smtpHostController.text = settings['smtpHost']?.toString() ?? '';
          _smtpPortController.text = settings['smtpPort']?.toString() ?? '587';
          _smtpUserController.text = settings['smtpUser']?.toString() ?? '';
          _smtpPasswordController.text = settings['smtpPassword']?.toString() ?? '';

          _enableWhatsappAlerts = settings['enableWhatsappAlerts'] ?? false;
          _twilioAccountSidController.text = settings['twilioAccountSid']?.toString() ?? '';
          _twilioAuthTokenController.text = settings['twilioAuthToken']?.toString() ?? '';
          _twilioWhatsappNumController.text = settings['twilioWhatsappNum']?.toString() ?? '';

          _enableSmsAlerts = settings['enableSmsAlerts'] ?? false;
          _twilioSmsNumController.text = settings['twilioSmsNum']?.toString() ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUserController.dispose();
    _smtpPasswordController.dispose();
    _twilioAccountSidController.dispose();
    _twilioAuthTokenController.dispose();
    _twilioWhatsappNumController.dispose();
    _twilioSmsNumController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'enableEmailAlerts': _enableEmailAlerts,
      'smtpHost': _smtpHostController.text.trim(),
      'smtpPort': _smtpPortController.text.trim(),
      'smtpUser': _smtpUserController.text.trim(),
      'smtpPassword': _smtpPasswordController.text.trim(),
      'enableWhatsappAlerts': _enableWhatsappAlerts,
      'twilioAccountSid': _twilioAccountSidController.text.trim(),
      'twilioAuthToken': _twilioAuthTokenController.text.trim(),
      'twilioWhatsappNum': _twilioWhatsappNumController.text.trim(),
      'enableSmsAlerts': _enableSmsAlerts,
      'twilioSmsNum': _twilioSmsNumController.text.trim(),
    };

    try {
      await context.read<AdminProvider>().updateSystemSettings(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings updated successfully.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update system settings.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminProvider>().isLoadingSettings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notification Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Email Section
                    _buildSectionHeader(
                      context: context,
                      title: 'Email Notifications (SMTP)',
                      subtitle: 'Configure SMTP for sending email alerts',
                      icon: LucideIcons.mail,
                      iconColor: AppTheme.warning,
                      value: _enableEmailAlerts,
                      onChanged: (val) => setState(() => _enableEmailAlerts = val),
                    ),
                    if (_enableEmailAlerts) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _smtpHostController,
                        label: 'SMTP Host',
                        hint: 'smtp.gmail.com',
                        icon: LucideIcons.server,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _smtpPortController,
                        label: 'SMTP Port',
                        hint: '587',
                        icon: LucideIcons.hash,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _smtpUserController,
                        label: 'SMTP User',
                        hint: 'parking@company.com',
                        icon: LucideIcons.user,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _smtpPasswordController,
                        label: 'SMTP Password',
                        hint: '••••••••••••',
                        icon: LucideIcons.lock,
                        obscureText: true,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // WhatsApp Section
                    _buildSectionHeader(
                      context: context,
                      title: 'WhatsApp Alerts (Twilio)',
                      subtitle: 'Configure Twilio API for WhatsApp messages',
                      icon: Icons.message_outlined,
                      iconColor: AppTheme.success,
                      value: _enableWhatsappAlerts,
                      onChanged: (val) => setState(() => _enableWhatsappAlerts = val),
                    ),
                    if (_enableWhatsappAlerts || _enableSmsAlerts) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _twilioAccountSidController,
                        label: 'Twilio Account SID',
                        hint: 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                        icon: LucideIcons.key,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _twilioAuthTokenController,
                        label: 'Twilio Auth Token',
                        hint: '••••••••••••••••••••••••••••',
                        icon: LucideIcons.shieldAlert,
                        obscureText: true,
                      ),
                    ],
                    if (_enableWhatsappAlerts) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _twilioWhatsappNumController,
                        label: 'Twilio WhatsApp Sender',
                        hint: '+14155238886',
                        icon: LucideIcons.phoneCall,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // SMS Section
                    _buildSectionHeader(
                      context: context,
                      title: 'Standard SMS (Twilio)',
                      subtitle: 'Configure SMS texts sending via Twilio',
                      icon: LucideIcons.messageSquare,
                      iconColor: AppTheme.primary,
                      value: _enableSmsAlerts,
                      onChanged: (val) => setState(() => _enableSmsAlerts = val),
                    ),
                    if (_enableSmsAlerts) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _twilioSmsNumController,
                        label: 'Twilio SMS Sender Number',
                        hint: '+1507502...',
                        icon: LucideIcons.phone,
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(LucideIcons.save, color: Colors.white),
                        label: const Text(
                          'SAVE CONFIGURATION',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: _saveSettings,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textSecondary(context).withOpacity(0.5), fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.error, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}
