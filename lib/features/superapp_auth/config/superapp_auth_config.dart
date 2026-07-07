import 'package:flutter_dotenv/flutter_dotenv.dart';

class SuperAppAuthConfig {
  const SuperAppAuthConfig({
    required this.merchantAppId,
    this.apiBaseUrlOverride,
    required this.tokenExchangePath,
    required this.profilePath,
    required this.telebirrGatewayAuthTokenUrl,
    required this.cbeBirrPlusAutoLoginUrl,
  });

  final String merchantAppId;
  final String? apiBaseUrlOverride;
  final String tokenExchangePath;
  final String profilePath;

  /// Posts `{"token": ...}` to complete Telebirr mini-app auto-login.
  final String telebirrGatewayAuthTokenUrl;

  /// Posts `{"token": ...}` to complete CBEBirr Plus mini-app auto-login.
  final String cbeBirrPlusAutoLoginUrl;

  static SuperAppAuthConfig fromEnv() {
    final merchantAppId =
        (dotenv.env['MERCHANT_APP_ID'] ?? '')
            .trim();

    String? normalizeBaseUrlOverride(String raw) {
      final v = raw.trim();
      if (v.isEmpty) return null;
      if (v.startsWith('http://') || v.startsWith('https://')) {
        return v.endsWith('/') ? v : '$v/';
      }
      // Non-absolute values are kept as-is for advanced setups.
      return v;
    }

    final apiBaseUrlOverride = normalizeBaseUrlOverride(
      dotenv.env['SUPERAPP_BASE_URL'] ?? dotenv.env['TELEBIRR_BASE_URL'] ?? '',
    );

    // These are paths relative to the API base URL (which in this project is
    // typically `${BASE_URL}/api/v1`). You can override them in `.env`.
    //
    // If your backend expects root paths like `/auth/token`, set
    // `SUPERAPP_TOKEN_EXCHANGE_PATH=/auth/token`.
    String normalizePath(String raw) {
      final v = raw.trim();
      if (v.isEmpty) return v;
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
      return v.startsWith('/') ? v.substring(1) : v;
    }

    final tokenExchangePath = normalizePath(
      dotenv.env['SUPERAPP_TOKEN_EXCHANGE_PATH'] ??
          'user/auth/login-for-miniapp',
    );
    final profilePath = normalizePath(
      dotenv.env['SUPERAPP_PROFILE_PATH'] ?? 'user/profile/me',
    );

    const defaultTelebirrAutoLoginUrl =
        'https://api.hello-equb.com/api/v1/user/auth/auto-login-telebirr-miniapp';
    final telebirrRaw =
        (dotenv.env['TELEBIRR_GATEWAY_AUTH_TOKEN_URL'] ?? '').trim();
    final telebirrGatewayAuthTokenUrl = telebirrRaw.isNotEmpty
        ? telebirrRaw
        : defaultTelebirrAutoLoginUrl;

    const defaultCbeBirrPlusAutoLoginUrl =
        'https://api.hello-equb.com/api/v1/user/auth/auto-login-cbebirr-miniapp';
    final cbeRaw =
        (dotenv.env['CBEBIRR_PLUS_AUTO_LOGIN_URL'] ?? '').trim();
    final cbeBirrPlusAutoLoginUrl = cbeRaw.isNotEmpty
        ? cbeRaw
        : defaultCbeBirrPlusAutoLoginUrl;

    return SuperAppAuthConfig(
      merchantAppId: merchantAppId,
      apiBaseUrlOverride: apiBaseUrlOverride,
      tokenExchangePath: tokenExchangePath,
      profilePath: profilePath,
      telebirrGatewayAuthTokenUrl: telebirrGatewayAuthTokenUrl,
      cbeBirrPlusAutoLoginUrl: cbeBirrPlusAutoLoginUrl,
    );
  }
}
