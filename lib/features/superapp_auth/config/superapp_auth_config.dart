import 'package:helloequb/core/env_config.dart';

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
    final merchantAppId = EnvConfig.merchantAppId.trim();

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
      EnvConfig.superappBaseUrl.isNotEmpty
          ? EnvConfig.superappBaseUrl
          : EnvConfig.telebirrBaseUrl,
    );

    // These are paths relative to the API base URL (which in this project is
    // typically `${BASE_URL}/api/v1`). Override via --dart-define.
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
      EnvConfig.superappTokenExchangePath.isNotEmpty
          ? EnvConfig.superappTokenExchangePath
          : 'user/auth/login-for-miniapp',
    );
    final profilePath = normalizePath(
      EnvConfig.superappProfilePath.isNotEmpty
          ? EnvConfig.superappProfilePath
          : 'user/profile/me',
    );

    const defaultTelebirrAutoLoginUrl =
        'https://api.hello-equb.com/api/v1/user/auth/auto-login-telebirr-miniapp';
    final telebirrRaw = EnvConfig.telebirrGatewayAuthTokenUrl.trim();
    final telebirrGatewayAuthTokenUrl = telebirrRaw.isNotEmpty
        ? telebirrRaw
        : defaultTelebirrAutoLoginUrl;

    const defaultCbeBirrPlusAutoLoginUrl =
        'https://api.hello-equb.com/api/v1/user/auth/auto-login-cbebirr-miniapp';
    final cbeRaw = EnvConfig.cbebirrPlusAutoLoginUrl.trim();
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
