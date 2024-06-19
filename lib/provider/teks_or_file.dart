import 'package:flutter/foundation.dart';

class TeksOrFile with ChangeNotifier {
  bool _isTeks = true;
  bool get isTeks => _isTeks;
  set isTeks(bool value) {
    _isTeks = value;
    notifyListeners();
  }
}
