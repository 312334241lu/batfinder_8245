import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


/// Widget displaying predicted incident hotspots with risk levels
class PredictedHotspotsWidget extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const PredictedHotspotsWidget({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final predictedHotspots = analysis['predicted_hotspots'] as List?;

    if (predictedHotspots == null || predictedHotspots.isEmpty) {
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
                Icon(Icons.location_on, color: Colors.red.shade700, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Predicted Hotspots',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ...predictedHotspots.map(
              (hotspot) => _buildHotspotCard(hotspot as Map<String, dynamic>),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotspotCard(Map<String, dynamic> hotspot) {
    final location = hotspot['location'] as String? ?? 'Unknown Location';
    final riskLevel = hotspot['risk_level'] as String? ?? 'medium';
    final confidence = hotspot['prediction_confidence'] as double? ?? 0.0;
    final reasoning = hotspot['reasoning'] as String? ?? '';
    final incidentTypes = hotspot['incident_types'] as List? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _getRiskColor(riskLevel).withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRiskColor(riskLevel).withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              _buildRiskBadge(riskLevel),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.analytics, size: 14, color: Colors.grey.shade600),
              SizedBox(width: 1.w),
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (incidentTypes.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              children: incidentTypes
                  .map(
                    (type) => Chip(
                      label: Text(
                        type.toString(),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                      backgroundColor: Colors.grey.shade200,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (reasoning.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              reasoning,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskBadge(String riskLevel) {
    final color = _getRiskColor(riskLevel);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        riskLevel.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.orange.shade700;
      case 'low':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
