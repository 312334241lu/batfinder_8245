import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model class for dashboard statistics
class DashboardStatistics {
  final String id;
  final DateTime date;
  final int totalIncidents;
  final int pendingIncidents;
  final int resolvedIncidents;
  final int verifiedIncidents;
  final int averageResponseTimeMinutes;
  final double safetyScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  DashboardStatistics({
    required this.id,
    required this.date,
    required this.totalIncidents,
    required this.pendingIncidents,
    required this.resolvedIncidents,
    required this.verifiedIncidents,
    required this.averageResponseTimeMinutes,
    required this.safetyScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      totalIncidents: json['total_incidents'] ?? 0,
      pendingIncidents: json['pending_incidents'] ?? 0,
      resolvedIncidents: json['resolved_incidents'] ?? 0,
      verifiedIncidents: json['verified_incidents'] ?? 0,
      averageResponseTimeMinutes: json['average_response_time_minutes'] ?? 0,
      safetyScore: (json['safety_score'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convenience getters
  int get totalAlerts => totalIncidents;
  int get activeAlerts => pendingIncidents;
  int get resolvedAlerts => resolvedIncidents;
  int get verifiedAlerts => verifiedIncidents;
  int get averageResponseTime => averageResponseTimeMinutes;

  double get resolutionRate {
    if (totalIncidents == 0) return 0.0;
    return (resolvedIncidents / totalIncidents) * 100;
  }

  double get verificationRate {
    if (totalIncidents == 0) return 0.0;
    return (verifiedIncidents / totalIncidents) * 100;
  }
}

/// Model class for geographic hotspot
class GeographicHotspot {
  final String id;
  final String title;
  final String incidentType;
  final String severity;
  final double locationLat;
  final double locationLng;
  final String? locationAddress;
  final DateTime occurredAt;
  final int incidentCount;

  GeographicHotspot({
    required this.id,
    required this.title,
    required this.incidentType,
    required this.severity,
    required this.locationLat,
    required this.locationLng,
    this.locationAddress,
    required this.occurredAt,
    this.incidentCount = 1,
  });

  factory GeographicHotspot.fromJson(Map<String, dynamic> json) {
    return GeographicHotspot(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      incidentType: json['incident_type'] ?? '',
      severity: json['severity'] ?? 'medium',
      locationLat: (json['location_lat'] ?? 0).toDouble(),
      locationLng: (json['location_lng'] ?? 0).toDouble(),
      locationAddress: json['location_address'],
      occurredAt: DateTime.parse(json['occurred_at']),
      incidentCount: json['incident_count'] ?? 1,
    );
  }
}

/// Service for real-time dashboard data with Supabase subscriptions
class RealtimeDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<List<Map<String, dynamic>>>? _statisticsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _incidentsSubscription;

  final StreamController<DashboardStatistics> _statisticsController =
      StreamController<DashboardStatistics>.broadcast();
  final StreamController<List<GeographicHotspot>> _hotspotsController =
      StreamController<List<GeographicHotspot>>.broadcast();

  Stream<DashboardStatistics> get statisticsStream =>
      _statisticsController.stream;
  Stream<List<GeographicHotspot>> get hotspotsStream =>
      _hotspotsController.stream;

  /// Fetch today's dashboard statistics
  Future<DashboardStatistics?> fetchTodayStatistics() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('alert_statistics')
          .select()
          .eq('date', today)
          .maybeSingle();

      if (response == null) {
        return DashboardStatistics(
          id: '',
          date: DateTime.now(),
          totalIncidents: 0,
          pendingIncidents: 0,
          resolvedIncidents: 0,
          verifiedIncidents: 0,
          averageResponseTimeMinutes: 0,
          safetyScore: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return DashboardStatistics.fromJson(response);
    } catch (e) {
      print('Error fetching statistics: $e');
      return null;
    }
  }

  /// Fetch geographic hotspots with incident clustering
  Future<List<GeographicHotspot>> fetchGeographicHotspots({
    int limit = 50,
    String? severityFilter,
  }) async {
    try {
      var query = _supabase
          .from('incidents')
          .select()
          .order('occurred_at', ascending: false)
          .limit(limit);

      // Remove the .eq() call on query since it's already executed
      final response = severityFilter != null
          ? await _supabase
                .from('incidents')
                .select()
                .eq('severity', severityFilter)
                .order('occurred_at', ascending: false)
                .limit(limit)
          : await query;

      return (response as List)
          .map((json) => GeographicHotspot.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching hotspots: $e');
      return [];
    }
  }

  /// Start real-time subscription for statistics updates
  void subscribeToStatistics() {
    final today = DateTime.now().toIso8601String().split('T')[0];

    _statisticsSubscription = _supabase
        .from('alert_statistics')
        .stream(primaryKey: ['id'])
        .eq('date', today)
        .listen((data) {
          if (data.isNotEmpty) {
            final statistics = DashboardStatistics.fromJson(data.first);
            _statisticsController.add(statistics);
          }
        });
  }

  /// Start real-time subscription for incident updates
  void subscribeToIncidents() {
    _incidentsSubscription = _supabase
        .from('incidents')
        .stream(primaryKey: ['id'])
        .order('occurred_at', ascending: false)
        .limit(50)
        .listen((data) {
          final hotspots = data
              .map((json) => GeographicHotspot.fromJson(json))
              .toList();
          _hotspotsController.add(hotspots);
        });
  }

  /// Get statistics for a specific date range
  Future<List<DashboardStatistics>> fetchStatisticsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('alert_statistics')
          .select()
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      return (response as List)
          .map((json) => DashboardStatistics.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching statistics by date range: $e');
      return [];
    }
  }

  /// Get incident counts by severity
  Future<Map<String, int>> fetchIncidentsBySeverity() async {
    try {
      final response = await _supabase.from('incidents').select('severity');

      final Map<String, int> severityCounts = {
        'low': 0,
        'medium': 0,
        'high': 0,
        'critical': 0,
      };

      for (var incident in response) {
        final severity = incident['severity'] ?? 'medium';
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }

      return severityCounts;
    } catch (e) {
      print('Error fetching incidents by severity: $e');
      return {};
    }
  }

  /// Dispose subscriptions and controllers
  void dispose() {
    _statisticsSubscription?.cancel();
    _incidentsSubscription?.cancel();
    _statisticsController.close();
    _hotspotsController.close();
  }
}
