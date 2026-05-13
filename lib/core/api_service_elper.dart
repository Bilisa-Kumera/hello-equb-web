import 'package:dio/dio.dart';
import 'package:ekubee/core/api_url.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<void> create(String endpoint, Map<String, dynamic> data,
      {String? bearerToken}) async {
    final String url = '$baseUrl/$endpoint';
    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );
    } catch (error) {}
  }

  Future<dynamic> readAll(String endpoint, {String? bearerToken}) async {
    final String url = endpoint;
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        return null;
      }
    } on DioError catch (error) {
      if (error.response != null ||
          error.response != '' &&
              error.response!.data['msg'] == 'Token is not valid') {
        return 'Token is not valid';
     
      }
    
    } catch (error) {
      return null;
    }
  }

  Future<void> read(String endpoint, String id, {String? bearerToken}) async {
    final String url = '$baseUrl/$endpoint/$id';
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );
    } catch (error) {}
  }

  Future<void> update(String endpoint, String id, Map<String, dynamic> data,
      {String? bearerToken}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );
    } on DioError catch (error) {
      if (error.response != null) {
        if (error.response!.statusCode == 400) {
          // Handle specific actions for 400 error, e.g., notify user or retry with corrected data
        }
      }
    } catch (error) {}
  }

  Future<void> delete(String endpoint, String id, {String? bearerToken}) async {
    final String url = '$baseUrl/$endpoint/$id';
    try {
      final response = await _dio.delete(
        url,
        options: Options(
          headers: {
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );
    } catch (error) {}
  }
}
