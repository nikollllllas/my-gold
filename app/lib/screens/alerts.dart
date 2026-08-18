import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas de preço')),
      body: PremiumGate(
        child: alerts.when(
          data: (list) => list.isEmpty
              ? Center(
                  child: Text('Nenhum alerta configurado',
                      style: Theme.of(context).textTheme.bodySmall))
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    final above = a.direction == 'above';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          above ? Icons.trending_up : Icons.trending_down,
                          color: above ? AppColors.upGreen : AppColors.downRed,
                        ),
                        title: Text('${above ? 'Acima de' : 'Abaixo de'} ${brl.format(a.targetPrice)}'),
                        subtitle: Text(a.triggered ? 'Disparado' : 'Ativo',
                            style: Theme.of(context).textTheme.bodySmall),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                          onPressed: () async {
                            try {
                              await ref.read(apiProvider).deleteAlert(a.id);
                              ref.invalidate(alertsProvider);
                            } on ApiException catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(e.toString())));
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(alertsProvider)),
        ),
      ),
      floatingActionButton: ref.watch(isPremiumProvider)
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final priceController = TextEditingController();
    var direction = 'above';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Novo alerta', style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            GoldTextField(
              controller: priceController,
              label: 'Preço alvo (R\$/g)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'above', label: Text('Acima'), icon: Icon(Icons.trending_up)),
                ButtonSegment(value: 'below', label: Text('Abaixo'), icon: Icon(Icons.trending_down)),
              ],
              selected: {direction},
              onSelectionChanged: (s) => setState(() => direction = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            GoldButton(
              label: 'Criar alerta',
              onPressed: () async {
                final price = double.tryParse(priceController.text.replaceAll(',', '.'));
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('Informe um preço alvo válido')));
                  return;
                }
                try {
                  await ref.read(apiProvider).createAlert(price, direction);
                  ref.invalidate(alertsProvider);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                } on ApiException catch (e) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
            ),
          ]),
        ),
      ),
    );
  }
}
