import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../core/global_popup.dart';
import '../widgets/complex_animations.dart';
import '../core/checkout_helper.dart';
import '../core/constants.dart';
import '../providers/vehicle_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../services/printing_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/scanner_screen.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'Inside'; // All, Inside, Absent
  String _filterCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().fetchVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getVehicleAsset(String? categoryName) {
    switch (categoryName) {
      case 'Bodaboda':
        return 'assets/images/bodaboda.png';
      case 'Bajaji':
        return 'assets/images/bajaji.png';
      case 'Lorry':
        return 'assets/images/lorry.png';
      case 'Daladala':
        return 'assets/images/daladala.png';
      case 'Sedan/SUV':
      default:
        return 'assets/images/car.png';
    }
  }

  void _showRegisterDialog(BuildContext context, {Map<String, dynamic>? editingVehicle}) {
    final formKey = GlobalKey<FormState>();
    final plateController = TextEditingController(text: editingVehicle?['plateNumber']);
    final ownerController = TextEditingController(text: editingVehicle?['ownerName']);
    final phoneController = TextEditingController(text: editingVehicle?['phone']);
    final emailController = TextEditingController(text: editingVehicle?['email']);
    final companyController = TextEditingController(text: editingVehicle?['company']);
    final colorController = TextEditingController(text: editingVehicle?['color']);
    final makeController = TextEditingController(text: editingVehicle?['makeModel']);
    const createNewCategoryOption = '__create_new__';
    
    final vehicleProvider = context.read<VehicleProvider>();
    List<String> categories = vehicleProvider.categories
        .map((cat) => (cat['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();

    if (categories.isEmpty) {
      categories = ['Bodaboda', 'Bajaji', 'Sedan/SUV', 'Daladala', 'Lorry'];
    }

    String selectedCategory = editingVehicle?['category']?['name'] ?? 'Sedan/SUV';
    if (!categories.contains(selectedCategory)) {
      categories.insert(0, selectedCategory);
    }
    if (!categories.contains('Sedan/SUV')) {
      categories.add('Sedan/SUV');
    }
    categories.add(createNewCategoryOption);

    // Image capture states
    String? frontImagePath;
    String? plateImagePath;
    String? sideImagePath;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.t.tr('dismiss'),
      barrierColor: Colors.black.withOpacity(isDark ? 0.85 : 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06), 
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(isDark ? 0.08 : 0.05),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // HEADER
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  editingVehicle != null 
                                      ? (context.t.tr('editVehicle') ?? 'Edit Vehicle Details') 
                                      : context.t.tr('newVehicleRegistration'),
                                  style: TextStyle(
                                    color: AppTheme.textPrimary(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  LucideIcons.x, 
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        
                        // BODY
                        Expanded(
                          child: Form(
                            key: formKey,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image moved down to be side-by-side with dropdown

                                  Text(
                                    context.t.tr('vehicleDetails'),
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Smart Plate Input
                                  TextFormField(
                                    controller: plateController,
                                    textCapitalization: TextCapitalization.characters,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary(context), 
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(LucideIcons.hash, color: isDark ? Colors.white38 : Colors.black38),
                                      suffixIcon: IconButton(
                                        icon: const Icon(LucideIcons.scanLine, color: AppTheme.primary),
                                        onPressed: () async {
                                          final status = await Permission.camera.request();
                                          if (status.isGranted) {
                                            if (!context.mounted) return;
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const ScannerScreen(mode: ScannerMode.plate)),
                                            );
                                            if (result != null && result is String) {
                                              plateController.text = result;
                                            }
                                          } else {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(context.t.tr('cameraPermissionDenied') ?? 'Camera Permission Denied')),
                                            );
                                          }
                                        },
                                      ),
                                      labelText: context.t.tr('plateNumberLabel'),
                                      labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                                      filled: true,
                                      fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return context.t.tr('plateNumberRequired');
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Category Dropdown
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          dropdownColor: Theme.of(context).cardColor,
                                          style: TextStyle(color: AppTheme.textPrimary(context)),
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(LucideIcons.car, color: isDark ? Colors.white38 : Colors.black38),
                                            labelText: context.t.tr('selectVehicleCategory'),
                                            labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                                            filled: true,
                                            fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                              ),
                                            ),
                                          ),
                                          value: selectedCategory,
                                          items: categories.map((c) => DropdownMenuItem(
                                            value: c, 
                                            child: Text(
                                              c == createNewCategoryOption ? context.t.tr('createNewCategory') : c,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                color: c == createNewCategoryOption
                                                    ? AppTheme.primary
                                                    : AppTheme.textPrimary(context),
                                                fontWeight: c == createNewCategoryOption
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          )).toList(),
                                          onChanged: (val) {
                                            if (val == createNewCategoryOption) {
                                              _showCreateCategoryDialog(context, (newCat) {
                                                if (newCat.isNotEmpty) {
                                                  setState(() {
                                                    categories.insert(categories.length - 1, newCat);
                                                    selectedCategory = newCat;
                                                  });
                                                } else {
                                                  setState(() {
                                                    selectedCategory = 'Sedan/SUV';
                                                  });
                                                }
                                              });
                                            } else {
                                              setState(() => selectedCategory = val!);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        height: 56, // Match height of the text field
                                        width: 80,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Image.asset(
                                          _getVehicleAsset(selectedCategory),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: colorController,
                                          style: TextStyle(color: AppTheme.textPrimary(context)),
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(LucideIcons.palette, color: isDark ? Colors.white38 : Colors.black38),
                                            suffixIcon: IconButton(
                                              icon: const Icon(LucideIcons.paintBucket, color: AppTheme.primary),
                                              onPressed: () {
                                                _showColorPickerDialog(context, (colorStr) {
                                                  setState(() => colorController.text = colorStr);
                                                });
                                              },
                                            ),
                                            labelText: context.t.tr('vehicleColor'),
                                            labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                                            filled: true,
                                            fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildPremiumInputField(makeController, context.t.tr('makeModel'), LucideIcons.car)),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  Text(
                                    context.t.tr('ownerDriverInfo'),
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPremiumInputField(ownerController, context.t.tr('fullName'), LucideIcons.user, requiredField: true),
                                  const SizedBox(height: 12),
                                  _buildPremiumInputField(
                                    phoneController,
                                    context.t.tr('phoneNumber'),
                                    LucideIcons.phone,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(12),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPremiumInputField(
                                    emailController,
                                    context.t.tr('emailAddress') ?? 'Email Address (Optional)',
                                    LucideIcons.mail,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPremiumInputField(companyController, context.t.tr('companyOrganization'), LucideIcons.building),
                                  const SizedBox(height: 20),

                                  // VEHICLE PHOTOS CAPTURE ROW
                                  Text(
                                    context.t.tr('vehiclePhotos') ?? 'VEHICLE PHOTOS',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildPhotoCaptureSlot(
                                          context,
                                          context.t.tr('frontView') ?? 'Front View',
                                          frontImagePath,
                                          (path) => setState(() => frontImagePath = path),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildPhotoCaptureSlot(
                                          context,
                                          context.t.tr('plateView') ?? 'Plate View',
                                          plateImagePath,
                                          (path) => setState(() => plateImagePath = path),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildPhotoCaptureSlot(
                                          context,
                                          context.t.tr('sideView') ?? 'Side View',
                                          sideImagePath,
                                          (path) => setState(() => sideImagePath = path),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // FOOTER
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () async {
                                if (!(formKey.currentState?.validate() ?? false)) {
                                  return;
                                }
                                try {
                                  if (editingVehicle != null) {
                                    await context.read<VehicleProvider>().updateVehicle(
                                          editingVehicle['id'],
                                          categoryName: selectedCategory,
                                          ownerName: ownerController.text.trim(),
                                          phone: phoneController.text.trim(),
                                          email: emailController.text.trim(),
                                          company: companyController.text.trim(),
                                          color: colorController.text.trim(),
                                          makeModel: makeController.text.trim(),
                                          frontImage: frontImagePath,
                                          plateImage: plateImagePath,
                                          sideImage: sideImagePath,
                                        );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      GlobalPopup.showSuccess(
                                        context,
                                        context.t.tr('vehicleUpdated') ?? 'Vehicle updated successfully',
                                        title: context.t.tr('updateSuccess') ?? 'Update Success',
                                      );
                                    }
                                  } else {
                                    await context.read<VehicleProvider>().registerVehicle(
                                          plateController.text.trim().toUpperCase(),
                                          selectedCategory,
                                          ownerController.text.trim(),
                                          phone: phoneController.text.trim(),
                                          email: emailController.text.trim(),
                                          company: companyController.text.trim(),
                                          color: colorController.text.trim(),
                                          makeModel: makeController.text.trim(),
                                          frontImage: frontImagePath,
                                          plateImage: plateImagePath,
                                          sideImage: sideImagePath,
                                        );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      GlobalPopup.showSuccess(
                                        context,
                                        context.t.tr('vehicleRegistered', {'plate': plateController.text.toUpperCase()}),
                                        title: context.t.tr('registrationSuccess'),
                                      );
                                    }
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(editingVehicle != null ? 'Failed to update vehicle' : context.t.tr('failedRegisterAndCheckIn'))),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                editingVehicle != null ? (context.t.tr('saveChanges') ?? 'Save Changes') : context.t.tr('completeRegistration'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
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

  // ─── Quick check-in for 1-click Check In from card ─────────────────
  void _quickCheckIn(BuildContext context, Map<String, dynamic> vehicle) async {
    final provider = context.read<VehicleProvider>();
    final auth = context.read<AuthProvider>();
    final category = vehicle['category']?['name'] ?? 'Sedan/SUV';
    final amount = (vehicle['category']?['price'] as num?)?.toDouble() ?? 0;
    
    // Show a small loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );
    
    try {
      final session = await provider.checkInVehicle(
        vehicle['plateNumber'],
        category,
        amount,
        autoSendEmail: auth.autoSendEmail,
        autoSendSms: auth.autoSendSms,
        propertiesLeft: '',
      );
      
      // Inject the vehicle data into session so the receipt can print Plate and Category correctly
      if (session['vehicle'] == null) {
        session['vehicle'] = vehicle;
      }
      
      if (context.mounted) Navigator.pop(context); // close loading
      
      // Force auto print
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${vehicle['plateNumber']} Checked In. Attempting to Print...'),
          duration: const Duration(seconds: 1),
        ));
      }
      
      await PrintingService.printTicket(context, session);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${vehicle['plateNumber']} Checked In & Auto-Printed Successfully.'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // close loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Check in failed: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  // ─── Dedicated check-in dialog for the vehicles screen ─────────────────
  void _showVehiclesCheckInDialog(BuildContext context, Map<String, dynamic> vehicle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(isDark ? 0.85 : 0.65),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) {
        return _VehiclesCheckInDialogContent(vehicle: vehicle, scaffoldContext: context);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _showCreateCategoryDialog(BuildContext context, Function(String) onCreated) {
    final catController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            context.t.tr('createNewCategory'),
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: catController,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: context.t.tr('exampleCategoryHint'),
                hintStyle: TextStyle(color: AppTheme.textSecondary(context).withOpacity(0.5)),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.03) 
                    : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.t.tr('categoryNameRequired');
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onCreated('');
              },
              child: Text(context.t.tr('cancel'), style: TextStyle(color: AppTheme.textSecondary(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.pop(ctx);
                onCreated(catController.text.trim());
              },
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      }
    );
  }

  void _showColorPickerDialog(BuildContext context, Function(String) onColorSelected) {
    final List<Map<String, dynamic>> presetColors = [
      {'name': 'White', 'labelKey': 'colorWhite', 'color': Colors.white},
      {'name': 'Black', 'labelKey': 'colorBlack', 'color': Colors.black},
      {'name': 'Silver', 'labelKey': 'colorSilver', 'color': Colors.grey[400]},
      {'name': 'Grey', 'labelKey': 'colorGrey', 'color': Colors.grey[700]},
      {'name': 'Red', 'labelKey': 'colorRed', 'color': Colors.red},
      {'name': 'Blue', 'labelKey': 'colorBlue', 'color': Colors.blue},
      {'name': 'Green', 'labelKey': 'colorGreen', 'color': Colors.green},
      {'name': 'Yellow', 'labelKey': 'colorYellow', 'color': Colors.yellow},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.tr('selectVehicleColor'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: presetColors.map((pc) => GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    onColorSelected(pc['name']);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: pc['color'],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12, 
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t.tr(pc['labelKey'] as String),
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPremiumInputField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.black38),
        labelText: hint,
        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Tesla & Uber Inspired Title Bar)
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/nps_logo.png',
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showRegisterDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            context.t.tr('registerNew'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Uber style Search and Tesla Minimal Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: _buildSearchBar(),
            ),

            // Horizontal Slider for Quick Tesla-style filters
            _buildStatusFilterPills(),

            const SizedBox(height: 12),

            Expanded(
              child: Consumer<VehicleProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }

                  var filteredList = provider.vehicles.where((v) {
                    bool matchesSearch = _searchQuery.isEmpty || 
                        (v['plateNumber']?.toLowerCase().contains(_searchQuery) ?? false) ||
                        (v['ownerName']?.toLowerCase().contains(_searchQuery) ?? false) ||
                        (v['phone']?.toLowerCase().contains(_searchQuery) ?? false);
                    
                    bool isInside = v['sessions'] != null && v['sessions'].isNotEmpty && v['sessions'][0]['status'] == 'INSIDE';
                    bool isOverstayed = false;
                    if (isInside) {
                      final checkInDate = DateTime.tryParse(v['sessions'][0]['checkIn'] ?? '') ?? DateTime.now();
                      isOverstayed = CheckoutHelper.hasOverstayed(checkInDate, provider.overstayTimeLimit);
                    }
                    
                    bool matchesStatus = _filterStatus == 'All' || 
                                         (_filterStatus == 'Inside' && isInside) || 
                                         (_filterStatus == 'Overstayed' && isOverstayed) ||
                                         (_filterStatus == 'Absent' && !isInside);
                    
                    bool matchesCat = _filterCategory == 'All' || (v['category']?['name'] == _filterCategory);
                    
                    return matchesSearch && matchesStatus && matchesCat;
                  }).toList();
                  
                  filteredList.sort((a, b) {
                    bool aInside = a['sessions'] != null && a['sessions'].isNotEmpty && a['sessions'][0]['status'] == 'INSIDE';
                    bool bInside = b['sessions'] != null && b['sessions'].isNotEmpty && b['sessions'][0]['status'] == 'INSIDE';
                    
                    bool aOverstayed = false;
                    bool bOverstayed = false;
                    
                    if (aInside) {
                      final checkInDate = DateTime.tryParse(a['sessions'][0]['checkIn'] ?? '') ?? DateTime.now();
                      aOverstayed = CheckoutHelper.hasOverstayed(checkInDate, provider.overstayTimeLimit);
                    }
                    if (bInside) {
                      final checkInDate = DateTime.tryParse(b['sessions'][0]['checkIn'] ?? '') ?? DateTime.now();
                      bOverstayed = CheckoutHelper.hasOverstayed(checkInDate, provider.overstayTimeLimit);
                    }
                    
                    if (aOverstayed && !bOverstayed) return -1;
                    if (!aOverstayed && bOverstayed) return 1;
                    return 0;
                  });

                  if (filteredList.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => context.read<VehicleProvider>().fetchVehicles(),
                      color: AppTheme.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: CarEnteringGateAnimation(
                            title: _searchQuery.isNotEmpty || _filterStatus != 'All'
                                ? context.t.tr('noVehiclesMatchFilter')
                                : context.t.tr('noVehiclesFound'),
                            subtitle: '',
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<VehicleProvider>().fetchVehicles(),
                    color: AppTheme.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return _buildPremiumVehicleCard(filteredList[index]);
                      },
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

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppTheme.textPrimary(context)),
        decoration: InputDecoration(
          prefixIcon: Icon(
            LucideIcons.search, 
            color: isDark ? Colors.white38 : Colors.black38, 
            size: 20,
          ),
          hintText: context.t.tr('searchPlateOwnerPhone'),
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.black38, 
            fontSize: 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildStatusFilterPills() {
    final statuses = ['Inside', 'Overstayed', 'Absent', 'All'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _filterStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                status == 'All' ? context.t.tr('all') : (
                    status == 'Inside' ? context.t.tr('inside') : 
                    status == 'Overstayed' ? 'Overstayed' : context.t.tr('absent')
                ),
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
                setState(() => _filterStatus = status);
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
        },
      ),
    );
  }

  Widget _buildTeslaFilterPills() {
    final categories = ['All', 'Bodaboda', 'Bajaji', 'Sedan/SUV', 'Daladala', 'Lorry'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _filterCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                cat == 'All' ? context.t.tr('all') : cat,
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
                setState(() => _filterCategory = cat);
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
        },
      ),
    );
  }

  Widget _buildPremiumVehicleCard(Map<String, dynamic> vehicle) {
    bool isInside = vehicle['sessions'] != null && vehicle['sessions'].isNotEmpty && vehicle['sessions'][0]['status'] == 'INSIDE';
    bool isOverstayed = false;
    if (isInside) {
      final checkInDate = DateTime.tryParse(vehicle['sessions'][0]['checkIn'] ?? '') ?? DateTime.now();
      isOverstayed = CheckoutHelper.hasOverstayed(checkInDate, context.read<VehicleProvider>().overstayTimeLimit);
    }
    
    String assetPath = _getVehicleAsset(vehicle['category']?['name']);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Hero section with vehicle render & details
            GestureDetector(
              onTap: () => _showVehiclePreview(context, vehicle),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Offline Render Image
                    Container(
                      width: 110,
                      height: 75,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.015),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Plate and details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                vehicle['plateNumber'] ?? 'UNKNOWN',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary(context),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              // Status pill (Tesla style)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isInside 
                                      ? AppTheme.success.withOpacity(0.15) 
                                      : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isInside ? context.t.tr('inside').toUpperCase() : context.t.tr('absent').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: isInside ? AppTheme.success : (isDark ? Colors.white60 : Colors.black54),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (isOverstayed) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.error.withOpacity(0.5), width: 1),
                                  ),
                                  child: const Text(
                                    'OVERSTAYED',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.error,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            vehicle['ownerName'] ?? context.t.tr('unknownOwner'),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (vehicle['makeModel'] != null && vehicle['makeModel'].toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              vehicle['makeModel'],
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Premium Tesla-style Actions footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.02),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.04),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Secondary detail shortcut button
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary(context),
                        side: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showVehiclePreview(context, vehicle),
                      child: const Text(
                        "Maelezo", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Primary Check In / Check Out toggle button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInside ? AppTheme.warning.withOpacity(0.15) : AppTheme.primary,
                        foregroundColor: isInside ? AppTheme.warning : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(isInside ? LucideIcons.logOut : LucideIcons.logIn, size: 14),
                      label: Text(
                        isInside ? context.t.tr('checkOut') : context.t.tr('checkIn'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () async {
                        if (isInside) {
                          final sessionId = vehicle['sessions'][0]['id'];
                          CheckoutHelper.fetchAndConfirmCheckout(context, sessionId);
                        } else {
                          _showVehiclesCheckInDialog(context, vehicle);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehiclePreview(BuildContext context, Map<String, dynamic> vehicle) {
    bool isInside = vehicle['sessions'] != null && vehicle['sessions'].isNotEmpty && vehicle['sessions'][0]['status'] == 'INSIDE';
    String assetPath = _getVehicleAsset(vehicle['category']?['name']);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle['plateNumber'] ?? 'UNKNOWN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehicle['category']?['name'] ?? context.t.tr('unknownCategory'),
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38, 
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isInside 
                          ? AppTheme.success.withOpacity(0.15) 
                          : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isInside ? context.t.tr('inside') : context.t.tr('absent'),
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: isInside ? AppTheme.success : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Render Image inside Detail Panel
                      Center(
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.015),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(assetPath, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        context.t.tr('ownerDetails'),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPreviewRow(context, LucideIcons.user, context.t.tr('fullName'), vehicle['ownerName'] ?? context.t.tr('notAvailable')),
                      _buildPreviewRow(context, LucideIcons.phone, context.t.tr('phoneNumber'), vehicle['phone'] ?? context.t.tr('notAvailable')),
                      _buildPreviewRow(context, LucideIcons.building, context.t.tr('companyOrganization'), vehicle['company'] ?? context.t.tr('notAvailable')),
                      
                      const SizedBox(height: 20),
                      Text(
                        context.t.tr('vehicleSpecifics'),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPreviewRow(context, LucideIcons.palette, context.t.tr('vehicleColor'), vehicle['color'] ?? context.t.tr('notAvailable')),
                      _buildPreviewRow(context, LucideIcons.car, context.t.tr('makeModel'), vehicle['makeModel'] ?? context.t.tr('notAvailable')),
                      
                      const SizedBox(height: 20),
                      Text(
                        context.t.tr('vehiclePhotos') ?? 'VEHICLE PHOTOS',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildDetailPhotoSlot(context, context.t.tr('frontView') ?? 'Front View', vehicle['frontImage'])),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDetailPhotoSlot(context, context.t.tr('plateView') ?? 'Plate View', vehicle['plateImage'])),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDetailPhotoSlot(context, context.t.tr('sideView') ?? 'Side View', vehicle['sideImage'])),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Sheet Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary(context),
                        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.edit3, size: 16),
                      label: Text(
                        context.t.tr('edit') ?? 'Edit',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRegisterDialog(context, editingVehicle: vehicle);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.trash2, size: 16),
                      label: Text(
                        context.t.tr('delete'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Theme.of(context).cardTheme.color,
                            title: Text(context.t.tr('confirmDelete'), style: TextStyle(color: AppTheme.textPrimary(context))),
                            content: Text(context.t.tr('areYouSureDeleteVehicle'), style: TextStyle(color: AppTheme.textSecondary(context))),
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
                          Navigator.pop(context); // Close bottom sheet
                          try {
                            await context.read<VehicleProvider>().deleteVehicle(vehicle['id']);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.t.tr('vehicleDeleted'))),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.t.tr('failedDeleteVehicle'))),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInside ? AppTheme.warning.withOpacity(0.2) : AppTheme.primary,
                        foregroundColor: isInside ? AppTheme.warning : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(
                        isInside ? LucideIcons.logOut : LucideIcons.logIn,
                      ),
                      label: Text(
                        isInside ? context.t.tr('checkOutNow') : context.t.tr('checkInNow'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final provider = context.read<VehicleProvider>();
                        if (isInside) {
                          final sessionId = vehicle['sessions'][0]['id'];
                          CheckoutHelper.fetchAndConfirmCheckout(context, sessionId);
                        } else {
                          _quickCheckIn(context, vehicle);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPreviewRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03), 
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isDark ? Colors.white60 : Colors.black54, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value, 
                style: TextStyle(
                  color: AppTheme.textPrimary(context), 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
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
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,       // Resize to max 1200px wide
          maxHeight: 900,       // Resize to max 900px tall
          imageQuality: 60,     // 60% quality — still sharp for vehicle ID
        );
        if (image != null) {
          onCapture(image.path);
        }
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imagePath != null 
                ? AppTheme.primary 
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            width: imagePath != null ? 2 : 1,
          ),
        ),
        child: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imagePath!.startsWith('assets/') 
                        ? Image.asset(imagePath, fit: BoxFit.contain)
                        : (imagePath!.startsWith('/uploads') || imagePath!.startsWith('http')
                            ? Image.network(
                                imagePath!.startsWith('/uploads') ? '${ApiConstants.baseUrl}$imagePath' : imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(LucideIcons.imageOff, color: Colors.grey, size: 20),
                                ),
                              )
                            : Image.file(File(imagePath!), fit: BoxFit.cover)),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.camera, 
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDetailPhotoSlot(BuildContext context, String label, String? imagePath) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: imagePath != null && imagePath.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imagePath.startsWith('assets/')
                  ? Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    )
                  : (imagePath.startsWith('/uploads') || imagePath.startsWith('http')
                      ? Image.network(
                          imagePath.startsWith('/uploads') ? '${ApiConstants.baseUrl}$imagePath' : imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.imageOff, color: isDark ? Colors.white24 : Colors.black26, size: 20),
                              const SizedBox(height: 6),
                              Text('Failed to load', style: TextStyle(fontSize: 8, color: isDark ? Colors.white30 : Colors.black38)),
                            ],
                          ),
                        )
                      : Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                        )),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.imageOff,
                  color: isDark ? Colors.white24 : Colors.black26,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ],
            ),
    );
  }
}

class _VehiclesCheckInDialogContent extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final BuildContext scaffoldContext;

  const _VehiclesCheckInDialogContent({
    required this.vehicle,
    required this.scaffoldContext,
  });

  @override
  State<_VehiclesCheckInDialogContent> createState() => _VehiclesCheckInDialogContentState();
}

class _VehiclesCheckInDialogContentState extends State<_VehiclesCheckInDialogContent> {
  final List<PropertyItem> dialogProperties = [];
  late final TextEditingController emailController;
  bool? overrideSms;
  bool? overrideEmail;
  bool? overridePrint;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.vehicle['email'] ?? '');
  }

  @override
  void dispose() {
    emailController.dispose();
    for (final item in dialogProperties) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    bool initSms = auth.autoSendSms;
    bool initEmail = auth.autoSendEmail;
    bool initPrint = true; // ALWAYS default to true to ensure printing

    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool sms = overrideSms ?? initSms;
    bool email = overrideEmail ?? initEmail;
    bool autoPrint = overridePrint ?? initPrint;

    Widget _toggleChip(IconData icon, String label, bool active, ValueChanged<bool> onChanged) {
      return GestureDetector(
        onTap: () => onChanged(!active),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primary.withOpacity(0.18)
                : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppTheme.primary.withOpacity(0.6) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? AppTheme.primary : (isDark ? Colors.white38 : Colors.black38), size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: active ? AppTheme.primary : (isDark ? Colors.white38 : Colors.black38),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildPropertiesSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROPERTIES LEFT IN VEHICLE',
                style: TextStyle(
                  color: AppTheme.textSecondary(context).withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    dialogProperties.add(PropertyItem(item: '', brand: '', quantity: 1));
                  });
                },
                icon: const Icon(Icons.add, size: 14, color: AppTheme.primary),
                label: const Text(
                  "Add Item",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (dialogProperties.isEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  dialogProperties.add(PropertyItem(item: '', brand: '', quantity: 1));
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.package, color: isDark ? Colors.white30 : Colors.black38, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Tap to add properties left in vehicle",
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            ...List.generate(dialogProperties.length, (index) {
              final item = dialogProperties[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: item.itemController,
                        style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 12),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: "Item (e.g. Phone)",
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: item.brandController,
                        style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 12),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: "Brand (e.g. iPhone)",
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: Icon(Icons.remove, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      onPressed: () {
                        if (item.quantity > 1) {
                          setState(() {
                            item.quantity--;
                          });
                        }
                      },
                    ),
                    SizedBox(
                      width: 14,
                      child: Text(
                        "${item.quantity}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      onPressed: () {
                        setState(() {
                          item.quantity++;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () {
                        setState(() {
                          dialogProperties.removeAt(index);
                          item.dispose();
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      );
    }

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.logIn, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.t.tr('checkIn'),
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              widget.vehicle['plateNumber'] ?? '',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, color: isDark ? Colors.white54 : Colors.black45, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Properties Left
                          _buildPropertiesSection(),
                          const SizedBox(height: 16),

                          // Email for ticket
                          Text(
                            'SEND TICKET TO EMAIL',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context).withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'driver@example.com (optional)',
                              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12),
                              prefixIcon: Icon(LucideIcons.mail, color: isDark ? Colors.white38 : Colors.black38, size: 18),
                              filled: true,
                              fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Notification toggles
                          Text(
                            'NOTIFICATIONS',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context).withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _toggleChip(LucideIcons.messageSquare, 'SMS', sms, (val) => setState(() => overrideSms = val)),
                              _toggleChip(LucideIcons.mail, 'EMAIL', email, (val) => setState(() => overrideEmail = val)),
                              _toggleChip(LucideIcons.printer, 'PRINT', autoPrint, (val) => setState(() => overridePrint = val)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Confirm button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(LucideIcons.logIn, size: 18),
                              label: Text(
                                context.t.tr('checkIn'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              onPressed: () async {
                                final propString = dialogProperties
                                    .where((item) => item.itemController.text.trim().isNotEmpty)
                                    .map((item) {
                                      final name = item.itemController.text.trim();
                                      final brand = item.brandController.text.trim();
                                      final qty = item.quantity;
                                      if (brand.isNotEmpty) {
                                        return "$qty $name ($brand)";
                                      } else {
                                        return "$qty $name";
                                      }
                                    })
                                    .join(', ');

                                // Capture the scaffold context BEFORE popping the dialog
                                final scaffoldContext = widget.scaffoldContext;
                                Navigator.pop(context);
                                final provider = scaffoldContext.read<VehicleProvider>();
                                final category = widget.vehicle['category']?['name'] ?? 'Sedan/SUV';
                                final amount = (widget.vehicle['category']?['price'] as num?)?.toDouble() ?? 0;
                                try {
                                  final session = await provider.checkInVehicle(
                                    widget.vehicle['plateNumber'],
                                    category,
                                    amount,
                                    driverEmail: emailController.text.trim(),
                                    autoSendEmail: overrideEmail ?? initEmail,
                                    autoSendSms: overrideSms ?? initSms,
                                    propertiesLeft: propString,
                                  );

                                  // Inject the vehicle data into session so the receipt can print Plate and Category correctly
                                  if (session['vehicle'] == null) {
                                    session['vehicle'] = widget.vehicle;
                                  }

                                  if (scaffoldContext.mounted) {
                                    scaffoldContext.read<ActivityProvider>().fetchActivities();
                                    final shouldPrint = overridePrint ?? initPrint;
                                    if (shouldPrint) {
                                      PrintingService.printTicket(scaffoldContext, session).catchError((err) {
                                        print('Auto-print failed: $err');
                                      });
                                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                        SnackBar(
                                          content: Text('${widget.vehicle['plateNumber']} Checked In & Printed Successfully.'),
                                          backgroundColor: AppTheme.success,
                                        ),
                                      );
                                    } else {
                                      // Show the ticket dialog with print option only if not auto-printing
                                      showDialog(
                                        context: scaffoldContext,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          title: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.success.withOpacity(0.12),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(LucideIcons.checkCircle, color: AppTheme.success, size: 20),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                scaffoldContext.t.tr('checkInSuccess'),
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${widget.vehicle['plateNumber']} has been checked in successfully.',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Would you like to print the entry ticket?',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('No, Close'),
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.primary,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              icon: const Icon(LucideIcons.printer, size: 16, color: Colors.white),
                                              onPressed: () async {
                                                try {
                                                  Navigator.pop(ctx);
                                                  await PrintingService.printTicket(scaffoldContext, session);
                                                } catch (e) {
                                                  if (scaffoldContext.mounted) {
                                                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                                      SnackBar(content: Text('Printing failed: $e'), backgroundColor: AppTheme.error),
                                                    );
                                                  }
                                                }
                                              },
                                              label: const Text('Print Ticket', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                } catch (_) {
                                  if (scaffoldContext.mounted) {
                                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                      SnackBar(content: Text(scaffoldContext.t.tr('failedCheckInVehicle'))),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
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

class PropertyItem {
  final TextEditingController itemController;
  final TextEditingController brandController;
  int quantity;

  PropertyItem({
    required String item,
    required String brand,
    this.quantity = 1,
  }) : itemController = TextEditingController(text: item),
       brandController = TextEditingController(text: brand);

  void dispose() {
    itemController.dispose();
    brandController.dispose();
  }
}
