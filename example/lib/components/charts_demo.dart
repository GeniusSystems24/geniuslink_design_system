import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class ChartsDemo extends StatelessWidget {
  const ChartsDemo({super.key});
  @override
  Widget build(BuildContext context) => GLShell(
        title: 'Charts',
        subtitle: 'Line · area · bar · donut · KPI · progress · states',
        children: const [
          GLSection(title: 'Chart primitives', children: [
            GLSpec(label: 'Line / Area', child: GLChartFrame(title: 'Revenue trend', child: GLLineAreaChart(), legend: [GLChartLegendItem(label: 'Revenue', color: GeniusThemeData.blue500)])),
            GLSpec(label: 'Bars', child: GLChartFrame(title: 'Monthly revenue', child: GLBarChart(), legend: [GLChartLegendItem(label: 'Actual', color: GeniusThemeData.blue500)])),
            GLSpec(label: 'Donut', child: GLChartFrame(title: 'Revenue mix', child: GLDonutChart())),
            GLSpec(label: 'Progress', child: Center(child: GLProgressRing())),
            GLSpec(label: 'KPI Spark', child: GLKpiSparkline(label: 'Gross margin', value: '42.8%')),
            GLSpec(label: 'Empty State', child: GLChartState(state: 'empty')),
          ]),
        ],
      );
}
