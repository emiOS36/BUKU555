String formatChartValue(double value) {
  if (value >= 1000) {
    final thousands = (value / 1000)
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'\.?0+$'), '');

    return '${thousands}k';
  }

  return value.toInt().toString();
}
