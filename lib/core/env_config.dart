/// Compile-time configuration via `--dart-define` or `--dart-define-from-file`.
class EnvConfig {
  const EnvConfig._();

  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String merchantAppId = String.fromEnvironment('MERCHANT_APP_ID');
  static const String superappTokenExchangePath =
      String.fromEnvironment('SUPERAPP_TOKEN_EXCHANGE_PATH');
  static const String superappBaseUrl =
      String.fromEnvironment('SUPERAPP_BASE_URL');
  static const String telebirrBaseUrl =
      String.fromEnvironment('TELEBIRR_BASE_URL');
  static const String superappProfilePath =
      String.fromEnvironment('SUPERAPP_PROFILE_PATH');
  static const String superappDebug = String.fromEnvironment('SUPERAPP_DEBUG');
  static const String cbebirrPlusCompanyName =
      String.fromEnvironment('CBEBIRR_PLUS_COMPANY_NAME');
  static const String cbebirrPlusKey =
      String.fromEnvironment('CBEBIRR_PLUS_KEY');
  static const String cbeGatewayBaseUrl =
      String.fromEnvironment('CBE_GATEWAY_BASE_URL');
  static const String telebirrGatewayAuthTokenUrl =
      String.fromEnvironment('TELEBIRR_GATEWAY_AUTH_TOKEN_URL');
  static const String cbebirrPlusAutoLoginUrl =
      String.fromEnvironment('CBEBIRR_PLUS_AUTO_LOGIN_URL');

  static String get(String key) {
    switch (key) {
      case 'BASE_URL':
        return baseUrl;
      case 'MERCHANT_APP_ID':
        return merchantAppId;
      case 'SUPERAPP_TOKEN_EXCHANGE_PATH':
        return superappTokenExchangePath;
      case 'SUPERAPP_BASE_URL':
        return superappBaseUrl;
      case 'TELEBIRR_BASE_URL':
        return telebirrBaseUrl;
      case 'SUPERAPP_PROFILE_PATH':
        return superappProfilePath;
      case 'SUPERAPP_DEBUG':
        return superappDebug;
      case 'CBEBIRR_PLUS_COMPANY_NAME':
        return cbebirrPlusCompanyName;
      case 'CBEBIRR_PLUS_KEY':
        return cbebirrPlusKey;
      case 'CBE_GATEWAY_BASE_URL':
        return cbeGatewayBaseUrl;
      case 'TELEBIRR_GATEWAY_AUTH_TOKEN_URL':
        return telebirrGatewayAuthTokenUrl;
      case 'CBEBIRR_PLUS_AUTO_LOGIN_URL':
        return cbebirrPlusAutoLoginUrl;
      default:
        return '';
    }
  }
}
