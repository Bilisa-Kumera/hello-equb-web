import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/provider/joined_equbs_status_provider.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/complete_profile_financial.dart';
import 'package:helloequb/screens/complete_profile_screen.dart';
import 'package:helloequb/screens/equb_history_screen.dart';
import 'package:helloequb/screens/help_support.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/notification_screen.dart';
import 'package:helloequb/screens/referal_code.dart';
import 'package:helloequb/screens/terms_conditions_screen.dart';
import 'package:helloequb/screens/transaction_history.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/language.dart';
import 'package:helloequb/utils/secure_storage.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedInShell;

  const ProfileScreen({super.key, this.embedInShell = false});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  double progress = 0.0;
  String fullName = '';
  String phoneNumber = '';
  String profileAvatarUrl = '';
  bool _loading = true;

  final DataController dataController = DataController();
  final ApiService apiService = ApiService();

  String _firstAndMiddleName(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.take(2).join(' ');
  }

  @override
  void initState() {
    super.initState();
    fullName =
        _firstAndMiddleName(dataController.retrieveData<String>('fullName'));
    phoneNumber =
        (dataController.retrieveData<String>('phoneNumber') ?? '').trim();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() => _loading = true);
    await Future.wait([
      getProfileImage(),
      getPercentage(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> getPercentage() async {
    try {
      final accessToken = await SecureStorageHelper.getAccessToken() ?? '';
      final data =
          await apiService.readAll(getMyProfile, bearerToken: accessToken);
      if (data == null || !mounted) return;

      final user = data['data']?['user'];
      if (user is! Map) return;

      final completion = user['profileCompletion'];
      final phone = (user['phoneNumber'] ?? '').toString().trim();
      final name = _firstAndMiddleName(user['fullName']?.toString());

      setState(() {
        progress = (completion is num)
            ? (completion / 100).clamp(0.0, 1.0).toDouble()
            : progress;
        if (phone.isNotEmpty) {
          phoneNumber = phone;
          dataController.storeData('phoneNumber', phone);
        }
        if (name.isNotEmpty) {
          fullName = name;
          dataController.storeData('fullName', user['fullName']?.toString());
        }
      });
    } catch (_) {}
  }

  Future<void> getProfileImage() async {
    try {
      final accessToken = await SecureStorageHelper.getAccessToken() ?? '';
      final data =
          await apiService.readAll(profileUrl, bearerToken: accessToken);
      if (!mounted) return;
      setState(() {
        profileAvatarUrl = (data?['user']?['avatar'] ?? '').toString().trim();
      });
    } catch (_) {
      if (mounted) setState(() => profileAvatarUrl = '');
    }
  }

  bool get _isProfileComplete => progress >= 1.0;
  bool get _hasAvatar => profileAvatarUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: widget.embedInShell
            ? null
            : IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black87,
                  size: 18,
                ),
              ),
        title: Text(
          AppKeys.myAccount.tr(context),
          style: AppTextStyles.poppins60016,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade700, size: 20),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshProfile,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          children: [
            _buildHeaderCard(context),
            if (!_isProfileComplete) ...[
              SizedBox(height: 12.h),
              _buildIncompleteProfileCard(context),
            ],
            SizedBox(height: 20.h),
            _sectionLabel(AppKeys.account.tr(context)),
            SizedBox(height: 8.h),
            _buildSettingsCard([
              _buildTile(
                icon: Icons.person_outline_rounded,
                label: AppKeys.editProfile.tr(context),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CompleteProfileScreen(serviceCharge: ''),
                  ),
                ),
              ),
              if (_isProfileComplete) ...[
                _divider(),
                _buildTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: AppKeys.financial.tr(context),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const FinancialInformation(serviceCharge: ''),
                    ),
                  ),
                ),
              ],
              _divider(),
              _buildTile(
                icon: Icons.notifications_none_rounded,
                label: AppKeys.notifications.tr(context),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                ),
              ),
              _divider(),
              _buildTile(
                icon: Icons.language_rounded,
                label: AppKeys.language.tr(context),
                onTap: () => _showLanguageDialog(languageProvider),
              ),
            ]),
            SizedBox(height: 20.h),
            _sectionLabel(AppKeys.payment.tr(context)),
            SizedBox(height: 8.h),
            _buildSettingsCard([
              _buildTile(
                icon: Icons.history_toggle_off_rounded,
                label: AppKeys.equbHistory.tr(context),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EqubHistoryScreen(),
                  ),
                ),
              ),
              _divider(),
              _buildTile(
                icon: Icons.receipt_long_outlined,
                label: AppKeys.transactionHistory.tr(context),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistory(),
                  ),
                ),
              ),
              _divider(),
              _buildTile(
                icon: Icons.help_outline_rounded,
                label: AppKeys.helpAndSupport.tr(context),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelpAndSupportScreen(),
                  ),
                ),
              ),
              _divider(),
              _buildTile(
                icon: Icons.description_outlined,
                label: AppKeys.termsAndConditions.tr(context),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsConditionsScreen(
                      termAndCondition: '',
                      termAndConditionInAmharic: '',
                      ekubId: '',
                      ekubAmount: '',
                      ekubName: '',
                      ekubRound: '',
                      selectedAmount: '',
                      selectedJoinOption: [],
                      expectedAmount: 0,
                    ),
                  ),
                ),
              ),
            ]),
            SizedBox(height: 16.h),
            if (phoneNumber.isNotEmpty)
              ReferralCard(
                referralCode: phoneNumber,
                title: AppKeys.inviteFriendsEarn.tr(context),
                primaryColor: AppColors.primary,
                shareText: AppKeys.shareText.tr(context),
              )
            else if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20.h),
            CustomLogoutButton(
              text: AppKeys.logout.tr(context),
              onPressed: () {
                dataController.updateData('isLoggedIn', false);
                dataController.deleteData('accessToken');
                context
                    .read<JoinedEqubsStatusProvider>()
                    .setHasJoinedEqubs(false);
                context.read<JoinedEqubsStatusProvider>().stopApprovalWatch();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreenWithPin(phoneNumber: ''),
                  ),
                  (_) => false,
                );
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );

    if (widget.embedInShell) return scaffold;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        return false;
      },
      child: scaffold,
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28.r),
            child: _hasAvatar
                ? Image.network(
                    '$mediaUrl/images/avatar/$profileAvatarUrl',
                    width: 56.w,
                    height: 56.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _splashAvatar(),
                  )
                : _splashAvatar(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? AppKeys.welcomeBack.tr(context) : fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.poppins60014,
                ),
                if (phoneNumber.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    phoneNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionMuted.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _splashAvatar() {
    return Container(
      width: 56.w,
      height: 56.w,
      color: Colors.white,
      padding: EdgeInsets.all(8.w),
      child: Image.asset(
        'assets/splash.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildIncompleteProfileCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppKeys.pleaseCompleteYourProfile.tr(context),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CompleteProfileScreen(serviceCharge: ''),
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppKeys.lblContinue.tr(context),
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '${(progress * 100).round()}%',
            style: AppTextStyles.captionMuted.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.poppins60013.copyWith(color: Colors.grey.shade800),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 0.6,
        color: Colors.grey.shade200,
        indent: 52.w,
      );

  Widget _buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12.sp,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(
          AppKeys.selectLanguage.tr(context),
          style: AppTextStyles.poppins60014,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        children: [
          _langOption('English', 'en', lang),
          _langOption('አማርኛ', 'am', lang),
          _langOption('Afaan Oromoo', 'om', lang),
          _langOption('ትግርኛ', 'ti', lang),
        ],
      ),
    );
  }

  Widget _langOption(String label, String code, LanguageProvider lang) {
    return SimpleDialogOption(
      onPressed: () {
        lang.changeLanguage(Locale(code, ''));
        Navigator.pop(context);
      },
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}
