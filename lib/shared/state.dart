// ignore_for_file: avoid_positional_boolean_parameters

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:wakelock/wakelock.dart';

class AppState extends ChangeNotifier {
  bool isRunning = false;
  bool isProcessing = false;

  void setRunning(bool value) {
    isRunning = value;
    Wakelock.toggle(enable: value);
    notifyListeners();
  }

  void setProcessing(bool value) {
    isProcessing = value;
    notifyListeners();
  }

  void stopTheWorld() {
    isRunning = false;
    isProcessing = false;
    Wakelock.disable();
    notifyListeners();
  }
}
