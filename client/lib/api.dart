import 'dart:io';
import 'package:flutter/foundation.dart';

/*
class Api {
  // DOAR host + port aici (fără /api)
  static String get base {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.3.2:3000'; // Genymotion
    return 'http://localhost:3000';                        // iOS sim
  }

  // prefixul comun pt. auth
  static const auth = '/api/auth';
}
*/

class Api {
  // DOAR host + port aici (fără /api)
  static String get base {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://192.168.66.159:3000'; // ← Laptop-ul meu cu ipconfig
    return 'http://192.168.66.159:3000'; 
  }
}
