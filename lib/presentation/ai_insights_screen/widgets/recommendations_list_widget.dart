import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


/// Widget displaying AI-generated recommendations and deployment suggestions
class RecommendationsListWidget extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const RecommendationsListWidget({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final recommendations = analysis['recommendations'] as List?;
    final deploymentSuggestions = analysis['deployment_suggestions'] as List?;

    if ((recommendations == null || recommendations.isEmpty) &&
        (deploymentSuggestions == null || deploymentSuggestions.isEmpty)) {
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
                Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
            if (recommendations != null && recommendations.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                'Strategic Actions',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 1.h),
              ...recommendations.asMap().entries.map(
                (entry) => _buildRecommendationItem(
                  entry.key + 1,
                  entry.value.toString(),
                  Colors.blue.shade700,
                ),
              ),
            ],
            if (deploymentSuggestions != null &&
                deploymentSuggestions.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                'Deployment Suggestions',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 1.h),
              ...deploymentSuggestions.asMap().entries.map(
                (entry) => _buildRecommendationItem(
                  entry.key + 1,
                  entry.value.toString(),
                  Colors.deepPurple.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(int index, String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
