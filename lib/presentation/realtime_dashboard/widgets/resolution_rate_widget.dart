import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ResolutionRateWidget extends StatelessWidget {
  final double resolutionRate;
  final int totalIncidents;
  final int resolvedIncidents;

  const ResolutionRateWidget({
    super.key,
    required this.resolutionRate,
    required this.totalIncidents,
    required this.resolvedIncidents,
  });

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${resolutionRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF66BB6A),
                    ),
                  ),
                  Text(
                    'Tasa de Resolución',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up,
                  color: const Color(0xFF66BB6A),
                  size: 24.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: resolutionRate / 100,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF66BB6A),
              minHeight: 1.h,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Total',
                totalIncidents.toString(),
                Icons.report,
                Colors.blue,
              ),
              _buildStatItem(
                'Resueltas',
                resolvedIncidents.toString(),
                Icons.check_circle,
                const Color(0xFF66BB6A),
              ),
              _buildStatItem(
                'Pendientes',
                (totalIncidents - resolvedIncidents).toString(),
                Icons.pending,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
