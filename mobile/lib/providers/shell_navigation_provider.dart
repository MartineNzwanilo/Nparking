import 'package:flutter/material.dart';

class ShellNavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String? prefilledPlate;

  int get currentIndex => _currentIndex;

  void setIndex(int index, {int maxIndex = 4, String? prefilledPlate}) {
    final clamped = index.clamp(0, maxIndex);
    this.prefilledPlate = prefilledPlate;
    _currentIndex = clamped;
    notifyListeners();
  }

  void clearPrefilledPlate() {
    prefilledPlate = null;
    notifyListeners();
  }
}
