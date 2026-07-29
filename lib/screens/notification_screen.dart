// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/secure_storage.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:intl/intl.dart';

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
              try {
                final dateA = dateFormat.parse(a['updatedAt']);
                final dateB = dateFormat.parse(b['updatedAt']);
                return dateB.compareTo(dateA);
              } catch (_) {
                return 0;
              }
            });
          _loading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load notifications';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppKeys.errorTryAgain.tr(context);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 18,
          ),
        ),
        title: Text(
          AppKeys.notifications.tr(context),
          style: AppTextStyles.poppins60014,
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchNotifications,
        child: _loading
            ? ListView(
                children: [
                  SizedBox(height: 120.h),
                  const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              )
            : _errorMessage != null
                ? ListView(
                    children: [
                      SizedBox(height: 100.h),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            children: [
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: Colors.red.shade400),
                              ),
                              SizedBox(height: 12.h),
                              TextButton(
                                onPressed: () {
                                  setState(() => _loading = true);
                                  _fetchNotifications();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                                child: Text(
                                  AppKeys.retry.tr(context),
                                  style: AppTextStyles.button
                                      .copyWith(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _notifications.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: 100.h),
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 40.sp,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 10.h),
                          Center(
                            child: Text(
                              AppKeys.noData.tr(context),
                              style: AppTextStyles.captionMuted,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          return NotificationCard(
                            notification: _notifications[index],
                          );
                        },
                      ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? 'No Title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.poppins60014,
                ),
                SizedBox(height: 4.h),
                Text(
                  notification['body'] ?? 'No Message',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '${notification['createdAt'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionMuted.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
