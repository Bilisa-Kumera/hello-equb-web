import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

const String _defaultBaseUrl = 'https://api.hello-equb.com/';

String _normalizeBaseUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.endsWith('/') ? trimmed : '$trimmed/';
}

String get _baseUrlEnv {
  final env = dotenv.env['BASE_URL'];
  if (env == null || env.trim().isEmpty) return _defaultBaseUrl;
  return env;
}

String get socketServer => _baseUrlEnv;
String get mediaUrl => _baseUrlEnv;
String get baseUrl {
  final base = _normalizeBaseUrl(_baseUrlEnv);
  if (base.isEmpty) return '';
  return '${base}api/v1';
}

String get sendOtpUrl => "$baseUrl/user/auth/otp";
String get registerUserUrls => "$baseUrl/user/auth/signup";
String get loginUrl => "$baseUrl/user/auth/login";
String get profileUrl => "$baseUrl/user/auth/";

String get equbTypeUrl => "$baseUrl/user/equb-type";
String get equbCategoriesUrl => "$baseUrl/user/equb-category";
String get deviceTokenUrl => '$baseUrl/user/device-token';
String get bannersUrl => '$baseUrl/user/banner?state=active';
String get updatePersonnalUrl => '$baseUrl/user/profile/personal-info/';
String get banksUrl => '$baseUrl/user/profile/banks';
String get addFinancialUrl => '$baseUrl/user/profile/financial-info/';
String get updateFinancialUrl => '$baseUrl/user/profile/bank-account/';
String get getMyProfile => '$baseUrl/user/profile/me';
String get ekubsUrl => '$baseUrl/user/equb';
String get joinEkubGroupUrl => '$baseUrl/user/equb/join/group/';
String get joinEkubIndividualUrl => '$baseUrl/user/equb/join/individual/';
String get ekubPaymentsUrl => '$baseUrl/user/equb/payments/';
String get getEligibleUsers => '$baseUrl/user/equb/lottery/';
String get getServerTimeUrl => '$baseUrl/server-time';
String get ekubLotteriesUrl => '$baseUrl/user/equb/lotteries/';
String get addGuarantorInfoUrl => '$baseUrl/user/equb/guarantee/';
String get claimEqubUrl => '$baseUrl/user/equb/claim/';
String get joinEkubUrl => '$baseUrl/user/equb/join/';
String get joinMiniAppEkubUrl => '$baseUrl/user/equb/joinMiniApp/';
String get companyBankUrl => '$baseUrl/company-bank?_page&_limit';
String get paymentUrl => '$baseUrl/user/payment/confirm/';
String get makePaymentUrl => '$baseUrl/user/equb/payment/';
String get pendingPaymentUrl => '$baseUrl/user/equb/payment/';
String get getMyPendingEqubs => '$baseUrl/user/equb/pending?_page&_limit';
String get getTransactionHistoryUrl => '$baseUrl/user/payment/transaction';
String get requestUrl => "$baseUrl/user/equb/request/";
String get forgetPasswordUrl => "$baseUrl/user/auth/forgot-password";
String get resetPasswordUrl => "$baseUrl/user/auth/reset-password";
String get getNotificationUrl => "$baseUrl/user/notification/getNotification";
String get getGuaranteeToBeUrl => "$baseUrl/user/equb/unwon-users";
String get saveGuaranteeIdUrl => "$baseUrl/user/equb/save-guarantee/";
String get getGuaranteeRequestUrl =>
    "$baseUrl/user/equb/sendGuarantorNotificaton/";
String get lotteriesListUrl => "$baseUrl/user/equb/getLotteriesAllTime/";
String get getSavingEqubDetailUrl => "$baseUrl/user/equb/savingMember/";
String get getEqubReportUrl => "$baseUrl/user/report/";
String get refreshTokenUrl => "$baseUrl/user/auth/refresh-token";
String get declineRequestUrl => "$baseUrl/user/equb/sendDeleteNotification/";
String get financeAndOtherEqubsUrl =>
    "$baseUrl/equbs/getFinanceAndOtherMobile/";
String get cooperateEqubUrl => "$baseUrl/user/cooperate";
String get validateCooperateUrl =>
    "$baseUrl/user/cooperate/checkValidCoopreateCode";
String get checkJoinUrl => "$baseUrl/user/equb/check-join";

// Equb history (completed/past equbs per user)
String get getEqubHistoryUrl => "$baseUrl/user/equb/get-history-equbs";

final NumberFormat numberFormat = NumberFormat('#,##0.00');
