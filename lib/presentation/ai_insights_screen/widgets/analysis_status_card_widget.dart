import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';


/// Widget displaying analysis status and metadata
class AnalysisStatusCardWidget extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const AnalysisStatusCardWidget({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final status = analysis['analysis_status'] as String;
    final createdAt = DateTime.parse(analysis['created_at'] as String);
    final completedAt = analysis['completed_at'] != null
        ? DateTime.parse(analysis['completed_at'] as String)
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analysis Status',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            SizedBox(height: 2.h),
            _buildInfoRow(
              Icons.calendar_today,
              'Started',
              DateFormat('MMM dd, yyyy HH:mm').format(createdAt),
            ),
            if (completedAt != null) ...[
              SizedBox(height: 1.h),
              _buildInfoRow(
                Icons.check_circle_outline,
                'Completed',
                DateFormat('MMM dd, yyyy HH:mm').format(completedAt),
              ),
            ],
            SizedBox(height: 1.h),
            _buildInfoRow(
              Icons.description,
              'Type',
              analysis['analysis_type'] as String,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'processing':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.hourglass_empty;
        break;
      case 'failed':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.error;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.pending;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: 1.w),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
