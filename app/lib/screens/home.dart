import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../chart.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // ponytail: "mercado aberto" = seg-sex, aproximação sem feriados;
  // trocar por calendário de mercado se precisar de precisão.
  bool get _marketOpen {
    final now = DateTime.now();
    return now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = ref.watch(goldPriceProvider);
    final history = ref.watch(historyProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(goldPriceProvider);
            ref.invalidate(historyProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat("d 'de' MMMM, HH:mm", 'pt_BR').format(DateTime.now()),
                      style: text.bodySmall),
                  Row(children: [
                    Icon(Icons.circle,
                        size: 10, color: _marketOpen ? AppColors.upGreen : AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(_marketOpen ? 'Mercado aberto' : 'Mercado fechado', style: text.bodySmall),
                  ]),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              price.when(
                data: (p) => GoldPriceCard(price: p),
                loading: () => const SizedBox(
                    height: 180, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SizedBox(
                  height: 180,
                  child: ErrorRetry(error: e, onRetry: () => ref.invalidate(goldPriceProvider)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const PeriodSelector(),
              const SizedBox(height: AppSpacing.md),
              history.when(
                data: (points) => GoldChart(points: points),
                loading: () => const SizedBox(
                    height: 220, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SizedBox(
                  height: 220,
                  child: ErrorRetry(error: e, onRetry: () => ref.invalidate(historyProvider)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
