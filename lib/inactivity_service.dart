import 'dart:async';
import 'package:flutter/widgets.dart';

class InactivityService with WidgetsBindingObserver {
  final Duration _inactivityThreshold = const Duration(minutes: 5);
  Timer? _checkInactivityTimer;
  DateTime? _lastBackgroundTime;
  final void Function() onLogoutCallback;

  InactivityService({required this.onLogoutCallback});

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkInactivityTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    } else if (state == AppLifecycleState.paused) {
      _handleAppPaused(); 
    }
  }

  void _handleAppResumed() {
    if (_lastBackgroundTime != null &&
        DateTime.now().difference(_lastBackgroundTime!) >= _inactivityThreshold) {
      _logoutUser(); 
    } else {
      _lastBackgroundTime = null; 
      _checkInactivityTimer?.cancel(); 
    }
  }

  void _handleAppPaused() {
    _lastBackgroundTime = DateTime.now();
    _checkInactivityTimer?.cancel();
    _checkInactivityTimer = Timer(_inactivityThreshold, () {
      _logoutUser(); 
    });
  }

  void _logoutUser() {
    onLogoutCallback();
  }

  void updateInteractionTime() {
    _lastBackgroundTime = null;
    _checkInactivityTimer?.cancel();
  }
}
