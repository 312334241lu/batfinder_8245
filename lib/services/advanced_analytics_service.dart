import './supabase_service.dart';

class AdvancedAnalyticsService {
  static final AdvancedAnalyticsService _instance =
      AdvancedAnalyticsService._internal();
  factory AdvancedAnalyticsService() => _instance;
  AdvancedAnalyticsService._internal();

  final _client = SupabaseService.client;

  // Hotspot data stream
  Stream<List<Map<String, dynamic>>> get hotspotsStream {
    return _client
        .from('incident_hotspots')
        .stream(primaryKey: ['id'])
        .order('prediction_score', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // Community engagement metrics stream
  Stream<List<Map<String, dynamic>>> get engagementMetricsStream {
    return _client
        .from('community_engagement_metrics')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<Map<String, dynamic>> getAuthoritiesAnalytics() async {
    try {
      final response = await _client.rpc('get_authorities_analytics');

      if (response == null || response.isEmpty) {
        return {
          'total_incidents': 0,
          'pending_incidents': 0,
          'avg_response_time': 0,
          'active_hotspots': 0,
          'community_engagement_score': 0.0,
          'report_quality_score': 0.0,
        };
      }

      return Map<String, dynamic>.from(response.first);
    } catch (error) {
      throw Exception('Failed to get analytics: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getTopHotspots({int limit = 10}) async {
    try {
      final response = await _client.rpc(
        'get_top_hotspots',
        params: {'p_limit': limit},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (error) {
      throw Exception('Failed to get hotspots: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getResponseTimeBenchmarks({
    String? incidentType,
    String? severity,
  }) async {
    try {
      var query = _client.from('response_time_benchmarks').select();

      if (incidentType != null) {
        query = query.eq('incident_type', incidentType);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query.order('target_response_minutes');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get benchmarks: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getCommunityEngagementHistory({
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String();

      final response = await _client
          .from('community_engagement_metrics')
          .select()
          .gte('date', startDate)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get engagement history: $error');
    }
  }

  Future<Map<String, dynamic>> getPredictiveAnalytics(
    double lat,
    double lng, {
    int radiusMeters = 500,
  }) async {
    try {
      final response = await _client.rpc(
        'calculate_hotspot_prediction_score',
        params: {
          'p_location_lat': lat,
          'p_location_lng': lng,
          'p_radius_meters': radiusMeters,
        },
      );

      return {
        'prediction_score': response ?? 0.0,
        'location_lat': lat,
        'location_lng': lng,
        'radius_meters': radiusMeters,
      };
    } catch (error) {
      throw Exception('Failed to get prediction: $error');
    }
  }

  Future<void> updateHotspot(String id, Map<String, dynamic> data) async {
    try {
      await _client
          .from('incident_hotspots')
          .update(data)
          .eq('id', id)
          .select();
    } catch (error) {
      throw Exception('Failed to update hotspot: $error');
    }
  }

  Future<void> createHotspot(Map<String, dynamic> data) async {
    try {
      await _client.from('incident_hotspots').insert(data).select();
    } catch (error) {
      throw Exception('Failed to create hotspot: $error');
    }
  }

  Future<void> updateEngagementMetrics(
    String date,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client
          .from('community_engagement_metrics')
          .update(data)
          .eq('date', date)
          .select();
    } catch (error) {
      throw Exception('Failed to update metrics: $error');
    }
  }
}
