import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../providers/vehicle_provider.dart';

void showAdminRegistrationDialog(BuildContext context, {String? initialPlate}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.85 : 0.6),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return _AdminRegistrationDialogContent(initialPlate: initialPlate);
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

class _AdminRegistrationDialogContent extends StatefulWidget {
  final String? initialPlate;
  const _AdminRegistrationDialogContent({this.initialPlate});

  @override
  State<_AdminRegistrationDialogContent> createState() => _AdminRegistrationDialogContentState();
}

class _AdminRegistrationDialogContentState extends State<_AdminRegistrationDialogContent> {
  String? _selectedCategory;
  String? _frontImagePath;
  String? _plateImagePath;
  String? _sideImagePath;
  
  late TextEditingController _plateController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  
  final GlobalKey<FormState> _registrationFormKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(text: widget.initialPlate ?? '');
  }

  @override
  void dispose() {
    _plateController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _colorController.dispose();
    _makeController.dispose();
    super.dispose();
  }

  String _getVehicleAsset(String? categoryName) {
    switch (categoryName) {
      case 'Bodaboda': return 'assets/images/bodaboda.png';
      case 'Bajaji': return 'assets/images/bajaji.png';
      case 'Lorry': return 'assets/images/lorry.png';
      case 'Daladala': return 'assets/images/daladala.png';
      case 'Sedan/SUV': default: return 'assets/images/car.png';
    }
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool isCompact = false,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: isCompact ? 13 : 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: isCompact ? 18 : 22),
        prefixIconConstraints: isCompact ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
        contentPadding: isCompact ? const EdgeInsets.symmetric(horizontal: 8, vertical: 10) : null,
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: isCompact ? 11 : 14),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$hint ${context.t.tr('isRequired')}';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildPhotoCaptureSlot(
    BuildContext context,
    String label,
    String? imagePath,
    Function(String) onCapture,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () async {
        try {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );
          if (image != null) {
            onCapture(image.path);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label captured successfully!')));
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open camera: $e')));
          }
        }
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imagePath != null ? AppTheme.primary : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            width: imagePath != null ? 2 : 1,
          ),
        ),
        child: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imagePath.startsWith('assets/') ? Image.asset(imagePath, fit: BoxFit.cover) : Image.file(File(imagePath), fit: BoxFit.cover),
                    Positioned(
                      right: 4, top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.camera, color: isDark ? Colors.white38 : Colors.black38, size: 20),
                  const SizedBox(height: 6),
                  Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.94,
            constraints: const BoxConstraints(maxWidth: 550),
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06), width: 1.5),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(isDark ? 0.08 : 0.05), blurRadius: 40, spreadRadius: 10)],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          context.t.tr('newVehicleRegistration'),
                          style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 18),
                          overflow: TextOverflow.ellipsis, maxLines: 1,
                        ),
                      ),
                      IconButton(icon: Icon(LucideIcons.x, color: isDark ? Colors.white60 : Colors.black54), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _registrationFormKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: 110, width: 200,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.015),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(_getVehicleAsset(_selectedCategory), fit: BoxFit.contain),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(context.t.tr('vehicleDetails'), style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          _buildInputField(_plateController, context.t.tr('plateNumberLabel'), LucideIcons.hash, requiredField: true, textCapitalization: TextCapitalization.characters),
                          const SizedBox(height: 12),
                          Consumer<VehicleProvider>(
                            builder: (context, provider, child) {
                              final categories = provider.categories.map((c) => (c['name'] ?? '').toString()).where((name) => name.isNotEmpty).toList();
                              
                              String? dropdownValue = _selectedCategory;
                              if (dropdownValue != null && !categories.contains(dropdownValue)) {
                                dropdownValue = null;
                              }
                              if (dropdownValue == null && categories.isNotEmpty) {
                                dropdownValue = categories.first;
                              }

                              if (_selectedCategory == null && dropdownValue != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() => _selectedCategory = dropdownValue);
                                });
                              }

                              return DropdownButtonFormField<String>(
                                dropdownColor: Theme.of(context).cardColor,
                                style: TextStyle(color: AppTheme.textPrimary(context)),
                                isExpanded: true,
                                value: categories.isEmpty ? null : dropdownValue,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(LucideIcons.car, color: isDark ? Colors.white38 : Colors.black38),
                                  labelText: context.t.tr('selectVehicleCategory'),
                                  labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
                                ),
                                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategory = val);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildInputField(_colorController, context.t.tr('vehicleColor'), LucideIcons.palette, isCompact: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildInputField(_makeController, context.t.tr('makeModel'), LucideIcons.car, isCompact: true)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(context.t.tr('ownerDriverInfo'), style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          _buildInputField(_nameController, context.t.tr('fullName'), LucideIcons.user, requiredField: true),
                          const SizedBox(height: 12),
                          _buildInputField(_phoneController, context.t.tr('phoneNumber'), LucideIcons.phone, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)]),
                          const SizedBox(height: 12),
                          _buildInputField(_emailController, context.t.tr('emailAddress') ?? 'Email Address', LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 12),
                          _buildInputField(_companyController, context.t.tr('companyOrganization'), LucideIcons.building),
                          const SizedBox(height: 20),
                          Text(context.t.tr('vehiclePhotos') ?? 'VEHICLE PHOTOS', style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildPhotoCaptureSlot(context, context.t.tr('frontView') ?? 'Front View', _frontImagePath, (path) => setState(() => _frontImagePath = path))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildPhotoCaptureSlot(context, context.t.tr('plateView') ?? 'Plate View', _plateImagePath, (path) => setState(() => _plateImagePath = path))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildPhotoCaptureSlot(context, context.t.tr('sideView') ?? 'Side View', _sideImagePath, (path) => setState(() => _sideImagePath = path))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)))),
                  child: SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: _isLoading ? null : () async {
                        if (!(_registrationFormKey.currentState?.validate() ?? false)) return;
                        final plate = _plateController.text.trim().toUpperCase();
                        final owner = _nameController.text.trim();
                        if (plate.isEmpty || owner.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.tr('plateNumberAndOwnerRequired'))));
                          return;
                        }
                        setState(() => _isLoading = true);
                        try {
                          await context.read<VehicleProvider>().registerVehicle(
                            plate, _selectedCategory ?? '', owner,
                            phone: _phoneController.text.trim(),
                            email: _emailController.text.trim(),
                            company: _companyController.text.trim(),
                            color: _colorController.text.trim(),
                            makeModel: _makeController.text.trim(),
                            frontImage: _frontImagePath, plateImage: _plateImagePath, sideImage: _sideImagePath,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vehicle Registered Successfully!'), backgroundColor: AppTheme.success));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.tr('failedRegisterVehicle'))));
                          }
                        }
                      },
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(context.t.tr('completeRegistration'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
