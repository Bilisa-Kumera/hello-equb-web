import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

 final String socketServer = dotenv.env['BASE_URL'] ?? '';
 final String baseUrl = "${dotenv.env['BASE_URL']}api/v1";
 final String mediaUrl = dotenv.env['BASE_URL'] ?? '';


 String sendOtpUrl = "$baseUrl/user/auth/otp";
 String registerUserUrls = "$baseUrl/user/auth/signup";
 String loginUrl = "$baseUrl/user/auth/login";
 String profileUrl = "$baseUrl/user/auth/";

 String equbTypeUrl = "$baseUrl/user/equb-type";
 String equbCategoriesUrl = "$baseUrl/user/equb-category";
 String deviceTokenUrl = '$baseUrl/user/device-token';
 String bannersUrl = '$baseUrl/user/banner?state=active';
 String updatePersonnalUrl = '$baseUrl/user/profile/personal-info/';
 String banksUrl = '$baseUrl/user/profile/banks';
 String addFinancialUrl = '$baseUrl/user/profile/financial-info/';
 String updateFinancialUrl = '$baseUrl/user/profile/bank-account/';
 String getMyProfile = '$baseUrl/user/profile/me';
 String ekubsUrl = '$baseUrl/user/equb';
 String joinEkubGroupUrl = '$baseUrl/user/equb/join/group/';
 String joinEkubIndividualUrl = '$baseUrl/user/equb/join/individual/';
 String ekubPaymentsUrl = '$baseUrl/user/equb/payments/';
 String getEligibleUsers = '$baseUrl/user/equb/lottery/';
 String getServerTimeUrl = '$baseUrl/server-time';
 String ekubLotteriesUrl = '$baseUrl/user/equb/lotteries/';
 String addGuarantorInfoUrl = '$baseUrl/user/equb/guarantee/';
 String claimEqubUrl = '$baseUrl/user/equb/claim/';
 String joinEkubUrl = '$baseUrl/user/equb/join/';
 String companyBankUrl = '$baseUrl/company-bank?_page&_limit';
 String paymentUrl = '$baseUrl/user/payment/confirm/';
 String makePaymentUrl = '$baseUrl/user/equb/payment/';
 String pendingPaymentUrl = '$baseUrl/user/equb/payment/';
 String getMyPendingEqubs = '$baseUrl/user/equb/pending?_page&_limit';
 String getTransactionHistoryUrl = '$baseUrl/user/payment/transaction';
 String requestUrl = "$baseUrl/user/equb/request/";
 String forgetPasswordUrl = "$baseUrl/user/auth/forgot-password";
 String resetPasswordUrl = "$baseUrl/user/auth/reset-password";
 String getNotificationUrl = "$baseUrl/user/notification/getNotification";
 String getGuaranteeToBeUrl = "$baseUrl/user/equb/unwon-users";
 String saveGuaranteeIdUrl = "$baseUrl/user/equb/save-guarantee/";
 String getGuaranteeRequestUrl =
    "$baseUrl/user/equb/sendGuarantorNotificaton/";

 String getSavingEqubDetailUrl = "$baseUrl/user/equb/savingMember/";
 String getEqubReportUrl = "$baseUrl/user/report/";
 String refreshTokenUrl = "$baseUrl/user/auth/refresh-token";
 String declineRequestUrl = "$baseUrl/user/equb/sendDeleteNotification/";
 String financeAndOtherEqubsUrl =
    "$baseUrl/equbs/getFinanceAndOtherMobile/";
 String cooperateEqubUrl = "$baseUrl/user/cooperate";
 String validateCooperateUrl = "$baseUrl/user/cooperate/checkValidCoopreateCode";

// Equb history (completed/past equbs per user)
String getEqubHistoryUrl = "$baseUrl/user/equb/get-history-equbs";

final NumberFormat numberFormat = NumberFormat('#,##0.00');
