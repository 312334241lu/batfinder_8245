import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/realtime_dashboard_service.dart';

class GeographicHotspotsWidget extends StatelessWidget {
  final List<GeographicHotspot> hotspots;

  const GeographicHotspotsWidget({super.key, required this.hotspots});

  @override
  Widget build(BuildContext context) {
    if (hotspots.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No hay puntos críticos en este momento',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
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
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(13),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Zonas de Alta Actividad',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${hotspots.length} áreas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hotspots.take(5).length,
            separatorBuilder: (context, index) => Divider(height: 0.1.h),
            itemBuilder: (context, index) {
              final hotspot = hotspots[index];
              return _buildHotspotItem(hotspot);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotItem(GeographicHotspot hotspot) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: _getSeverityColor(hotspot.severity).withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          _getSeverityIcon(hotspot.severity),
          color: _getSeverityColor(hotspot.severity),
          size: 20.sp,
        ),
      ),
      title: Text(
        hotspot.title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 0.5.h),
          Text(
            hotspot.locationAddress ?? 'Sin dirección',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Lat: ${hotspot.locationLat.toStringAsFixed(4)}, Lng: ${hotspot.locationLng.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 9.sp, color: Colors.grey[500]),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _getSeverityColor(hotspot.severity),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              _getSeverityLabel(hotspot.severity),
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            _formatTime(hotspot.occurredAt),
            style: TextStyle(fontSize: 9.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.warning;
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 'CRÍTICO';
      case 'high':
        return 'ALTO';
      case 'medium':
        return 'MEDIO';
      case 'low':
        return 'BAJO';
      default:
        return 'N/A';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }
}
