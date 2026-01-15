import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/advanced_analytics_service.dart';

class CommunityEngagementWidget extends StatefulWidget {
  const CommunityEngagementWidget({super.key});

  @override
  State<CommunityEngagementWidget> createState() =>
      _CommunityEngagementWidgetState();
}

class _CommunityEngagementWidgetState extends State<CommunityEngagementWidget> {
  final _analyticsService = AdvancedAnalyticsService();
  Map<String, dynamic>? _latestMetrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _setupRealtimeSubscription();
  }

  Future<void> _loadMetrics() async {
    try {
      final history = await _analyticsService.getCommunityEngagementHistory(
        days: 1,
      );
      if (history.isNotEmpty) {
        setState(() {
          _latestMetrics = history.first;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscription() {
    _analyticsService.engagementMetricsStream.listen((data) {
      if (data.isNotEmpty && mounted) {
        setState(() => _latestMetrics = data.first);
      }
    });
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
              Icon(Icons.people, color: Colors.purple, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Community Engagement',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_latestMetrics == null)
            Center(
              child: Text(
                'No metrics available',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCard(
                      'Active Users',
                      _latestMetrics!['active_users']?.toString() ?? '0',
                      Icons.person,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      'Reports',
                      _latestMetrics!['total_reports']?.toString() ?? '0',
                      Icons.report,
                      Colors.orange,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCard(
                      'Volunteers',
                      _latestMetrics!['volunteer_participants']?.toString() ??
                          '0',
                      Icons.volunteer_activism,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      'Quality Score',
                      '${(_latestMetrics!['report_quality_score'] ?? 0.0).toStringAsFixed(1)}%',
                      Icons.star,
                      Colors.purple,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildSatisfactionBar(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSatisfactionBar() {
    final satisfaction =
        (_latestMetrics!['citizen_satisfaction_score'] ?? 0.0) as num;
    final percentage = satisfaction.toDouble() / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Citizen Satisfaction',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
            ),
            Text(
              '${satisfaction.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 0.7
                  ? Colors.green
                  : percentage >= 0.5
                  ? Colors.orange
                  : Colors.red,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}