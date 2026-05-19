import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/login_screen_with_pin.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

class TokenHelper {
  static Future<void> checkTokenExpiration({
    required BuildContext context,
    required Dio dio,
    required String refreshTokenUrl,
    required String refreshToken,
  }) async {
    final DataController dataController = DataController();
    try {
      final response = await dio.post(
        refreshTokenUrl,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $refreshToken",
          },
        ),
      );

      if (response.statusCode == 200) {
        // dataController.storeData('accessToken', response.data['accessToken']);
        // dataController.storeData('refreshToken', response.data['refreshToken']);
      } else {
        _handleTokenExpired(context);
      }
    } on DioError catch (error) {
      if (error.response?.statusCode == 401) {
        _handleTokenExpired(context);
      } else {
        // CustomSnackBar.show(
        //   context,
        //   'Network error',
        //   AppColors.red,
        // );
      }
    } catch (error) {}
  }

  static void _handleTokenExpired(BuildContext context) {
    CustomSnackBar.show(context, "Token Expired", AppColors.red);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LoginScreenWithPin(phoneNumber: ''))); // Use named route
  }
}
