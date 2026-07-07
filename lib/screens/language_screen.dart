import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:provider/provider.dart';
import 'package:helloequb/screens/login_screen.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/language.dart';

class LanguageSelection extends StatefulWidget {
  const LanguageSelection({super.key});

  @override
  State<LanguageSelection> createState() => _LanguageSelectionState();
}

class _LanguageSelectionState extends State<LanguageSelection> {
  final DataController dataController = DataController();
  String? _selectedLanguageCode; // 'am' | 'en'
  bool _showError = false;

  void _selectLanguage(String code) {
    setState(() {
      _selectedLanguageCode = code;
      _showError = false;
    });
  }

  Locale _localeFor(String code) {
    switch (code) {
      case 'am':
        return const Locale('am', '');
      case 'en':
      default:
        return const Locale('en', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.12),
              AppColors.white,
              AppColors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.18),
                        AppColors.primary.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.14)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.language,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              textScaleFactor: 1.0,
                              AppKeys.pleaseSelectLanguage.tr(context),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              textScaleFactor: 1.0,
                              AppKeys.selectLanguage.tr(context),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                        color: AppColors.darkOverlay.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLanguageTile(
                        language: 'አማርኛ',
                        flag: 'assets/etflag.png',
                        isSelected: _selectedLanguageCode == 'am',
                        onTap: () => _selectLanguage('am'),
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageTile(
                        language: 'English',
                        flag: 'assets/usflag.png',
                        isSelected: _selectedLanguageCode == 'en',
                        onTap: () => _selectLanguage('en'),
                      ),
                      if (_showError) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                textScaleFactor: 1.0,
                                AppKeys.pleaseSelectLanguage.tr(context),
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      CustomTextButton(
                        text: AppKeys.lblContinue.tr(context),
                        onPressed: () {
                          if (_selectedLanguageCode == null) {
                            setState(() {
                              _showError = true;
                            });
                            return;
                          }

                          dataController.storeData("isFirstTime", false);
                          languageProvider
                              .changeLanguage(_localeFor(_selectedLanguageCode!));
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required String language,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.black12,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(isSelected ? 0.07 : 0.03),
            blurRadius: isSelected ? 16 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    flag,
                    width: 34,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    textScaleFactor: 1.0,
                    language,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black87,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : AppColors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.black12,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          size: 16, color: AppColors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

