import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

class InputUser {
  late Uint8List plainText;
  late Uint8List passw;
  late bool isFile;
  late String fileName;
}
