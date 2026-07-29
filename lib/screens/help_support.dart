// ignore_for_file: deprecated_member_use

import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/lang_constants.dart';
import 'package:helloequb/utils/style_constants.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.black87,
            size: 20,
          ),
        ),
        title: Text(
          AppKeys.helpAndSupport.tr(context),
          style: AppTextStyles.poppins60016.copyWith(color: AppColors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.poppins40014.copyWith(color: AppColors.black87),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 12.h),
                  hintText: AppKeys.findAnswers.tr(context),
                  hintStyle: AppTextStyles.poppins40013.copyWith(color: AppColors.black54),
                  prefixIcon: const Icon(Icons.search, color: AppColors.black54, size: 20),
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // FAQ Section
            Text(
              AppKeys.frequentlyAskedQuestions.tr(context),
              style: AppTextStyles.poppins60014.copyWith(color: AppColors.black87),
            ),
            SizedBox(height: 12.h),
            faqs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        AppKeys.noData.tr(context),
                        style: AppTextStyles.poppins40013.copyWith(color: AppColors.black54),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: faqs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildFAQItem(
                        (faqs[index]['questionKey'] ?? '').tr(context),
                        (faqs[index]['answerKey'] ?? '').tr(context),
                      );
                    },
                  ),
            SizedBox(height: 28.h),

            // Contact Support Section
            Text(
              AppKeys.contactSupport.tr(context),
              style: AppTextStyles.poppins60014.copyWith(color: AppColors.black87),
            ),
            SizedBox(height: 12.h),
            _buildSupportOption(
              icon: Icons.phone_outlined,
              title: AppKeys.callUs.tr(context),
              subtitle: '+251 946 494 949',
              onTap: () => _launchUrl('tel:+251946494949'),
            ),
            SizedBox(height: 8.h),
            _buildSupportOption(
              icon: Icons.email_outlined,
              title: AppKeys.emailUs.tr(context),
              subtitle: 'helloequb@gmail.com',
              onTap: () => _launchUrl('mailto:helloequb@gmail.com'),
            ),
            SizedBox(height: 8.h),
            _buildSupportOption(
              icon: Icons.chat_outlined,
              title: AppKeys.whatsappUs.tr(context),
              subtitle: AppKeys.chatWithSupport.tr(context),
              onTap: () => _launchUrl('https://wa.me/251946494949'),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          title: Text(
            question,
            style: AppTextStyles.poppins50013.copyWith(color: AppColors.black87),
          ),
          iconColor: AppColors.black54,
          collapsedIconColor: AppColors.black54,
          children: [
            Text(
              answer,
              style: AppTextStyles.poppins40012.copyWith(
                color: AppColors.black54,
                height: 1.5,
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.grey50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.poppins50013.copyWith(color: AppColors.black87),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: AppTextStyles.poppins40012.copyWith(color: AppColors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.black54),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppKeys.errorTryAgain.tr(context))),
      );
    }
  }
}
