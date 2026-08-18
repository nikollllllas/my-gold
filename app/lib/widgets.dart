import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'api.dart';
import 'providers.dart';
import 'theme.dart';

final brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class PriceTag extends StatelessWidget {
  final double value;
  final bool positive;
  final TextStyle? style;
  const PriceTag({super.key, required this.value, required this.positive, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      brl.format(value),
      style: (style ?? Theme.of(context).textTheme.bodyMedium!)
          .copyWith(color: positive ? AppColors.upGreen : AppColors.downRed),
    );
  }
}

class GoldPriceCard extends StatelessWidget {
  final GoldPrice price;
  const GoldPriceCard({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    final up = price.changeBrl >= 0;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ouro · BRL/g', style: text.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(brl.format(price.priceBrl),
                style: text.headlineLarge?.copyWith(color: AppColors.goldPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16, color: up ? AppColors.upGreen : AppColors.downRed),
              const SizedBox(width: AppSpacing.xs),
              PriceTag(value: price.changeBrl.abs(), positive: up),
              const SizedBox(width: AppSpacing.sm),
              Text('(${price.changePct.toStringAsFixed(2)}%)',
                  style: text.bodySmall
                      ?.copyWith(color: up ? AppColors.upGreen : AppColors.downRed)),
            ]),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RangeItem(label: 'Mínima', value: price.lowBrl),
                _RangeItem(label: 'Máxima', value: price.highBrl),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeItem extends StatelessWidget {
  final String label;
  final double value;
  const _RangeItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: text.labelMedium),
      Text(brl.format(value), style: text.bodyMedium),
    ]);
  }
}

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});
  static const _periods = {'1d': '1D', '7d': '7D', '30d': '30D', '120d': '120D', '1y': '1A'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPeriodProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _periods.entries.map((e) {
        final active = e.key == selected;
        return GestureDetector(
          onTap: () => ref.read(selectedPeriodProvider.notifier).state = e.key,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: active ? AppColors.goldPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: active ? AppColors.background : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PremiumGate extends ConsumerWidget {
  final Widget child;
  const PremiumGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isPremiumProvider)) return child;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.goldPrimary),
            const SizedBox(height: AppSpacing.md),
            Text('Recurso Premium', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Assine para desbloquear alertas, calculadora e análise técnica.',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            GoldButton(
              label: 'Assinar por R\$14,90/mês',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Acesse a aba Conta para assinar o Premium')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const GoldButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: AppColors.background,
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class GoldTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  const GoldTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    // Visual vem do inputDecorationTheme do ThemeData
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error is ApiException ? error.toString() : 'Algo deu errado',
            style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
      ]),
    );
  }
}
