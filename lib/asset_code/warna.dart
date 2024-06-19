import 'dart:ui';

import 'package:flutter/material.dart';

class Warna {
  ///warna background AppBar
  static List<Color> bab = [
    Colors.blue.shade400,
    Colors.black,
  ];

  ///warna background loading process
  static List<Color> blc = [
    Colors.blue.shade700,
    Colors.green.shade900.withOpacity(0.7),
  ];

  ///warna button ganti pertama
  static List<Color> sbca = [
    Colors.grey.shade400,
    const Color(0xff153415),
  ];

  ///Warna Switch button b
  static List<Color> sbcb = [
    Colors.blue.shade800,
    Colors.green.shade900,
  ];

  ///warna box A
  static List<Color> bca = [
    Colors.grey.shade400,
    Colors.green.withOpacity(0.2),
  ];

  ///warna font A
  static List<Color> fca = [
    Colors.black,
    Colors.green,
  ];

  /// warna font B
  static List<Color> fcb = [
    const Color(0xffcccccc),
  ];

  ///warna background body
  static List<Color> bbc = [
    const Color(0xffcccccc),
    const Color(0xff333333),
  ];
  static int idx = 0;
}
