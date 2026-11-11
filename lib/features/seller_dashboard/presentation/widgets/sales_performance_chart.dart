import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:live_shopping/core/utils/currency_formatter.dart';

class SalesPerformanceChart extends StatelessWidget {
  final List<dynamic> dailySales;

  const SalesPerformanceChart({super.key, required this.dailySales});

  @override
  Widget build(BuildContext context) {
    // Convertir les données pour le graphique
    final spots = dailySales.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final revenue = double.parse(entry.value['revenue'].toString());
      return FlSpot(
        index,
        revenue / 1000,
      ); // Mise à l'échelle (ex: en milliers)
    }).toList();

    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1;

    return AspectRatio(
      aspectRatio: 2.2,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return const FlLine(color: BazzarColors.soft, strokeWidth: 1);
            },
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => BazzarColors.primary,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final revenue = double.parse(
                    dailySales[touchedSpot.x.toInt()]['revenue'].toString(),
                  );
                  return LineTooltipItem(
                    CurrencyFormatter.format(revenue),
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: BazzarColors.primary,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: BazzarColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    BazzarColors.primary.withValues(alpha: 0.28),
                    BazzarColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
