import 'package:flutter/foundation.dart';

class EncryptOrDecrypt with ChangeNotifier {
  bool _isEncrypt = false;
  bool get isEncrypt => _isEncrypt;
  set isEncrypt(bool value) {
    _isEncrypt = value;
    notifyListeners();
  }
}
