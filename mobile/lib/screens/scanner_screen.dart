import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../providers/vehicle_provider.dart';
import 'dart:io';

enum ScannerMode { plate, qr }

class ScannerScreen extends StatefulWidget {
  final ScannerMode mode;
  const ScannerScreen({super.key, this.mode = ScannerMode.plate});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
  bool _isBusy = false;
  bool _isProcessing = false;
  String _detectedText = '';
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {});

      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _returnResult(String result) {
    if (!_isProcessing) {
      _isProcessing = true;
      try {
        _cameraController?.stopImageStream();
      } catch (_) {}
      
      _playWinningVibe();

      if (mounted) {
        Navigator.pop(context, result);
      }
    }
  }

  Future<void> _playWinningVibe() async {
    try {
      // Use HapticFeedback.vibrate() which is highly compatible and noticeable on all Android devices
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.vibrate();
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('Error playing success feedback: $e');
    }
  }

  void _setFlash(bool turnOn) {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      setState(() {
        _isFlashOn = turnOn;
      });
      _cameraController!.setFlashMode(turnOn ? FlashMode.torch : FlashMode.off);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _isProcessing) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      if (widget.mode == ScannerMode.plate) {
        final recognizedText = await _textRecognizer.processImage(inputImage);
        
        // Combine all blocks and lines to handle 2-line plates (e.g. T332 \n ANN -> T332ANN)
        String rawText = recognizedText.text.toUpperCase();
        String collapsedText = rawText.replaceAll(RegExp(r'[^A-Z0-9]'), '');
        
        // 1. Strict Auto-Capture Regex (Tanzania Cars, TZ Motorcycles, Kenya, Uganda, Gov)
        // Matches: T123ABC, MC123ABC, KBB123A, UAB123A, STK1234, etc.
        final RegExp strictPlateRegex = RegExp(r'(T|MC|K[A-Z]|U[A-Z]|STK|SU|PT)\d{3,4}[A-Z]{1,3}');
        
        final match = strictPlateRegex.firstMatch(collapsedText);
        
        if (match != null) {
          final plate = match.group(0)!;
          _returnResult(plate);
        } else {
          // 2. If no strict plate is found, show the most likely candidate for manual tapping
          // Look for any string of 3-9 alphanumeric characters
          final RegExp genericRegex = RegExp(r'\b[A-Z0-9]{3,9}\b');
          String cleanedSpaced = rawText.replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          
          final candidateMatch = genericRegex.firstMatch(cleanedSpaced);
          if (candidateMatch != null && !_isProcessing && mounted) {
            setState(() {
              _detectedText = candidateMatch.group(0)!.replaceAll(' ', '');
            });
          } else if (!_isProcessing && mounted) {
             setState(() {
              _detectedText = '';
            });
          }
        }
      } else {
        // QR Scanner / Ticket UUID Mode
        final barcodes = await _barcodeScanner.processImage(inputImage);
        final RegExp uuidRegex = RegExp(
          r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
          caseSensitive: false,
        );

        for (Barcode barcode in barcodes) {
          if (barcode.rawValue != null) {
            final value = barcode.rawValue!;
            final match = uuidRegex.firstMatch(value);
            if (match != null) {
              final uuid = match.group(0)!.toLowerCase();
              _returnResult(uuid);
              break;
            } else {
              // If it reads a QR that is not a UUID, at least show we detected it
              if (!_isProcessing && mounted) {
                setState(() {
                  _detectedText = value.replaceAll('\n', ' ');
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error recognizing text/qr: $e');
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (sensorOrientation == 90) rotation = InputImageRotation.rotation90deg;
    else if (sensorOrientation == 180) rotation = InputImageRotation.rotation180deg;
    else if (sensorOrientation == 270) rotation = InputImageRotation.rotation270deg;
    else rotation = InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _showSimulateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();

    if (widget.mode == ScannerMode.plate) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            title: const Text('Simulate Plate Scan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'License Plate',
                    hintText: 'e.g. T123ABC',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Popular Mock Options:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['T101ABC', 'T555BAJ', 'T777LOR', 'T999DX'].map((p) {
                    return ActionChip(
                      label: Text(p),
                      onPressed: () {
                        Navigator.pop(context);
                        _returnResult(p);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (textController.text.trim().isNotEmpty) {
                    final plate = textController.text.trim().toUpperCase();
                    Navigator.pop(context);
                    _returnResult(plate);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    } else {
      // Full page manual checkout
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const ManualCheckoutSheet(),
      ).then((result) {
        if (result != null && result is String) {
          _returnResult(result);
        }
      });
    }
  }

  void _showTypePlateDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.t.tr('plateNumberLabel').split('(').first.trim(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.t.tr('plateNumberLabel'),
                  hintText: 'e.g. T123ABC',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  final plate = textController.text.trim().toUpperCase();
                  Navigator.pop(context);
                  _returnResult(plate);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                context.t.tr('awesome'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraInit = _cameraController != null && _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cameraInit) CameraPreview(_cameraController!) else const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          
          // Overlay for Scanner
          Container(
            decoration: ShapeDecoration(
              shape: _ScannerOverlayShape(
                borderColor: AppTheme.primary,
                borderWidth: 3.0,
                isQrMode: widget.mode == ScannerMode.qr,
              ),
            ),
          ),
          
          _ScanningLaser(isQrMode: widget.mode == ScannerMode.qr),

          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            top: 50,
            right: 20,
            child: TextButton.icon(
              icon: const Icon(LucideIcons.keyboard, color: Colors.white, size: 18),
              label: Text(widget.mode == ScannerMode.plate ? 'Type Plate' : 'Manual Entry', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (widget.mode == ScannerMode.plate) {
                  _showTypePlateDialog(context);
                } else {
                  _showSimulateDialog(context);
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primary.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTapDown: (_) => _setFlash(true),
                  onTapUp: (_) => _setFlash(false),
                  onTapCancel: () => _setFlash(false),
                  onLongPressStart: (_) => _setFlash(true),
                  onLongPressEnd: (_) => _setFlash(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: _isFlashOn ? AppTheme.primary : Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isFlashOn ? Colors.white : AppTheme.primary.withOpacity(0.6),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isFlashOn ? AppTheme.primary : Colors.transparent).withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.flashlight,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isFlashOn ? 'RELEASE TO TURN OFF' : 'HOLD FOR LIGHT',
                  style: TextStyle(
                    color: _isFlashOn ? Colors.white : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.mode == ScannerMode.qr ? 'Point camera at Ticket QR Code' : 'Point camera at License Plate',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_detectedText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: InkWell(
                      onTap: () {
                        if (widget.mode == ScannerMode.plate && _detectedText.isNotEmpty) {
                          _returnResult(_detectedText);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: widget.mode == ScannerMode.plate ? AppTheme.primary.withOpacity(0.9) : Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.mode == ScannerMode.plate ? 'TAP TO USE: $_detectedText' : 'Detecting: $_detectedText',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.mode == ScannerMode.plate) ...[
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double overlayOpacity;
  final bool isQrMode;

  const _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayOpacity = 0.5,
    required this.isQrMode,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    double scanAreaWidth = isQrMode ? rect.width * 0.65 : rect.width * 0.8;
    double scanAreaHeight = isQrMode ? rect.width * 0.65 : 150;
    
    Rect scanAreaRect = Rect.fromCenter(
      center: rect.center.translate(0, -50),
      width: scanAreaWidth,
      height: scanAreaHeight,
    );
    
    return Path()
      ..addRect(scanAreaRect)
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    double scanAreaWidth = isQrMode ? rect.width * 0.65 : rect.width * 0.8;
    double scanAreaHeight = isQrMode ? rect.width * 0.65 : 150;
    
    Rect scanAreaRect = Rect.fromCenter(
      center: rect.center.translate(0, -50),
      width: scanAreaWidth,
      height: scanAreaHeight,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(overlayOpacity)
      ..style = PaintingStyle.fill;
      
    final backgroundPath = Path()
      ..addRect(rect)
      ..addRect(scanAreaRect)
      ..fillType = PathFillType.evenOdd;
      
    canvas.drawPath(backgroundPath, backgroundPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final double cornerLength = 30.0;
    
    // Top Left
    canvas.drawLine(scanAreaRect.topLeft, scanAreaRect.topLeft.translate(cornerLength, 0), borderPaint);
    canvas.drawLine(scanAreaRect.topLeft, scanAreaRect.topLeft.translate(0, cornerLength), borderPaint);
    
    // Top Right
    canvas.drawLine(scanAreaRect.topRight, scanAreaRect.topRight.translate(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanAreaRect.topRight, scanAreaRect.topRight.translate(0, cornerLength), borderPaint);
    
    // Bottom Left
    canvas.drawLine(scanAreaRect.bottomLeft, scanAreaRect.bottomLeft.translate(cornerLength, 0), borderPaint);
    canvas.drawLine(scanAreaRect.bottomLeft, scanAreaRect.bottomLeft.translate(0, -cornerLength), borderPaint);
    
    // Bottom Right
    canvas.drawLine(scanAreaRect.bottomRight, scanAreaRect.bottomRight.translate(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanAreaRect.bottomRight, scanAreaRect.bottomRight.translate(0, -cornerLength), borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayOpacity: overlayOpacity,
      isQrMode: isQrMode,
    );
  }
}

class _ScanningLaser extends StatefulWidget {
  final bool isQrMode;
  const _ScanningLaser({required this.isQrMode});

  @override
  State<_ScanningLaser> createState() => _ScanningLaserState();
}

class _ScanningLaserState extends State<_ScanningLaser> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double scanAreaWidth = widget.isQrMode ? MediaQuery.of(context).size.width * 0.65 : MediaQuery.of(context).size.width * 0.8;
    double scanAreaHeight = widget.isQrMode ? MediaQuery.of(context).size.width * 0.65 : 150;
    
    _animation = Tween<double>(begin: -scanAreaHeight / 2, end: scanAreaHeight / 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, -50 + _animation.value),
            child: Container(
              width: scanAreaWidth - 10,
              height: 2,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ManualCheckoutSheet extends StatefulWidget {
  const ManualCheckoutSheet({Key? key}) : super(key: key);

  @override
  State<ManualCheckoutSheet> createState() => _ManualCheckoutSheetState();
}

class _ManualCheckoutSheetState extends State<ManualCheckoutSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehicleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final insideVehicles = provider.vehicles.where((v) {
      if (v['sessions'] == null || v['sessions'].isEmpty || v['sessions'][0]['status'] != 'INSIDE') {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final plate = v['plateNumber']?.toString().toLowerCase() ?? '';
      final session = v['sessions'][0];
      final ticketId = session['id']?.toString().toLowerCase() ?? '';
      return plate.contains(_searchQuery.toLowerCase()) || ticketId.contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manual Checkout',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Plate or Ticket No...',
                prefixIcon: const Icon(LucideIcons.search),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: insideVehicles.isEmpty
                ? const Center(child: Text('No vehicles found inside.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: insideVehicles.length,
                    itemBuilder: (context, index) {
                      final v = insideVehicles[index];
                      final session = v['sessions'][0];
                      final plate = v['plateNumber'] ?? 'Unknown';
                      final category = v['category']?['name'] ?? 'Unknown';
                      
                      final checkInDate = DateTime.tryParse(session['checkIn'] ?? '') ?? DateTime.now();
                      final diffMs = DateTime.now().difference(checkInDate).inMilliseconds;
                      final diffHrs = diffMs ~/ 3600000;
                      final diffMins = (diffMs % 3600000) ~/ 60000;
                      final durationStr = '${diffHrs}h ${diffMins}m';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Material(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    plate,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.ticket, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ticket: ${session['id'] != null ? (session['id'].length > 8 ? session['id'].substring(0, 8).toUpperCase() : session['id'].toUpperCase()) : 'N/A'}',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('Duration: $durationStr', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warning,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(LucideIcons.logOut, size: 16),
                            label: const Text('Checkout'),
                            onPressed: () {
                              Navigator.pop(context, session['id']);
                            },
                          ),
                        ),
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
