import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


/// Widget displaying AI-generated pattern insights and analysis
class PatternInsightsWidget extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const PatternInsightsWidget({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final patternInsights = analysis['pattern_insights'] as String?;
    final riskAssessment = analysis['risk_assessment'] as Map<String, dynamic>?;

    if (patternInsights == null || patternInsights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Colors.deepPurple.shade700,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Pattern Insights',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              patternInsights,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
            if (riskAssessment != null) ...[
              SizedBox(height: 2.h),
              Divider(color: Colors.grey.shade300),
              SizedBox(height: 1.h),
              _buildRiskAssessment(riskAssessment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessment(Map<String, dynamic> riskAssessment) {
    final overallRisk =
        riskAssessment['overall_risk_level'] as String? ?? 'unknown';
    final trendAnalysis = riskAssessment['trend_analysis'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Assessment',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            _buildRiskLevelBadge(overallRisk),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                trendAnalysis,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskLevelBadge(String riskLevel) {
    Color color;
    switch (riskLevel.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${riskLevel.toUpperCase()} RISK',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}