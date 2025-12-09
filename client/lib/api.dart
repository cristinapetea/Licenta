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
  static String get base {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://192.168.1.2:3000'; //  ipconfig
    return 'http://192.168.1.2:3000'; 
  }
}
