import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');

class GoldPrice {
  final double priceBrl, changeBrl, changePct, lowBrl, highBrl;
  final DateTime fetchedAt;
  GoldPrice.fromJson(Map<String, dynamic> j)
      : priceBrl = (j['priceBrl'] as num).toDouble(),
        changeBrl = (j['changeBrl'] as num).toDouble(),
        changePct = (j['changePct'] as num).toDouble(),
        lowBrl = (j['lowBrl'] as num).toDouble(),
        highBrl = (j['highBrl'] as num).toDouble(),
        fetchedAt = DateTime.parse(j['fetchedAt'] as String);
}

class HistoryPoint {
  final double priceBrl;
  final DateTime recordedAt;
  HistoryPoint.fromJson(Map<String, dynamic> j)
      : priceBrl = (j['priceBrl'] as num).toDouble(),
        recordedAt = DateTime.parse(j['recordedAt'] as String);
}

class PriceAlert {
  final int id;
  final double targetPrice;
  final String direction;
  final bool triggered;
  PriceAlert.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        targetPrice = double.parse(j['targetPrice'].toString()),
        direction = j['direction'] as String,
        triggered = j['triggered'] as bool;
}

class User {
  final int id;
  final String email;
  final bool isPremium;
  User.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        email = j['email'] as String,
        isPremium = j['isPremium'] as bool;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  final Dio _dio;
  String? _token;

  Api()
      : _dio = Dio(BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) options.headers['authorization'] = 'Bearer $_token';
        handler.next(options);
      },
    ));
  }

  bool get isLoggedIn => _token != null;

  Future<void> loadToken() async {
    // ponytail: shared_preferences; migrar p/ flutter_secure_storage antes de produção
    _token = (await SharedPreferences.getInstance()).getString('token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    await (await SharedPreferences.getInstance()).setString('token', token);
  }

  Future<void> logout() async {
    _token = null;
    await (await SharedPreferences.getInstance()).remove('token');
  }

  Never _throw(DioException e) {
    final msg = e.response?.data is Map ? e.response!.data['error'] as String? : null;
    throw ApiException(msg ?? 'Falha de conexão. Verifique sua internet.');
  }

  Future<GoldPrice> goldPrice() async {
    try {
      return GoldPrice.fromJson((await _dio.get('/prices/gold')).data);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<List<HistoryPoint>> history(String period) async {
    try {
      final data = (await _dio.get('/history', queryParameters: {'period': period})).data as List;
      return data.map((j) => HistoryPoint.fromJson(j)).toList();
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<void> register(String email, String password) async {
    try {
      final r = await _dio.post('/auth/register', data: {'email': email, 'password': password});
      await _saveToken(r.data['token'] as String);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final r = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      await _saveToken(r.data['token'] as String);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<User> me() async {
    try {
      return User.fromJson((await _dio.get('/auth/me')).data);
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<List<PriceAlert>> alerts() async {
    try {
      final data = (await _dio.get('/alerts')).data as List;
      return data.map((j) => PriceAlert.fromJson(j)).toList();
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<void> createAlert(double targetPrice, String direction) async {
    try {
      await _dio.post('/alerts', data: {'targetPrice': targetPrice, 'direction': direction});
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<void> deleteAlert(int id) async {
    try {
      await _dio.delete('/alerts/$id');
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<String> checkoutUrl(String plan) async {
    try {
      final r = await _dio.post('/subscriptions/checkout', data: {'plan': plan});
      return r.data['url'] as String;
    } on DioException catch (e) {
      _throw(e);
    }
  }

  Future<void> sendFcmToken(String token) async {
    try {
      await _dio.patch('/account/fcm-token', data: {'fcmToken': token});
    } on DioException catch (e) {
      _throw(e);
    }
  }
}
