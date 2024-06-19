import 'package:flutter/foundation.dart';

class ProgressApp with ChangeNotifier {
  double _proses = 0;
  double get proses => _proses;
  set proses(double value) {
    _proses = value;
    notifyListeners();
  }
}
