import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyChart extends StatefulWidget {
  const MyChart({super.key});

  @override
  State<MyChart> createState() => _MyChartState();
}

class _MyChartState extends State<MyChart> {
  // Generate bar chart groups
  List<BarChartGroupData> get showingGroups => List.generate(8, (i) {
    switch (i) {
      case 0:
        return makeGroupData(0, 2);
      case 1:
        return makeGroupData(1, 3);
      case 2:
        return makeGroupData(2, 2);
      case 3:
        return makeGroupData(3, 4.5);
      case 4:
        return makeGroupData(4, 3.8);
      case 5:
        return makeGroupData(5, 1.5);
      case 6:
        return makeGroupData(6, 4);
      case 7:
        return makeGroupData(7, 3.8);
      default:
        return throw Error();
    }
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(mainBarchart()),
    );
  }

  // Create each group of bars
  BarChartGroupData makeGroupData(
    int x,
    double y, [
    Color barColor = const Color(0xFF00B2E7),
  ]) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.tertiary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.primary,
            ],
            transform: const GradientRotation(pi / 4),
          ),
          width: 10,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 6,
            color: const Color(0xFFB7B7B7),
          ),
        ),
      ],
    );
  }

  // Full chart config
  BarChartData mainBarchart() {
    return BarChartData(
      maxY: 6,
      barGroups: showingGroups,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        show: true,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 32),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: getTitles,
          ),
        ),
      ),
    );
  }

  // Bottom axis label widget
  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xFFB7B7B7),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Jan', style: style);
        break;
      case 1:
        text = const Text('Feb', style: style);
        break;
      case 2:
        text = const Text('Mar', style: style);
        break;
      case 3:
        text = const Text('Apr', style: style);
        break;
      case 4:
        text = const Text('Mai', style: style);
        break;
      case 5:
        text = const Text('Jun', style: style);
        break;
      case 6:
        text = const Text('Jul', style: style);
        break;
      case 7:
        text = const Text('Aug', style: style);
        break;
      default:
        text = const Text('', style: style);
    }

    return SideTitleWidget(space: 4, angle: 0, meta: meta, child: text);
  }
}
