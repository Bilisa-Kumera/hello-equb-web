import 'package:helloequb/core/network/dio_factory.dart';
import 'package:helloequb/core/network/dio_debug_interceptor.dart';
import 'package:helloequb/core/network/dio_error_formatter.dart';
import 'package:helloequb/core/storage/secure_token_storage.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/features/superapp_auth/data/datasources/superapp_auth_remote_data_source.dart';
import 'package:helloequb/features/superapp_auth/data/datasources/superapp_js_data_source.dart';
import 'package:helloequb/features/superapp_auth/data/datasources/telebirr_gateway_js_exchange.dart';
import 'package:helloequb/features/superapp_auth/domain/entities/session.dart';
import 'package:helloequb/features/superapp_auth/domain/repositories/superapp_auth_repository.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/secure_storage.dart';

class SuperAppAuthRepositoryImpl implements SuperAppAuthRepository {
  SuperAppAuthRepositoryImpl({
    required String apiBaseUrl,
    required String tokenExchangePath,
    required String profilePath,
    required String telebirrGatewayAuthTokenUrl,
    String cbeBirrPlusAutoLoginUrl = '',
    SuperAppJsDataSource? jsDataSource,
    SecureTokenStorage? tokenStorage,
    DioFactory? dioFactory,
    DataController? dataController,
  })  : _jsDataSource = jsDataSource ?? SuperAppJsDataSource(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _dioFactory = dioFactory ?? DioFactory(),
        _dataController = dataController ?? DataController(),
        _apiBaseUrl = apiBaseUrl,
        _tokenExchangePath = tokenExchangePath,
        _profilePath = profilePath,
        _telebirrGatewayAuthTokenUrl = telebirrGatewayAuthTokenUrl,
        _cbeBirrPlusAutoLoginUrl = cbeBirrPlusAutoLoginUrl;

  final SuperAppJsDataSource _jsDataSource;
  final SecureTokenStorage _tokenStorage;
  final DioFactory _dioFactory;
  final DataController _dataController;

  final String _apiBaseUrl;
  final String _tokenExchangePath;
  final String _profilePath;
  final String _telebirrGatewayAuthTokenUrl;
  final String _cbeBirrPlusAutoLoginUrl;

  @override
  bool get isSuperAppAvailable => _jsDataSource.isAvailable;

  @override
  Future<String> getMiniAppToken({required String merchantAppId}) {
    AppLogger.log(
      'requesting SuperApp mini app token (merchantAppId=$merchantAppId)',
    );
    return _jsDataSource.getMiniAppToken(merchantAppId: merchantAppId);
  }

  @override
  Future<Map<String, dynamic>> exchangeAppTokenWithTelebirrGateway({
    required String appToken,
  }) async {
    AppLogger.log(
      'exchanging app token with Telebirr gateway url=$_telebirrGatewayAuthTokenUrl tokenLen=${appToken.length}',
    );

    final remote = SuperAppAuthRemoteDataSource(
      dio: _dioFactory.createPlainDio(baseUrl: ''),
      tokenExchangePath: _tokenExchangePath,
      profilePath: _profilePath,
    );

    Map<String, dynamic>? payload;

    try {
      payload = await exchangeTelebirrAuthTokenViaJs(
        gatewayUrl: _telebirrGatewayAuthTokenUrl,
        authToken: appToken,
      );
      if (payload != null) {
        AppLogger.success('Telebirr gateway auth/token via JS fetch');
      }
    } catch (e) {
      AppLogger.warn('Telebirr gateway JS fetch failed: $e');
    }

    if (payload == null) {
      AppLogger.log('falling back to Dio for Telebirr gateway auth/token');
      final dio = _dioFactory.createPlainDio(baseUrl: '');
      if (AppLogger.enabled) {
        dio.interceptors.add(DioDebugInterceptor(tag: 'TelebirrGateway'));
      }
      final dioRemote = SuperAppAuthRemoteDataSource(
        dio: dio,
        tokenExchangePath: _tokenExchangePath,
        profilePath: _profilePath,
      );
      try {
        payload = await dioRemote.exchangeTelebirrAuthToken(
          gatewayUrl: _telebirrGatewayAuthTokenUrl,
          authToken: appToken,
        );
        AppLogger.success('Telebirr gateway auth/token via Dio');
      } catch (e) {
        AppLogger.error(
          'Telebirr gateway Dio error: ${formatTelebirrGatewayError(e, gatewayUrl: _telebirrGatewayAuthTokenUrl)}',
        );
        rethrow;
      }
    }

    final user = remote.userFromLoginPayload(payload);
    final openId = user?['open_id'] ?? user?['openId'];
    final identityId = user?['identityId'];
    AppLogger.log('Telebirr user openId=$openId identityId=$identityId');

    return <String, dynamic>{
      'gatewayPayload': payload,
      if (openId != null) 'openId': openId,
      if (identityId != null) 'identityId': identityId,
      if (user != null) 'user': user,
    };
  }

  @override
  Future<Session> loginWithMiniAppToken({
    required String appToken,
    required String phoneNumber,
  }) async {
    AppLogger.log(
      'starting SuperApp backend login base=$_apiBaseUrl path=$_tokenExchangePath phone=$phoneNumber tokenLen=${appToken.length}',
    );

    final dio = _dioFactory.createPlainDio(baseUrl: _apiBaseUrl);
    if (AppLogger.enabled) {
      dio.interceptors.add(DioDebugInterceptor(tag: 'SuperAppAuth'));
    }
    final remote = SuperAppAuthRemoteDataSource(
      dio: dio,
      tokenExchangePath: _tokenExchangePath,
      profilePath: _profilePath,
    );

    final payload = await remote.loginForMiniApp(
      phoneNumber: phoneNumber,
      appToken: appToken,
    );
    AppLogger.success('SuperApp backend login response received');
    return _persistSessionFromPayload(remote, payload,
        phoneNumber: phoneNumber);
  }

  /// POSTs `{"token": appToken}` to the Telebirr auto-login endpoint and
  /// persists the returned session. This is the single-step auto-login path.
  ///
  /// [onResponse] is called with the raw response payload before session
  /// persistence, allowing callers to display debug info without changing the
  /// return type.
  Future<Session> autoLoginTelebirrMiniApp({
    required String appToken,
    void Function(String url, Map<String, dynamic> requestBody,
            Map<String, dynamic> responsePayload)?
        onResponse,
  }) async {
    AppLogger.log(
      'Telebirr auto-login → $_telebirrGatewayAuthTokenUrl (tokenLen=${appToken.length})',
    );

    final dio = _dioFactory.createPlainDio(baseUrl: _apiBaseUrl);
    if (AppLogger.enabled) {
      dio.interceptors.add(DioDebugInterceptor(tag: 'TelebirrAutoLogin'));
    }
    final remote = SuperAppAuthRemoteDataSource(
      dio: dio,
      tokenExchangePath: _tokenExchangePath,
      profilePath: _profilePath,
    );

    final requestBody = <String, dynamic>{'token': appToken};
    final payload = await remote.autoLoginMiniApp(
      url: _telebirrGatewayAuthTokenUrl,
      token: appToken,
    );
    AppLogger.success('Telebirr auto-login response received');
    onResponse?.call(_telebirrGatewayAuthTokenUrl, requestBody, payload);
    final session = await _persistSessionFromPayload(remote, payload);
    _dataController.storeData('isFromTelebirrMiniApp', true);
    _dataController.storeData('isCbeBirr', false);
    return session;
  }

  /// POSTs `{"token": launchToken}` to the CBEBirr Plus auto-login endpoint.
  Future<Session> autoLoginCbeBirrPlusMiniApp(
      {required String launchToken}) async {
    final url = _cbeBirrPlusAutoLoginUrl.isNotEmpty
        ? _cbeBirrPlusAutoLoginUrl
        : '$_apiBaseUrl/user/auth/auto-login-cbebirr-miniapp';
    AppLogger.log(
      'CBEBirr Plus auto-login → $url (tokenLen=${launchToken.length})',
    );

    final dio = _dioFactory.createPlainDio(baseUrl: _apiBaseUrl);
    if (AppLogger.enabled) {
      dio.interceptors.add(DioDebugInterceptor(tag: 'CbeBirrAutoLogin'));
    }
    final remote = SuperAppAuthRemoteDataSource(
      dio: dio,
      tokenExchangePath: _tokenExchangePath,
      profilePath: _profilePath,
    );

    final payload = await remote.autoLoginMiniApp(
      url: url,
      token: launchToken,
    );
    AppLogger.success('CBEBirr Plus auto-login response received');
    final session = await _persistSessionFromPayload(
      remote,
      payload,
      persistCbeBirrPhone: true,
    );
    _dataController.storeData('isFromTelebirrMiniApp', false);
    _dataController.storeData('isCbeBirr', true);
    return session;
  }

  Future<Session> _persistSessionFromPayload(
    SuperAppAuthRemoteDataSource remote,
    Map<String, dynamic> payload, {
    String? phoneNumber,
    bool persistCbeBirrPhone = false,
  }) async {
    final session = remote.sessionFromLoginPayload(payload);
    AppLogger.log(
      'session parsed; accessTokenLen=${session.accessToken.length} refreshToken=${session.refreshToken == null ? 'absent' : 'present'}',
    );

    await _tokenStorage.writeAccessToken(session.accessToken);
    await SecureStorageHelper.saveAccessToken(session.accessToken);
    _dataController.storeData('accessToken', session.accessToken);
    if (session.refreshToken != null) {
      await SecureStorageHelper.saveRefreshToken(session.refreshToken!);
      _dataController.storeData('refreshToken', session.refreshToken);
    }
    _dataController.storeData('isLoggedIn', true);

    String? persistedPhoneNumber;
    final user = remote.userFromLoginPayload(payload);
    if (user != null) {
      persistedPhoneNumber = _persistUserIdentity(user);
    } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
      _dataController.storeData('phoneNumber', phoneNumber);
      persistedPhoneNumber = phoneNumber;
    }
    final payloadPhoneNumber = _phoneNumberFromPayload(payload);
    if (payloadPhoneNumber != null && payloadPhoneNumber.isNotEmpty) {
      _dataController.storeData('phoneNumber', payloadPhoneNumber);
      persistedPhoneNumber = payloadPhoneNumber;
    }

    try {
      final authedDio = _dioFactory.createAuthedDio(baseUrl: _apiBaseUrl);
      if (AppLogger.enabled) {
        authedDio.interceptors.add(DioDebugInterceptor(tag: 'SuperAppProfile'));
      }
      final authedRemote = SuperAppAuthRemoteDataSource(
        dio: authedDio,
        tokenExchangePath: _tokenExchangePath,
        profilePath: _profilePath,
      );
      final profile = await authedRemote.fetchProfile();
      _dataController.storeData('profile', profile);
      persistedPhoneNumber =
          _persistProfileIdentity(profile) ?? persistedPhoneNumber;
      AppLogger.log('profile fetched and cached');
    } catch (e) {
      AppLogger.warn('profile fetch skipped/failed after login: $e');
    }

    if (persistCbeBirrPhone &&
        persistedPhoneNumber != null &&
        persistedPhoneNumber.trim().isNotEmpty) {
      _dataController.storeData('cbeBirrPlusPhone', persistedPhoneNumber);
    }

    return session;
  }

  String? _persistUserIdentity(Map<String, dynamic> user) {
    _storeIfPresent(
        'userId', _stringAt(user, ['id', '_id', 'userId', 'userID']));
    _storeIfPresent('open_id', _stringAt(user, ['open_id', 'openId']));
    _storeIfPresent(
        'identityId', _stringAt(user, ['identityId', 'identity_id']));
    _storeIfPresent('firstName', _stringAt(user, ['firstName', 'first_name']));
    _storeIfPresent(
        'middleName', _stringAt(user, ['middleName', 'middle_name']));
    _storeIfPresent('lastName', _stringAt(user, ['lastName', 'last_name']));
    _storeIfPresent('email', _stringAt(user, ['email']));
    final phoneNumber =
        _stringAt(user, ['phoneNumber', 'phone', 'mobile', 'identifier']);
    _storeIfPresent('phoneNumber', phoneNumber);

    final fullName = _stringAt(user, ['fullName', 'name']) ??
        _joinNameParts(
          _stringAt(user, ['firstName', 'first_name']),
          _stringAt(user, ['middleName', 'middle_name']),
          _stringAt(user, ['lastName', 'last_name']),
        );
    _storeIfPresent('fullName', fullName);
    return phoneNumber;
  }

  String? _persistProfileIdentity(Map<String, dynamic> profile) {
    final user = _mapAt(profile, [
      'user',
      'data.user',
      'data.profile.user',
      'profile.user',
    ]);

    if (user != null) {
      return _persistUserIdentity(user);
    }

    final flatProfile =
        _mapAt(profile, ['data.profile', 'profile', 'data']) ?? profile;
    return _persistUserIdentity(flatProfile);
  }

  Map<String, dynamic>? _mapAt(
      Map<String, dynamic> payload, List<String> paths) {
    for (final path in paths) {
      dynamic current = payload;
      for (final part in path.split('.')) {
        if (current is Map) {
          current = current[part];
        } else {
          current = null;
          break;
        }
      }
      if (current is Map<String, dynamic>) return current;
      if (current is Map) return Map<String, dynamic>.from(current);
    }
    return null;
  }

  String? _stringAt(Map<String, dynamic> payload, List<String> paths) {
    for (final path in paths) {
      dynamic current = payload;
      for (final part in path.split('.')) {
        if (current is Map) {
          current = current[part];
        } else {
          current = null;
          break;
        }
      }
      final value = current?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }

  String? _joinNameParts(
      String? firstName, String? middleName, String? lastName) {
    final parts = [firstName, middleName, lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  void _storeIfPresent(String key, String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == 'null') return;
    _dataController.storeData(key, trimmed);
  }

  String? _phoneNumberFromPayload(Map<String, dynamic> payload) {
    String? stringAt(List<String> paths) {
      for (final path in paths) {
        dynamic current = payload;
        for (final part in path.split('.')) {
          if (current is Map) {
            current = current[part];
          } else {
            current = null;
            break;
          }
        }
        final value = current?.toString().trim();
        if (value != null && value.isNotEmpty && value != 'null') {
          return value;
        }
      }
      return null;
    }

    final directPhone = stringAt([
      'phoneNumber',
      'phone',
      'identifier',
      'data.phoneNumber',
      'data.phone',
      'data.identifier',
      'user.phoneNumber',
      'data.user.phoneNumber',
    ]);
    if (directPhone != null) return directPhone;

    final authRes = stringAt(['authRes', 'data.authRes']);
    if (authRes == null) return null;

    final match = RegExp(r'identifier:\s*([^,}]+)').firstMatch(authRes);
    final phone = match?.group(1)?.trim();
    if (phone == null || phone.isEmpty || phone == 'null') return null;
    return phone.startsWith('+') ? phone : '+$phone';
  }
}
