/// Indicadores de análise técnica (premium), calculados sobre o histórico já carregado.
library;

/// SMA de [period]; resultado alinhado ao índice final da janela.
/// Índices < period-1 ficam null.
List<double?> sma(List<double> prices, int period) {
  final out = List<double?>.filled(prices.length, null);
  if (period <= 0 || prices.length < period) return out;
  var sum = prices.take(period).reduce((a, b) => a + b);
  out[period - 1] = sum / period;
  for (var i = period; i < prices.length; i++) {
    sum += prices[i] - prices[i - period];
    out[i] = sum / period;
  }
  return out;
}

/// RSI de Wilder, período [period]. Índices < period ficam null.
List<double?> rsi(List<double> prices, [int period = 14]) {
  final out = List<double?>.filled(prices.length, null);
  if (prices.length <= period) return out;
  double avgGain = 0, avgLoss = 0;
  for (var i = 1; i <= period; i++) {
    final d = prices[i] - prices[i - 1];
    if (d > 0) {
      avgGain += d;
    } else {
      avgLoss -= d;
    }
  }
  avgGain /= period;
  avgLoss /= period;
  out[period] = avgLoss == 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss);
  for (var i = period + 1; i < prices.length; i++) {
    final d = prices[i] - prices[i - 1];
    avgGain = (avgGain * (period - 1) + (d > 0 ? d : 0)) / period;
    avgLoss = (avgLoss * (period - 1) + (d < 0 ? -d : 0)) / period;
    out[i] = avgLoss == 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss);
  }
  return out;
}
