// ignore_for_file: deprecated_member_use

import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/lang_constants.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _faqKeys = const [
    {
      'questionKey': AppKeys.viewTransactionHistory,
      'answerKey': AppKeys.transactionHistoryAnswer,
    },
    {
      'questionKey': AppKeys.viewLotteryWinners,
      'answerKey': AppKeys.lotteryWinnersAnswer,
    },
    {
      'questionKey': AppKeys.howToJoinSpecialEqub,
      'answerKey': AppKeys.joinSpecialEqubAnswer,
    },
    {
      'questionKey': AppKeys.whatIsRequest,
      'answerKey': AppKeys.requestAnswer,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<Map<String, String>> faqs = _faqKeys.where((item) {
      final String q = (item['questionKey'] ?? '').tr(context).toLowerCase();
      final String a = (item['answerKey'] ?? '').tr(context).toLowerCase();
      if (query.isEmpty) return true;
      return q.contains(query) || a.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppKeys.helpAndSupport.tr(context),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.grey50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.08),
              AppColors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.green600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppKeys.howCanWeHelp.tr(context),
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      AppKeys.findAnswers.tr(context),
                      style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.white.withOpacity(0.9)),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.22),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          hintText: AppKeys.findAnswers.tr(context),
                          hintStyle: TextStyle(
                            color: AppColors.white.withOpacity(0.75),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.white.withOpacity(0.9)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              _buildSectionHeader(AppKeys.frequentlyAskedQuestions.tr(context)),
              SizedBox(height: 16.h),
              faqs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          textScaleFactor: 1.0,
                          AppKeys.noData.tr(context),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.black54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: faqs.length,
                      itemBuilder: (context, index) {
                        return _buildFAQItem(
                          (faqs[index]['questionKey'] ?? '').tr(context),
                          (faqs[index]['answerKey'] ?? '').tr(context),
                        );
                      },
                    ),
              SizedBox(height: 30.h),
              _buildSectionHeader(AppKeys.contactSupport.tr(context)),
              SizedBox(height: 16.h),
              _buildSupportOption(
                index: 0,
                icon: Icons.phone,
                title: AppKeys.callUs.tr(context),
                subtitle: AppKeys.available247.tr(context),
              ),
              _buildSupportOption(
                index: 1,
                icon: Icons.email,
                title: AppKeys.emailUs.tr(context),
                subtitle: 'helloequb@gmail.com',
              ),
              _buildSupportOption(
                index: 2,
                icon: Icons.chat,
                title: AppKeys.whatsappUs.tr(context),
                subtitle: AppKeys.chatWithSupport.tr(context),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          collapsedBackgroundColor: AppColors.white,
          backgroundColor: AppColors.white,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.green50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: AppColors.primary),
          ),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.black87,
            ),
          ),
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              color: AppColors.green50,
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.white, AppColors.green50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _launchSupportOption(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.green100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchSupportOption(int option) async {
    String url;
    switch (option) {
      case 0:
        url = 'tel:+251946494949';
        break;
      case 1:
        url = 'mailto:helloequb@gmail.com';
        break;
      case 2:
        url = 'https://wa.me/251946494949';
        break;
      default:
        url = '';
    }

    if (url.isEmpty) return;

    final bool ok = await canLaunch(url);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppKeys.errorTryAgain.tr(context))),
      );
      return;
    }

    await launch(url);
  }
}
