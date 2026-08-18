import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets.dart';

const _gramsPerOunce = 31.1034768;

/// Calculadora de investimento (premium): quantidade + data de compra →
/// valor atual, variação e rentabilidade %.
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _amount = TextEditingController();
  final _buyPrice = TextEditingController();
  bool _inOunces = false;
  DateTime? _buyDate;
  ({double current, double change, double pct})? _result;
  String? _error;

  void _calculate() {
    final amountRaw = double.tryParse(_amount.text.replaceAll(',', '.'));
    final buyPrice = double.tryParse(_buyPrice.text.replaceAll(',', '.'));
    final currentPrice = ref.read(goldPriceProvider).valueOrNull?.priceBrl;

    setState(() {
      _error = null;
      _result = null;
      if (amountRaw == null || amountRaw <= 0) {
        _error = 'Informe uma quantidade válida';
      } else if (buyPrice == null || buyPrice <= 0) {
        _error = 'Informe o preço pago por grama na compra';
      } else if (currentPrice == null) {
        _error = 'Preço atual indisponível, tente novamente';
      } else {
        final grams = _inOunces ? amountRaw * _gramsPerOunce : amountRaw;
        final invested = grams * buyPrice;
        final current = grams * currentPrice;
        _result = (current: current, change: current - invested, pct: (current / invested - 1) * 100);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora')),
      body: PremiumGate(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(children: [
              Expanded(
                child: GoldTextField(
                  controller: _amount,
                  label: _inOunces ? 'Quantidade (oz)' : 'Quantidade (g)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('g')),
                  ButtonSegment(value: true, label: Text('oz')),
                ],
                selected: {_inOunces},
                onSelectionChanged: (s) => setState(() => _inOunces = s.first),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            GoldTextField(
              controller: _buyPrice,
              label: 'Preço pago por grama (R\$)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(_buyDate == null
                  ? 'Data de compra (opcional)'
                  : '${_buyDate!.day.toString().padLeft(2, '0')}/${_buyDate!.month.toString().padLeft(2, '0')}/${_buyDate!.year}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _buyDate = picked);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            GoldButton(label: 'Calcular', onPressed: _calculate),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null)
              Text(_error!, style: text.bodyMedium?.copyWith(color: AppColors.downRed)),
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Valor atual', style: text.labelMedium),
                    Text(brl.format(_result!.current), style: text.headlineMedium),
                    const SizedBox(height: AppSpacing.md),
                    Text('Variação desde a compra', style: text.labelMedium),
                    Row(children: [
                      PriceTag(
                          value: _result!.change.abs(),
                          positive: _result!.change >= 0,
                          style: text.titleMedium),
                      const SizedBox(width: AppSpacing.sm),
                      Text('(${_result!.pct.toStringAsFixed(2)}%)',
                          style: text.bodySmall?.copyWith(
                              color: _result!.change >= 0 ? AppColors.upGreen : AppColors.downRed)),
                    ]),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ponytail: spec pedia "data de compra" como input do cálculo, mas o backend não
// tem preço histórico por data arbitrária ainda (histórico só 1 ano, horário).
// Uso preço pago informado pelo usuário; buscar preço pela data quando /history
// aceitar data pontual.
