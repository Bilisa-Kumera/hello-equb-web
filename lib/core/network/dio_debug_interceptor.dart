import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:helloequb/core/logging/app_logger.dart';

class DioDebugInterceptor extends Interceptor {
  DioDebugInterceptor({this.tag = 'Dio'});

  final String tag;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.log(
      '$tag → ${options.method} ${options.baseUrl}${options.path}',
    );
    if (options.queryParameters.isNotEmpty) {
      AppLogger.log('$tag query: ${_safeJson(options.queryParameters)}');
    }
    if (options.headers.isNotEmpty) {
      AppLogger.log('$tag headers: ${_safeJson(_redactHeaders(options.headers))}');
    }
    if (options.data != null) {
      AppLogger.log('$tag body: ${_safeJson(_redactBody(options.data))}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.log(
      '$tag ← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.baseUrl}${response.requestOptions.path}',
    );
    AppLogger.log('$tag resp: ${_safeJson(_redactBody(response.data))}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final ro = err.requestOptions;
    AppLogger.error(
      '$tag !! ${err.type} ${ro.method} ${ro.baseUrl}${ro.path} status=${err.response?.statusCode} msg=${err.message}',
    );
    if (err.response?.data != null) {
      AppLogger.error('$tag errBody: ${_safeJson(_redactBody(err.response?.data))}');
    }
    handler.next(err);
  }

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    final out = <String, dynamic>{};
    headers.forEach((k, v) {
      final key = k.toString().toLowerCase();
      if (key == 'authorization' || key == 'cookie') {
        out[k.toString()] = '***';
      } else {
        out[k.toString()] = v;
      }
    });
    return out;
  }

  dynamic _redactBody(dynamic data) {
    if (data is Map) {
      final out = <String, dynamic>{};
      data.forEach((k, v) {
        final key = k.toString().toLowerCase();
        if (key.contains('token') || key.contains('password')) {
          out[k.toString()] = '***';
        } else {
          out[k.toString()] = _redactBody(v);
        }
      });
      return out;
    }
    if (data is List) {
      return data.map(_redactBody).toList();
    }
    return data;
  }

  String _safeJson(dynamic value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      try {
        return value.toString();
      } catch (_) {
        return '<unprintable>';
      }
    }
  }
}

