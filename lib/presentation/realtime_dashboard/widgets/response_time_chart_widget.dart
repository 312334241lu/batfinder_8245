import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class ResponseTimeChartWidget extends StatelessWidget {
  final int averageResponseTime;

  const ResponseTimeChartWidget({super.key, required this.averageResponseTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiempo Promedio',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '$averageResponseTime min',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A73E8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 20.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Lun',
                          'Mar',
                          'Mié',
                          'Jue',
                          'Vie',
                          'Sáb',
                          'Dom',
                        ];
                        return Text(
                          days[value.toInt() % days.length],
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _generateBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    final values = [45.0, 38.0, 52.0, 41.0, 48.0, 35.0, 42.0];

    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: values[index],
            color: const Color(0xFF1A73E8),
            width: 3.w,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ],
      );
    });
  }
}
