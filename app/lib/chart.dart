import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api.dart';
import 'indicators.dart';
import 'theme.dart';
import 'widgets.dart' show brl;

/// Wrapper do fl_chart com tema unificado. [showIndicators] sobrepõe SMA 9/21
/// e exibe painel de RSI 14 abaixo (premium).
class GoldChart extends StatelessWidget {
  final List<HistoryPoint> points;
  final bool showIndicators;
  const GoldChart({super.key, required this.points, this.showIndicators = false});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text('Sem dados para este período ainda',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    final prices = points.map((p) => p.priceBrl).toList();
    final spots = [for (var i = 0; i < prices.length; i++) FlSpot(i.toDouble(), prices[i])];

    List<FlSpot> smaSpots(int period) {
      final values = sma(prices, period);
      return [
        for (var i = 0; i < values.length; i++)
          if (values[i] != null) FlSpot(i.toDouble(), values[i]!)
      ];
    }

    final chart = SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                // ~4 labels espaçados, sempre incluindo o primeiro ponto
                interval: (points.length / 4).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('dd/MM').format(points[i].recordedAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItems: (touched) => touched
                  .map<LineTooltipItem?>((s) {
                    // Só a linha de preço (barra 0) — SMAs não precisam de tooltip
                    if (s.barIndex != 0) return null;
                    final i = s.x.toInt();
                    final date = i >= 0 && i < points.length
                        ? DateFormat('dd/MM/yyyy').format(points[i].recordedAt)
                        : '';
                    return LineTooltipItem(
                      '${brl.format(s.y)}\n',
                      Theme.of(context).textTheme.titleMedium!,
                      children: [
                        TextSpan(text: date, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    );
                  })
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.goldPrimary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.goldPrimary.withValues(alpha: 0.25),
                    AppColors.goldPrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            if (showIndicators) ...[
              LineChartBarData(
                spots: smaSpots(9),
                color: IndicatorColors.smaFast,
                barWidth: 1,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: smaSpots(21),
                color: IndicatorColors.smaSlow,
                barWidth: 1,
                dotData: const FlDotData(show: false),
              ),
            ],
          ],
        ),
      ),
    );

    if (!showIndicators) return chart;
    return Column(children: [chart, const SizedBox(height: AppSpacing.md), _RsiPanel(prices: prices)]);
  }
}

class _RsiPanel extends StatelessWidget {
  final List<double> prices;
  const _RsiPanel({required this.prices});

  @override
  Widget build(BuildContext context) {
    final values = rsi(prices);
    final spots = [
      for (var i = 0; i < values.length; i++)
        if (values[i] != null) FlSpot(i.toDouble(), values[i]!)
    ];
    if (spots.isEmpty) {
      return Text('RSI precisa de mais dados', style: Theme.of(context).textTheme.bodySmall);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RSI (14)', style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 80,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 30,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
            ),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: IndicatorColors.rsi,
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
