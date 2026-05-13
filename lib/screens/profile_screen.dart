
import 'package:ekubee/screens/home_screen.dart';
import 'package:ekubee/screens/terms_conditions_screen.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:ekubee/core/api_service_elper.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/screens/LoginScreenWithPin.dart';
import 'package:ekubee/screens/complete_profile_financial.dart';
import 'package:ekubee/screens/complete_profile_screen.dart';
import 'package:ekubee/screens/help_support.dart';
import 'package:ekubee/screens/notification_screen.dart';
import 'package:ekubee/screens/transaction_history.dart';
import 'package:ekubee/screens/equb_history_screen.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:ekubee/utils/language.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../utils/secure_storage.dart';
import 'referal_code.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  double progress = 0.0;

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
    getProfileImage();
    fullName =
        _firstAndMiddleName(dataController.retrieveData<String>('fullName'));
    getPercentage();
  }

  Future<String> getReferalCode() async {
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
    final data =
        await apiService.readAll(getMyProfile, bearerToken: accessToken);
    return data['data']['user']['userID'];
  }

  final DataController dataController = DataController();
  final ApiService apiService = ApiService();
  String? referalCode;

  Future<void> getPercentage() async {
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
    final data =
        await apiService.readAll(getMyProfile, bearerToken: accessToken);
    if (data['data']['user']['userID'] != null) {
      referalCode == data['data']['user']['userID'];
    } else {
      referalCode = 'N/A';
    }
    if (data != null) {
      setState(() {
        progress = data['data']['user']['profileCompletion'] / 100;
      });
    } else {}
  }

  String fullName = '';

  String profileAvatarUrl = '';

  Future<void> getProfileImage() async {
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
    final data = await apiService.readAll(profileUrl, bearerToken: accessToken);
    setState(() {
      profileAvatarUrl = data['user']['avatar'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          leading: IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const HomeScreen())),
              icon: const Icon(Icons.arrow_back)),
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      NetworkImage('$mediaUrl/images/avatar/$profileAvatarUrl'),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(AppKeys.welcomeBack.tr(context),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: () => getPercentage(),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => getPercentage(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (progress == 1.0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const CompleteProfileScreen(
                                              serviceCharge: ''))),
                              child: Text(AppKeys.personal.tr(context),
                                  style: const TextStyle(
                                      decoration: TextDecoration.underline)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const FinancialInformation(
                                              serviceCharge: ''))),
                              child: Text(AppKeys.financial.tr(context),
                                  style: const TextStyle(
                                      decoration: TextDecoration.underline)),
                            ),
                          ],
                        )
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                AppKeys.pleaseCompleteYourProfile.tr(context),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const CompleteProfileScreen(
                                              serviceCharge: ''))),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: Text(
                                AppKeys.lblContinue.tr(context),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8.0),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 22,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.green.shade700),
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: progress == 1.0
                                  ? Colors.white
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text("👤 ${AppKeys.account.tr(context)}",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildTile(
                    icon: Icons.person_outline,
                    label: AppKeys.editProfile.tr(context),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CompleteProfileScreen(
                                serviceCharge: '')))),
                _divider(),
                _buildTile(
                    icon: Icons.notifications_none,
                    label: AppKeys.notifications.tr(context),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationScreen()))),
                _divider(),
                _buildTile(
                    icon: Icons.language,
                    label: AppKeys.language.tr(context),
                    onTap: () => _showLanguageDialog(languageProvider)),
              ]),
              const SizedBox(height: 28),
              Text("💳 ${AppKeys.payment.tr(context)}",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildSettingsCard(
                [
                  _buildTile(
                      icon: Icons.history_toggle_off,
                      label: AppKeys.equbHistory.tr(context),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EqubHistoryScreen()))),
                  _divider(),
                  _buildTile(
                      icon: Icons.history,
                      label: AppKeys.transactionHistory.tr(context),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TransactionHistory()))),
                  _divider(),
                  _buildTile(
                      icon: Icons.help_outline,
                      label: AppKeys.helpAndSupport.tr(context),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => HelpAndSupportScreen()))),
                  _divider(),
                  _buildTile(
                    icon: Icons.rule_folder,
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
                            expectedAmount: 0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<String>(
                future: getReferalCode(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: LoadingAnimationWidget.threeRotatingDots(
                        color: AppColors.vibrantGreen,
                        size: 30,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Text("");
                  } else {
                    return ReferralCard(
                      referralCode: snapshot.data ?? "",
                      title: AppKeys.inviteFriendsEarn.tr(context),
                      primaryColor: AppColors.primary,
                      shareText: AppKeys.shareText.tr(context),
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
              CustomLogoutButton(
                text: AppKeys.logout.tr(context),
                onPressed: () {
                  dataController.updateData('isLoggedIn', false);
                  dataController.deleteData('accessToken');
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LoginScreenWithPin(phoneNumber: '')),
                    (_) => false,
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 2,
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 0.6);

  Widget _buildTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(
          AppKeys.selectLanguage.tr(context),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      child: Text(label),
    );
  }
}
