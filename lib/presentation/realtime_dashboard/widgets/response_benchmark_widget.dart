import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/advanced_analytics_service.dart';

class ResponseBenchmarkWidget extends StatefulWidget {
  const ResponseBenchmarkWidget({super.key});

  @override
  State<ResponseBenchmarkWidget> createState() =>
      _ResponseBenchmarkWidgetState();
}

class _ResponseBenchmarkWidgetState extends State<ResponseBenchmarkWidget> {
  final _analyticsService = AdvancedAnalyticsService();
  List<Map<String, dynamic>> _benchmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBenchmarks();
  }

  Future<void> _loadBenchmarks() async {
    try {
      final benchmarks = await _analyticsService.getResponseTimeBenchmarks();
      setState(() {
        _benchmarks = benchmarks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: Colors.blue, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Response Time Benchmarks',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_benchmarks.isEmpty)
            Center(
              child: Text(
                'No benchmarks available',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            )
          else
            ..._benchmarks
                .take(3)
                .map((benchmark) => _buildBenchmarkRow(benchmark)),
        ],
      ),
    );
  }

  Widget _buildBenchmarkRow(Map<String, dynamic> benchmark) {
    final incidentType = benchmark['incident_type'] ?? 'Unknown';
    final severity = benchmark['severity'] ?? 'medium';
    final targetTime = (benchmark['target_response_minutes'] ?? 0) as int;
    final industryAvg = (benchmark['industry_average_minutes'] ?? 0) as int;
    final bestPractice = (benchmark['best_practice_minutes'] ?? 0) as int;

    Color getSeverityColor() {
      switch (severity) {
        case 'critical':
          return Colors.red;
        case 'high':
          return Colors.orange;
        case 'medium':
          return Colors.yellow.shade700;
        default:
          return Colors.green;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  incidentType,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: getSeverityColor().withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: getSeverityColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeMetric('Target', targetTime, Colors.blue),
              _buildTimeMetric('Industry', industryAvg, Colors.grey),
              _buildTimeMetric('Best', bestPractice, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(String label, int minutes, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 0.3.h),
        Text(
          '${minutes}m',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}