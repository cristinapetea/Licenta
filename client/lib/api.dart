import 'dart:io';
import 'package:flutter/foundation.dart';

class Api {
  static String get base {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000'; // Android Emulator
    return 'http://localhost:3000'; // iOS Simulator
  }
}
