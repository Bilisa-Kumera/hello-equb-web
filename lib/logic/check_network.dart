import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:ekubee/utils/lang_constants.dart';

class CheckNetwork extends StatefulWidget {
  final VoidCallback onRetry;

  const CheckNetwork({super.key, required this.onRetry});

  @override
  _CheckNetworkState createState() => _CheckNetworkState();
}

class _CheckNetworkState extends State<CheckNetwork> {
  late Connectivity _connectivity;
  late List<ConnectivityResult> _connectionStatus;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _checkNetworkStatus();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Check the initial network status
  void _checkNetworkStatus() async {
    _connectionStatus = await _connectivity.checkConnectivity();
    if (!_connectionStatus.contains(ConnectivityResult.none)) {
      Navigator.of(context).pop();
    }
  }

  // Update the connection status when it changes
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (!result.contains(ConnectivityResult.none)) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _openSettings() {
    if (Platform.isAndroid) {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.SETTINGS',
      );
      intent.launch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420.h,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_outlined,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 15),
              Text(
                AppKeys.enableInternet.tr(context),
                style: TextStyle(
                  fontFamily: 'Urbanists',
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppKeys.yourInternetSeems.tr(context),
                style: TextStyle(
                  fontFamily: 'Urbanists',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 20),
              CustomTextButton(
                text: AppKeys.enable.tr(context),
                onPressed: () async {
                  _openSettings();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: widget.onRetry,
                child: Text(
                  AppKeys.retry.tr(context),
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}