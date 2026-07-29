import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/notification_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';

import '../utils/secure_storage.dart';
import 'package:helloequb/utils/style_constants.dart';

class AcceptDeclineScreen extends StatefulWidget {
  final String? guaranteeNeedyId;
  final String? guaranteeTobeId;
  final String? equbId;
  final String? equbName;
  final String? equbAmount;
  final String? fullName;

  const AcceptDeclineScreen(
      {super.key,
      this.guaranteeNeedyId,
      this.guaranteeTobeId,
      this.equbId,
      this.equbName,
      this.equbAmount,
      this.fullName});

  @override
  State<AcceptDeclineScreen> createState() => _AcceptDeclineScreenState();
}

class _AcceptDeclineScreenState extends State<AcceptDeclineScreen> {
  final Dio _dio = Dio();
  final DataController dataController = DataController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.guaranteeNeedyId == null ||
          widget.guaranteeNeedyId!.isEmpty ||
          widget.equbName == null ||
          widget.equbName!.isEmpty ||
          widget.equbAmount == null ||
          widget.equbAmount!.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
      }
    });
  }

  Future<void> postSelected(BuildContext context, String endpoint, String id,
      Map<String, dynamic> data,
      {String? bearerToken}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200) {
        CustomSnackBar.show(context, 'Sent successfully', AppColors.primary);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ConfirmationDialog(
              title: AppKeys.requestAccepted.tr(context),
              message: AppKeys.youHaveSuccessfullyAccepted.tr(context),
              icon: Icons.check_circle,
              iconColor: AppColors.primary,
              details:
                  '${AppKeys.equbName.tr(context)}: ${widget.equbName ?? 'N/A'}\n${AppKeys.equbAmount.tr(context)}: ${numberFormat.format(double.tryParse(widget.equbAmount ?? '0') ?? 0)} ETB',
            );
          },
        );
      } else {
        CustomSnackBar.show(
            context, 'Error adding data. Try again!', AppColors.red);
      }
    } on DioException catch (error) {
      if (error.response != null) {
        if (error.response!.statusCode == 400) {
          CustomSnackBar.show(context,
              'Error ${error.response!.data['message']}', AppColors.red);
        } else {
          CustomSnackBar.show(context,
              'Error ${error.response!.data['message']}', AppColors.red);
        }
      }
    } catch (error) {}
  }

  Future<void> declineRequest(BuildContext context, String endpoint, String id,
      Map<String, dynamic> data,
      {String? bearerToken}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200) {
        CustomSnackBar.show(context, 'Sent successfully', AppColors.primary);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ConfirmationDialog(
              title: 'Request Declined',
              message: 'You have declined the request.',
              icon: Icons.cancel,
              iconColor: AppColors.red,
              details:
                  'Equb Name: ${widget.equbName ?? 'N/A'}\nAmount: ${numberFormat.format(double.tryParse(widget.equbAmount ?? '0') ?? 0)} ETB',
            );
          },
        );
      } else {
        CustomSnackBar.show(
            context, 'Error adding data. Try again!', AppColors.red);
      }
    } on DioException catch (error) {
      if (error.response != null) {
        if (error.response!.statusCode == 400) {
          CustomSnackBar.show(context,
              'Error ${error.response!.data['message']}', AppColors.red);
        } else {
          CustomSnackBar.show(context,
              'Error ${error.response!.data['message']}', AppColors.red);
        }
      }
    } catch (error) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.guaranteeNeedyId == null ||
        widget.guaranteeNeedyId!.isEmpty ||
        widget.equbName == null ||
        widget.equbName!.isEmpty ||
        widget.equbAmount == null ||
        widget.equbAmount!.isEmpty) {
      // Navigate immediately if data is missing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
          (route) => false,
        );
      });
      // Return empty container while navigation happens
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          AppKeys.guaranteeRequest.tr(context),
          style: AppTextStyles.poppins70020.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            shadowColor: AppColors.teal100,
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppKeys.doYouAccept.tr(context),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.poppins70020.copyWith(color: AppColors.black87),
                  ),
                  const SizedBox(height: 20),
                  // Guarantee Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DetailRow(
                          title: AppKeys.guaranteeNeedy.tr(context),
                          value: widget.fullName ?? 'N/A'),
                      DetailRow(
                          title: AppKeys.equbName.tr(context),
                          value: widget.equbName ?? 'N/A'),
                      DetailRow(
                        title: AppKeys.equbAmount.tr(context),
                        value:
                            "${numberFormat.format(double.tryParse(widget.equbAmount ?? '0') ?? 0)} ETB",
                        valueStyle: AppTextStyles.poppins70014.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          if (widget.equbId == null ||
                              widget.guaranteeNeedyId == null) {
                            CustomSnackBar.show(
                                context, 'Invalid request data', AppColors.red);
                            return;
                          }
                          String accessToken =
                              await SecureStorageHelper.getAccessToken() ?? '';
                          await postSelected(
                            context,
                            "$saveGuaranteeIdUrl${widget.equbId}",
                            await SecureStorageHelper.getUserId() ?? '',
                            {
                              "userId": widget.guaranteeNeedyId,
                              "guaranteToBe": widget.guaranteeTobeId,
                              "fullName": dataController
                                      .retrieveData<String>('fullName') ??
                                  '',
                            },
                            bearerToken: accessToken,
                          );
                        },
                        icon: const Icon(Icons.check, color: AppColors.white),
                        label: Text(
                          AppKeys.accept.tr(context),
                          style: AppTextStyles.poppins70014.copyWith(color: AppColors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor:
                              AppColors.neonSuccessGreen.withOpacity(0.5),
                          elevation: 5,
                        ),
                      ),
                      const SizedBox(width: 20),
                      TextButton.icon(
                        onPressed: () async {
                          if (widget.guaranteeNeedyId == null) {
                            CustomSnackBar.show(
                                context, 'Invalid request data', AppColors.red);
                            return;
                          }
                          String accessToken = dataController
                                  .retrieveData<String>('accessToken') ??
                              '';
                          await declineRequest(
                            context,
                            "$declineRequestUrl${widget.guaranteeNeedyId}",
                            widget.guaranteeNeedyId!,
                            {
                              "userId": widget.guaranteeNeedyId!,
                              "fullName": dataController
                                      .retrieveData<String>('fullName') ??
                                  'N/A'
                            },
                            bearerToken: accessToken,
                          );
                        },
                        icon: const Icon(Icons.close, color: AppColors.white),
                        label: Text(
                          AppKeys.decline.tr(context),
                          style: AppTextStyles.poppins70014.copyWith(color: AppColors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor: AppColors.red.withOpacity(0.5),
                          elevation: 5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final TextStyle? valueStyle;

  const DetailRow({
    super.key,
    required this.title,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.poppins60016.copyWith(color: AppColors.black54),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  AppTextStyles.poppins40016.copyWith(color: AppColors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final List<Color> gradientColors;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.white),
      label: Text(
        label,
        style: AppTextStyles.poppins70016.copyWith(color: AppColors.white),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.transparent,
        shadowColor: gradientColors.last.withOpacity(0.5),
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String details;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        children: [
          Icon(icon, size: 30, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.poppins70018,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 10),
          Text(
            details,
            textAlign: TextAlign.center,
            style: AppTextStyles.poppins70014.copyWith(color: AppColors.black87),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HomeScreen())),
          child: Text(AppKeys.ok.tr(context),
              style: AppTextStyles.poppins70014.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}
