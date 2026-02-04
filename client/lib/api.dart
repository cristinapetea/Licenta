import 'dart:io';
import 'package:flutter/foundation.dart';


class Api {
  static String get base {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://192.168.1.3:3000'; 
    return 'http://192.168.1.3:3000'; 
  }
}
