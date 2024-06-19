import 'package:flutter/foundation.dart';

class OutputProses with ChangeNotifier {
  String _tulisan = "";
  String get tulisan => _tulisan;
  set tulisan(String value) {
    _tulisan = value;
    notifyListeners();
  }
}
