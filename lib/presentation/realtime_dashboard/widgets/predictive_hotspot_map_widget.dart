import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/advanced_analytics_service.dart';

class PredictiveHotspotMapWidget extends StatefulWidget {
  const PredictiveHotspotMapWidget({super.key});

  @override
  State<PredictiveHotspotMapWidget> createState() =>
      _PredictiveHotspotMapWidgetState();
}

class _PredictiveHotspotMapWidgetState
    extends State<PredictiveHotspotMapWidget> {
  final _analyticsService = AdvancedAnalyticsService();
  List<Map<String, dynamic>> _hotspots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotspots();
  }

  Future<void> _loadHotspots() async {
    try {
      final hotspots = await _analyticsService.getTopHotspots(limit: 5);
      setState(() {
        _hotspots = hotspots;
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
              Icon(Icons.location_on, color: Colors.red, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Predictive Hotspot Map',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_hotspots.isEmpty)
            Center(
              child: Text(
                'No hotspots available',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            )
          else
            ..._hotspots.map((hotspot) => _buildHotspotCard(hotspot)),
        ],
      ),
    );
  }

  Widget _buildHotspotCard(Map<String, dynamic> hotspot) {
    final predictionScore = (hotspot['prediction_score'] ?? 0.0) as num;
    final incidentCount = (hotspot['incident_count'] ?? 0) as int;
    final address = hotspot['location_address'] ?? 'Unknown location';
    final hotspotType = hotspot['hotspot_type'] ?? 'general';

    Color getRiskColor() {
      if (predictionScore >= 75) return Colors.red;
      if (predictionScore >= 50) return Colors.orange;
      return Colors.yellow.shade700;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: getRiskColor().withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: getRiskColor(), width: 1.5),
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
                  address,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: getRiskColor(),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${predictionScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.warning, size: 14.sp, color: Colors.grey.shade600),
              SizedBox(width: 1.w),
              Text(
                '$incidentCount incidents',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  hotspotType,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}