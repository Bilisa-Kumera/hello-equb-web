// ignore_for_file: deprecated_member_use

import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:intl/intl.dart';

import '../utils/secure_storage.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Dio _dio = Dio();
  bool _loading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  final DataController dataController = DataController();

  Future<void> _fetchNotifications() async {
    try {
      final response = await _dio
          .get("$getNotificationUrl/${await SecureStorageHelper.getUserId()}");
      if (response.statusCode == 200) {
        final dateFormat = DateFormat('EEEE, MMMM d, y \'at\' hh:mm:ss a');

        setState(() {
          _notifications = List<Map<String, dynamic>>.from(
              response.data['data']['notifications'])
            ..sort((a, b) {
              final dateA = dateFormat.parse(a['updatedAt']);
              final dateB = dateFormat.parse(b['updatedAt']);
              return dateB.compareTo(dateA);
            });
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load notifications';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: InkWell(
                onTap: () => Navigator.pop(context),
                child:
                    const Icon(Icons.arrow_back_ios, color: AppColors.white)),
          ),
        ),
        title: Text(
          textScaleFactor: 1.0,
          AppKeys.notifications.tr(context),
          style: const TextStyle(
              color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(
              child: SpinKitFadingCircle(
                color: AppColors.primary,
                size: 31.0,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    textScaleFactor: 1.0,
                    _errorMessage!,
                    style: TextStyle(color: AppColors.red, fontSize: 16.sp),
                  ),
                )
              : !_loading && _notifications.isEmpty
                  ? Center(
                      child: Text(AppKeys.noData.tr(context)),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return NotificationCard(notification: notification);
                      },
                    ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [AppColors.forestGreenPrimary, AppColors.jungleGreen],

            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16.0),
          leading: CircleAvatar(
            backgroundColor: AppColors.white.withOpacity(0.2),
            child: const Icon(Icons.notifications, color: AppColors.white),
          ),
          title: Text(
            textScaleFactor: 1.0,
            notification['title'] ?? 'No Title',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8.0),
              Text(
                textScaleFactor: 1.0,
                notification['body'] ?? 'No Message',
                style: TextStyle(
                  color: AppColors.white60,
                  fontSize: 15.sp,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  textScaleFactor: 1.0,
                  notification['createdAt'],
                  style: TextStyle(
                    color: AppColors.white60,
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
