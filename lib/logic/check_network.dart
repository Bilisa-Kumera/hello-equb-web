import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/lang_constants.dart';

import 'open_device_settings.dart';
import 'package:helloequb/utils/style_constants.dart';

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
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 8),
              Text(
                AppKeys.yourInternetSeems.tr(context),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 20),
              CustomTextButton(
                text: AppKeys.enable.tr(context),
                onPressed: () async {
                  await openDeviceSettings();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: widget.onRetry,
                child: Text(
                  AppKeys.retry.tr(context),
                  style: AppTextStyles.poppins40014.copyWith(color: Theme.of(context).primaryColor),
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
