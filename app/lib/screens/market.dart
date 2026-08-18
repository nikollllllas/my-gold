import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chart.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'alerts.dart';

/// Mercado: gráfico ampliado + análise técnica (SMA 9/21 + RSI 14, premium).
class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Alertas de preço',
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const PeriodSelector(),
          const SizedBox(height: AppSpacing.md),
          history.when(
            data: (points) => GoldChart(points: points, showIndicators: isPremium),
            loading: () =>
                const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SizedBox(
              height: 220,
              child: ErrorRetry(error: e, onRetry: () => ref.invalidate(historyProvider)),
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: AppSpacing.lg),
            const Card(
              child: PremiumGate(child: SizedBox.shrink()),
            ),
          ],
        ],
      ),
    );
  }
}
