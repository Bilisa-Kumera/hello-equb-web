import 'package:helloequb/core/network/dio_factory.dart';
import 'package:helloequb/core/network/dio_debug_interceptor.dart';
import 'package:helloequb/core/storage/secure_token_storage.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/features/superapp_auth/data/datasources/superapp_auth_remote_data_source.dart';
import 'package:helloequb/features/superapp_auth/data/datasources/superapp_js_data_source.dart';
import 'package:helloequb/features/superapp_auth/domain/entities/session.dart';
import 'package:helloequb/features/superapp_auth/domain/repositories/superapp_auth_repository.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

class SuperAppAuthRepositoryImpl implements SuperAppAuthRepository {
  SuperAppAuthRepositoryImpl({
    required String apiBaseUrl,
    required String tokenExchangePath,
    required String profilePath,
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
        _profilePath = profilePath;

  final SuperAppJsDataSource _jsDataSource;
  final SecureTokenStorage _tokenStorage;
  final DioFactory _dioFactory;
  final DataController _dataController;

  final String _apiBaseUrl;
  final String _tokenExchangePath;
  final String _profilePath;

  @override
  bool get isSuperAppAvailable => _jsDataSource.isAvailable;

  @override
  Future<Session> loginWithSuperApp({required String merchantAppId}) async {
    AppLogger.log('starting SuperApp login flow');
    final miniAppToken =
        await _jsDataSource.getMiniAppToken(merchantAppId: merchantAppId);
    AppLogger.log('token received; exchanging with backend');

    final dio = _dioFactory.createPlainDio(baseUrl: _apiBaseUrl);
    if (AppLogger.enabled) {
      dio.interceptors.add(DioDebugInterceptor(tag: 'SuperAppAuth'));
    }
    final remote = SuperAppAuthRemoteDataSource(
      dio: dio,
      tokenExchangePath: _tokenExchangePath,
      profilePath: _profilePath,
    );

    final session = await remote.exchangeToken(authToken: miniAppToken);
    AppLogger.log('exchange success; session token stored');

    // Persist token for the rest of the app.
    await _tokenStorage.writeAccessToken(session.accessToken);
    _dataController.storeData('accessToken', session.accessToken);
    _dataController.storeData('isLoggedIn', true);

    // Fetch profile (best-effort; don't fail login if profile request fails).
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
      AppLogger.log('profile fetched and cached');
    } catch (_) {}

    return session;
  }
}
