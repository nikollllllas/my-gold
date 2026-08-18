import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api.dart';

final apiProvider = Provider<Api>((ref) => Api());

/// Preço atual, repolling a cada 60s.
final goldPriceProvider = StreamProvider<GoldPrice>((ref) async* {
  final api = ref.watch(apiProvider);
  yield await api.goldPrice();
  await for (final _ in Stream.periodic(const Duration(seconds: 60))) {
    yield await api.goldPrice();
  }
});

final selectedPeriodProvider = StateProvider<String>((ref) => '1d');

final historyProvider = FutureProvider<List<HistoryPoint>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(apiProvider).history(period);
});

/// Usuário logado, ou null (free/anônimo).
final userProvider = FutureProvider<User?>((ref) async {
  final api = ref.watch(apiProvider);
  await api.loadToken();
  if (!api.isLoggedIn) return null;
  try {
    final user = await api.me();
    _registerPushToken(api); // fire-and-forget: push é best-effort
    return user;
  } on ApiException {
    return null; // token expirado → volta a anônimo
  }
});

Future<void> _registerPushToken(Api api) async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) await api.sendFcmToken(token);
  } catch (_) {
    // Firebase não configurado (sem flutterfire configure) ou permissão negada
  }
}

final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(userProvider).valueOrNull?.isPremium ?? false,
);

final alertsProvider = FutureProvider<List<PriceAlert>>((ref) {
  return ref.watch(apiProvider).alerts();
});
