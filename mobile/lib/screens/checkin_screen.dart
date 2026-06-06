import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../core/global_popup.dart';
import '../providers/vehicle_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_navigation_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'scanner_screen.dart';
import '../services/printing_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String _selectedCategory = 'Sedan/SUV';
  bool _isNewVehicle = true;
  Map<String, dynamic>? _selectedVehicle;
  List<Map<String, dynamic>> _searchResults = [];
  
  String? _frontImagePath;
  String? _plateImagePath;
  String? _sideImagePath;
  
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverPhoneController = TextEditingController();
  final TextEditingController _driverCompanyController = TextEditingController();
  final TextEditingController _driverEmailController = TextEditingController();
  final TextEditingController _propertiesController = TextEditingController();

  // Local transactional override flags (fallback to AuthProvider defaults)
  bool? _overridePrint;
  bool? _overrideEmail;
  bool? _overrideSms;

  bool _shouldPrint(BuildContext context) => _overridePrint ?? context.read<AuthProvider>().autoPrint;
  bool _shouldEmail(BuildContext context) => _overrideEmail ?? context.read<AuthProvider>().autoSendEmail;
  bool _shouldSms(BuildContext context) => _overrideSms ?? context.read<AuthProvider>().autoSendSms;

  final GlobalKey<FormState> _checkInFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registrationFormKey = GlobalKey<FormState>();
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _plateController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _colorController.dispose();
    _makeController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _driverCompanyController.dispose();
    _driverEmailController.dispose();
    _propertiesController.dispose();
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

  void _onPlateChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (value.isEmpty) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _selectedVehicle = null;
            _isNewVehicle = true;
          });
        }
        return;
      }

      String query = value.toLowerCase();
      final provider = context.read<VehicleProvider>();
      
      final matches = provider.vehicles.where((v) {
        final plate = (v['plateNumber'] ?? '').toString().toLowerCase();
        final owner = (v['ownerName'] ?? '').toString().toLowerCase();
        final cat = (v['category']?['name'] ?? '').toString().toLowerCase();
        return plate.contains(query) || owner.contains(query) || cat.contains(query);
      }).toList().cast<Map<String, dynamic>>();
      
      if (mounted) {
        setState(() {
          _searchResults = matches.take(5).toList();
          if (_selectedVehicle != null && !matches.any((m) => m['id'] == _selectedVehicle!['id'])) {
             _selectedVehicle = null;
             _isNewVehicle = true;
          }
        });
      }
    });
  }

  void _selectVehicle(Map<String, dynamic> vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _plateController.text = vehicle['plateNumber'];
      _isNewVehicle = false;
      _searchResults = [];
      if (vehicle['category'] != null) {
        _selectedCategory = vehicle['category']['name'];
      } else if (vehicle['categoryName'] != null) {
        _selectedCategory = vehicle['categoryName'];
      }
      _driverNameController.text = vehicle['ownerName'] ?? '';
      _driverPhoneController.text = vehicle['phone'] ?? '';
      _driverCompanyController.text = vehicle['company'] ?? '';
      _driverEmailController.text = vehicle['email'] ?? '';
    });
    _plateController.selection = TextSelection.fromPosition(TextPosition(offset: _plateController.text.length));
  }

  void _clearRegistrationFields() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _companyController.clear();
    _colorController.clear();
    _makeController.clear();
    _frontImagePath = null;
    _plateImagePath = null;
    _sideImagePath = null;
  }

  void _showPremiumRegistrationDialog() {
    _clearRegistrationFields();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.t.tr('dismiss'),
      barrierColor: Colors.black.withOpacity(isDark ? 0.85 : 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                                  context.t.tr('newVehicleRegistration'),
                                  style: TextStyle(
                                    color: AppTheme.textPrimary(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.x, color: isDark ? Colors.white60 : Colors.black54),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        
                        // BODY
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
                                      height: 110,
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.015),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        _getVehicleAsset(_selectedCategory),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Text(
                                    context.t.tr('vehicleDetails'),
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInputField(
                                    _plateController,
                                    context.t.tr('plateNumberLabel'),
                                    LucideIcons.hash,
                                    requiredField: true,
                                    textCapitalization: TextCapitalization.characters,
                                  ),
                                  const SizedBox(height: 12),
                                  Consumer<VehicleProvider>(
                                    builder: (context, provider, child) {
                                      final categories = provider.categories
                                          .map((c) => (c['name'] ?? '').toString())
                                          .where((name) => name.isNotEmpty)
                                          .toList();
                                      if (categories.isEmpty) {
                                        categories.addAll(['Sedan/SUV', 'Bodaboda', 'Bajaji', 'Daladala', 'Lorry']);
                                      }
                                      if (!categories.contains(_selectedCategory)) {
                                        categories.insert(0, _selectedCategory);
                                      }
                                      return DropdownButtonFormField<String>(
                                        dropdownColor: Theme.of(context).cardColor,
                                        style: TextStyle(color: AppTheme.textPrimary(context)),
                                        isExpanded: true,
                                        value: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
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
                                        items: categories.map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c, overflow: TextOverflow.ellipsis),
                                        )).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setStateDialog(() {
                                              _selectedCategory = val;
                                            });
                                            setState(() {
                                              _selectedCategory = val;
                                            });
                                          }
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

                                  Text(
                                    context.t.tr('ownerDriverInfo'),
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInputField(_nameController, context.t.tr('fullName'), LucideIcons.user, requiredField: true),
                                  const SizedBox(height: 12),
                                  _buildInputField(
                                    _phoneController,
                                    context.t.tr('phoneNumber'),
                                    LucideIcons.phone,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(12),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInputField(
                                    _emailController,
                                    context.t.tr('emailAddress') ?? 'Email Address',
                                    LucideIcons.mail,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInputField(_companyController, context.t.tr('companyOrganization'), LucideIcons.building),
                                  const SizedBox(height: 20),
                                  Text(
                                    context.t.tr('vehiclePhotos') ?? 'VEHICLE PHOTOS',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                                          _frontImagePath,
                                          (path) => setStateDialog(() => _frontImagePath = path),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildPhotoCaptureSlot(
                                          context,
                                          context.t.tr('plateView') ?? 'Plate View',
                                          _plateImagePath,
                                          (path) => setStateDialog(() => _plateImagePath = path),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildPhotoCaptureSlot(
                                          context,
                                          context.t.tr('sideView') ?? 'Side View',
                                          _sideImagePath,
                                          (path) => setStateDialog(() => _sideImagePath = path),
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
                              onPressed: _isLoading ? null : () async {
                                if (!(_registrationFormKey.currentState?.validate() ?? false)) {
                                  return;
                                }
                                final plate = _plateController.text.trim().toUpperCase();
                                final owner = _nameController.text.trim();
                                if (plate.isEmpty || owner.isEmpty) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(context.t.tr('plateNumberAndOwnerRequired'))),
                                  );
                                  return;
                                }

                                setStateDialog(() {
                                  _isLoading = true;
                                });

                                final provider = context.read<VehicleProvider>();
                                double amount = 0;
                                try {
                                  final cat = provider.categories.firstWhere((c) => c['name'] == _selectedCategory);
                                  amount = (cat['price'] as num).toDouble();
                                } catch (_) {}

                                try {
                                  await provider.registerVehicle(
                                    plate,
                                    _selectedCategory,
                                    owner,
                                    phone: _phoneController.text.trim(),
                                    email: _emailController.text.trim(),
                                    company: _companyController.text.trim(),
                                    color: _colorController.text.trim(),
                                    makeModel: _makeController.text.trim(),
                                    frontImage: _frontImagePath,
                                    plateImage: _plateImagePath,
                                    sideImage: _sideImagePath,
                                  );

                                  final newVehicle = provider.vehicles.firstWhere(
                                    (v) => (v['plateNumber'] ?? '').toString().toLowerCase() == plate.toLowerCase(),
                                    orElse: () => null,
                                  );

                                  if (!context.mounted) return;

                                  if (newVehicle != null) {
                                    _selectVehicle(newVehicle);
                                  }

                                  Navigator.pop(context);

                                  setState(() {
                                    _frontImagePath = null;
                                    _plateImagePath = null;
                                    _sideImagePath = null;
                                    _isLoading = false;
                                  });
                                } catch (_) {
                                  if (!context.mounted) return;
                                  setStateDialog(() {
                                    _isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(context.t.tr('failedRegisterVehicle'))),
                                  );
                                }
                              },
                              child: _isLoading
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : Text(
                                context.t.tr('completeRegistration'),
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
          }
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

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<ShellNavigationProvider>();
    if (nav.prefilledPlate != null) {
      final plate = nav.prefilledPlate!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nav.clearPrefilledPlate();
        if (plate.isNotEmpty) {
          final provider = context.read<VehicleProvider>();
          final exactMatch = provider.vehicles.firstWhere(
            (v) => (v['plateNumber'] ?? '').toString().toLowerCase() == plate.toLowerCase(),
            orElse: () => null,
          );

          if (exactMatch != null) {
            _selectVehicle(exactMatch);
          } else {
            setState(() {
              _plateController.text = plate;
              _isNewVehicle = true;
            });
            _showPremiumRegistrationDialog();
          }
        } else {
          setState(() {
            _plateController.clear();
            _isNewVehicle = true;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/images/nps_logo.png',
          height: 38,
          fit: BoxFit.contain,
        ),
        centerTitle: false,
        actions: [
          _PulsingScannerIcon(onPressed: _openScanner),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _checkInFormKey,
                child: _buildPlateInput(),
              ),
              _buildSuggestionsList(),
              const SizedBox(height: 28),
              
              Text(
                context.t.tr('vehicleType').toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.textSecondary(context).withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<VehicleProvider>(
                builder: (context, provider, child) {
                  if (provider.categories.isEmpty) {
                    return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
                  }
                  
                  if (!provider.categories.any((c) => c['name'] == _selectedCategory)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedCategory = provider.categories.first['name']);
                    });
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildCategoryCard(cat['name']),
                        );
                      }).toList(),
                    ),
                  );
                }
              ),
              const SizedBox(height: 28),

              // Uber/Tesla style Payment Collection Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withOpacity(0.04) 
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t.tr('amountToCollect').toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Consumer<VehicleProvider>(
                          builder: (context, provider, child) {
                            return Text(
                              _getPaymentAmount(provider.categories),
                              style: const TextStyle(color: AppTheme.success, fontSize: 26, fontWeight: FontWeight.w900),
                            );
                          }
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.banknote, color: AppTheme.success, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Properties Left in Vehicle Field
              _buildInputField(_propertiesController, "Properties Left in Vehicle", LucideIcons.package, maxLines: 2),
              const SizedBox(height: 20),

              // Glowing Override toggles card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withOpacity(0.04) 
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverrideIconToggle(
                      context,
                      LucideIcons.messageSquare,
                      'SMS ALERT',
                      _shouldSms(context),
                      (val) => setState(() => _overrideSms = val),
                    ),
                    _buildOverrideIconToggle(
                      context,
                      LucideIcons.mail,
                      'EMAIL TICKET',
                      _shouldEmail(context),
                      (val) => setState(() => _overrideEmail = val),
                    ),
                    _buildOverrideIconToggle(
                      context,
                      LucideIcons.printer,
                      'PRINT QR',
                      _shouldPrint(context),
                      (val) => setState(() => _overridePrint = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 58,
                child: Builder(
                  builder: (context) {
                    bool isSelectedInside = false;
                    if (_selectedVehicle != null) {
                       isSelectedInside = _selectedVehicle!['sessions'] != null && 
                                          _selectedVehicle!['sessions'].isNotEmpty && 
                                          _selectedVehicle!['sessions'][0]['status'] == 'INSIDE';
                    }

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelectedInside 
                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)) 
                            : (_isNewVehicle ? AppTheme.warning : AppTheme.success),
                        foregroundColor: isSelectedInside ? AppTheme.textSecondary(context).withOpacity(0.4) : Colors.white,
                        elevation: isSelectedInside ? 0 : 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: (isSelectedInside || _isLoading) ? null : () async {
                        if (!(_checkInFormKey.currentState?.validate() ?? false)) {
                          return;
                        }

                        if (_isNewVehicle) {
                          _showPremiumRegistrationDialog();
                          return;
                        }

                        setState(() {
                          _isLoading = true;
                        });

                        final provider = context.read<VehicleProvider>();
                        double amount = 0;
                        try {
                          final cat = provider.categories.firstWhere((c) => c['name'] == _selectedCategory);
                          amount = (cat['price'] as num).toDouble();
                        } catch (_) {}

                        try {
                          final session = await provider.checkInVehicle(
                            _plateController.text.toUpperCase(), 
                            _selectedCategory, 
                            amount,
                            driverName: _driverNameController.text.trim(),
                            driverPhone: _driverPhoneController.text.trim(),
                            driverCompany: _driverCompanyController.text.trim(),
                            driverEmail: _driverEmailController.text.trim(),
                            autoSendEmail: _shouldEmail(context),
                            autoSendSms: _shouldSms(context),
                            propertiesLeft: _propertiesController.text.trim(),
                          );
                          
                          if (mounted) {
                            _plateController.clear();
                            _driverNameController.clear();
                            _driverPhoneController.clear();
                            _driverCompanyController.clear();
                            _driverEmailController.clear();
                            _propertiesController.clear();
                            setState(() {
                              _isNewVehicle = true;
                              _selectedVehicle = null;
                              _overridePrint = null;
                              _overrideEmail = null;
                              _overrideSms = null;
                              _isLoading = false;
                            });
                            if (_shouldPrint(context)) {
                              PrintingService.printTicket(context, session).catchError((err) {
                                if (mounted) {
                                  print('Background auto-print failed: $err');
                                }
                              });
                            }
                            if (context.mounted) {
                              context.read<ShellNavigationProvider>().setIndex(1);
                            }
                          }
                        } catch (_) {
                          if (!context.mounted) return;
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.t.tr('failedCheckInVehicle'))),
                          );
                        }
                      },
                      child: _isLoading 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                        : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelectedInside ? Icons.block : (_isNewVehicle ? LucideIcons.userPlus : LucideIcons.checkCircle), 
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              isSelectedInside
                                  ? context.t.tr('vehicleAlreadyInside')
                                  : (_isNewVehicle
                                      ? context.t.tr('registerAndCheckIn')
                                      : context.t.tr('collectPaymentAndCheckIn')),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentAmount(List<dynamic> categories) {
    if (categories.isEmpty) return 'TZS 0';
    try {
      final cat = categories.firstWhere((c) => c['name'] == _selectedCategory);
      return 'TZS ${cat['price']}';
    } catch (e) {
      return 'TZS 0';
    }
  }

  Widget _buildPlateInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: TextFormField(
        controller: _plateController,
        onChanged: _onPlateChanged,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.t.tr('plateNumberRequired');
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.characters,
        textAlign: TextAlign.center,
        cursorColor: AppTheme.primary,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: AppTheme.textPrimary(context),
        ),
        decoration: InputDecoration(
          hintText: 'T123 ABC',
          hintStyle: TextStyle(
            color: AppTheme.textSecondary(context).withOpacity(0.3),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_searchResults.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03), 
              height: 1,
            ),
            itemBuilder: (context, index) {
              final v = _searchResults[index];
              bool isInside = v['sessions'] != null && v['sessions'].isNotEmpty && v['sessions'][0]['status'] == 'INSIDE';
              
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isInside ? AppTheme.warning : AppTheme.success).withOpacity(0.12), 
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.car, color: isInside ? AppTheme.warning : AppTheme.success, size: 20),
                ),
                title: Text(
                  v['plateNumber'] ?? '',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                subtitle: Text(
                  '${v['ownerName'] ?? context.t.tr('unknownOwner')} - ${v['category']?['name'] ?? context.t.tr('unknownCategory')}',
                  style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInside ? AppTheme.warning.withOpacity(0.12) : AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isInside ? context.t.tr('inside') : context.t.tr('absent'),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isInside ? AppTheme.warning : AppTheme.success),
                  ),
                ),
                onTap: () => _selectVehicle(v),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title) {
    bool isSelected = _selectedCategory == title;
    String assetPath = _getVehicleAsset(title);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 110,
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.015)) 
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.all(6),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openScanner() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScannerScreen(mode: ScannerMode.plate)),
      );
      if (result != null && result is String) {
        if (result.isNotEmpty) {
          final provider = context.read<VehicleProvider>();
          final exactMatch = provider.vehicles.firstWhere(
            (v) => (v['plateNumber'] ?? '').toString().toLowerCase() == result.toLowerCase(),
            orElse: () => null,
          );

          if (exactMatch != null) {
            _selectVehicle(exactMatch);
          } else {
            setState(() {
              _plateController.text = result;
              _isNewVehicle = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showPremiumRegistrationDialog();
            });
          }
        } else {
          setState(() {
            _plateController.clear();
            _isNewVehicle = true;
          });
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.tr('cameraPermissionDenied'))),
      );
    }
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
            imageQuality: 80, // Compress to save space/bandwidth
          );
          
          if (image != null) {
            onCapture(image.path);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$label captured successfully!',
                  ),
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to open camera: $e')),
             );
          }
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
                    imagePath.startsWith('assets/') 
                       ? Image.asset(imagePath, fit: BoxFit.cover)
                       : Image.file(File(imagePath), fit: BoxFit.cover),
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



  Widget _buildOverrideIconToggle(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    ValueChanged<bool> onToggle,
  ) {
    return GestureDetector(
      onTap: () => onToggle(!isActive),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppTheme.primary.withOpacity(0.12) 
                  : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppTheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary(context).withOpacity(0.5),
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingScannerIcon extends StatefulWidget {
  final VoidCallback onPressed;
  const _PulsingScannerIcon({required this.onPressed});

  @override
  State<_PulsingScannerIcon> createState() => _PulsingScannerIconState();
}

class _PulsingScannerIconState extends State<_PulsingScannerIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(LucideIcons.scanLine, color: AppTheme.primary),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

class QrPainter extends CustomPainter {
  final String data;
  final Color color;
  QrPainter(this.data, {this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Generate a pseudo-random grid based on data hash
    final int hash = data.hashCode;
    const int gridSize = 15;
    final double cellSize = size.width / gridSize;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        // Make standard QR finder patterns in corners
        bool isFinder = (row < 4 && col < 4) ||
            (row < 4 && col >= gridSize - 4) ||
            (row >= gridSize - 4 && col < 4);

        if (isFinder) {
          // Draw outer finder box
          bool isBorder = row == 0 || row == 3 || col == 0 || col == 3 ||
              row == 0 || row == 3 || col == gridSize - 1 || col == gridSize - 4 ||
              row == gridSize - 1 || row == gridSize - 4 || col == 0 || col == 3;
          
          bool isCenter = (row == 1 || row == 2) && (col == 1 || col == 2) ||
              (row == 1 || row == 2) && (col == gridSize - 2 || col == gridSize - 3) ||
              (row == gridSize - 2 || row == gridSize - 3) && (col == 1 || col == 2);
          
          if (isBorder || isCenter) {
            canvas.drawRect(
              Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
              paint,
            );
          }
        } else {
          // Deterministic pseudo-random bytes for other cells
          final int cellIndex = row * gridSize + col;
          final bool isFilled = ((hash >> (cellIndex % 32)) & 1) == 1;
          if (isFilled) {
            canvas.drawRect(
              Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
