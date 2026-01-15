import 'dart:convert';

import 'package:dio/dio.dart';

import './anthropic_client.dart';
import './anthropic_service.dart';
import './supabase_service.dart';

/// Service for AI-powered incident pattern analysis using Claude
/// Provides predictive insights and response recommendations
class AIPatternAnalysisService {
  final _supabase = SupabaseService.client;
  final _anthropicClient = AnthropicClient(AnthropicService().dio);

  /// Analyzes incident patterns and generates AI-powered insights
  /// Returns analysis ID for tracking
  Future<String> analyzeIncidentPatterns({
    int daysBack = 30,
    List<String>? incidentTypes,
    CancelToken? cancelToken,
  }) async {
    try {
      // 1. Create analysis record
      final analysisResponse = await _supabase
          .from('ai_incident_analysis')
          .insert({
            'analysis_type': 'pattern_analysis',
            'analysis_status': 'processing',
            'incident_ids': [],
            'prompt_used':
                'Analyzing incident patterns for predictive insights',
          })
          .select()
          .single();

      final analysisId = analysisResponse['id'] as String;

      // 2. Fetch recent incidents
      final incidents = await _supabase.rpc(
        'get_recent_incidents_for_analysis',
        params: {'days_back': daysBack, 'incident_types': incidentTypes},
      );

      // 3. Fetch hotspot patterns
      final hotspots = await _supabase.rpc('get_hotspot_patterns');

      // 4. Build comprehensive analysis prompt
      final prompt = _buildAnalysisPrompt(incidents, hotspots);

      // 5. Get AI analysis from Claude
      final completion = await _anthropicClient.createChat(
        messages: [Message(role: 'user', content: prompt)],
        model: AnthropicClient.sonnet45,
        maxTokens: 4096,
        cancelToken: cancelToken,
      );

      // 6. Parse AI response
      final analysisResult = _parseAIResponse(completion.text);

      // 7. Update analysis record with results
      await _supabase
          .from('ai_incident_analysis')
          .update({
            'analysis_status': 'completed',
            'incident_ids': (incidents as List).map((i) => i['id']).toList(),
            'analysis_result': analysisResult,
            'pattern_insights': analysisResult['pattern_insights'],
            'recommendations': analysisResult['recommendations'],
            'predicted_hotspots': analysisResult['predicted_hotspots'],
            'risk_assessment': analysisResult['risk_assessment'],
            'deployment_suggestions': analysisResult['deployment_suggestions'],
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', analysisId);

      return analysisId;
    } catch (e) {
      // Update analysis status to failed
      try {
        await _supabase.from('ai_incident_analysis').update({
          'analysis_status': 'failed',
          'error_message': e.toString(),
        });
      } catch (_) {}
      rethrow;
    }
  }

  /// Streams real-time analysis updates
  Stream<String> streamIncidentAnalysis({
    int daysBack = 30,
    List<String>? incidentTypes,
    CancelToken? cancelToken,
  }) async* {
    // 1. Fetch data
    final incidents = await _supabase.rpc(
      'get_recent_incidents_for_analysis',
      params: {'days_back': daysBack, 'incident_types': incidentTypes},
    );

    final hotspots = await _supabase.rpc('get_hotspot_patterns');

    // 2. Build prompt
    final prompt = _buildAnalysisPrompt(incidents, hotspots);

    // 3. Stream AI analysis
    yield* _anthropicClient.streamChat(
      messages: [Message(role: 'user', content: prompt)],
      model: AnthropicClient.sonnet45,
      maxTokens: 4096,
      cancelToken: cancelToken,
    );
  }

  /// Retrieves a specific analysis by ID
  Future<Map<String, dynamic>> getAnalysis(String analysisId) async {
    final response = await _supabase
        .from('ai_incident_analysis')
        .select()
        .eq('id', analysisId)
        .single();

    return response;
  }

  /// Lists recent analyses with pagination
  Future<List<Map<String, dynamic>>> listRecentAnalyses({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('ai_incident_analysis')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Builds comprehensive analysis prompt for Claude
  String _buildAnalysisPrompt(dynamic incidents, dynamic hotspots) {
    final incidentsList = incidents as List;
    final hotspotsList = hotspots as List;

    return '''
You are an expert public safety analyst specializing in incident pattern recognition and predictive response optimization. Analyze the following data and provide actionable insights.

## INCIDENT DATA (Last 30 Days)
Total Incidents: ${incidentsList.length}

Incidents by Type:
${_summarizeIncidentsByType(incidentsList)}

Incidents by Severity:
${_summarizeIncidentsBySeverity(incidentsList)}

Recent Incidents:
${incidentsList.take(20).map((i) => '''
- ${i['title']} (${i['incident_type']}, ${i['severity']})
  Location: ${i['location_address'] ?? 'Unknown'}
  Coordinates: (${i['location_lat']}, ${i['location_lng']})
  Occurred: ${i['occurred_at']}
''').join('\n')}

## HOTSPOT PATTERNS
${hotspotsList.map((h) => '''
- ${h['location_address'] ?? 'Unknown Location'} (${h['hotspot_type']})
  Incidents: ${h['incident_count']}
  Severity Score: ${h['severity_score']}
  Prediction Score: ${h['prediction_score']}
  Time Period: ${h['time_period']}
''').join('\n')}

## ANALYSIS REQUIREMENTS

Provide a comprehensive JSON response with the following structure:

{
  "pattern_insights": "Detailed narrative analysis of observed patterns, trends, and correlations in the incident data. Identify temporal patterns (time of day, day of week), spatial clusters, incident type correlations, and severity escalation trends.",
  
  "predicted_hotspots": [
    {
      "location": "Specific address or area name",
      "coordinates": {"lat": 19.4326, "lng": -99.1332},
      "incident_types": ["robo", "vandalismo"],
      "risk_level": "high|medium|low",
      "prediction_confidence": 0.85,
      "reasoning": "Why this area is predicted to be a hotspot"
    }
  ],
  
  "recommendations": [
    "Increase patrol frequency in Centro Histórico during evening hours (6-10 PM)",
    "Deploy additional units to Colonia Roma on weekends",
    "Install additional lighting in identified dark zones"
  ],
  
  "deployment_suggestions": [
    "Station 2 patrol units at intersection of Reforma & Juárez from 8 PM - 12 AM",
    "Position mobile command center in Polanco during peak hours",
    "Allocate community engagement team to Condesa neighborhood"
  ],
  
  "risk_assessment": {
    "overall_risk_level": "medium",
    "high_risk_areas": ["Centro Histórico", "Tepito"],
    "emerging_threats": ["Increased theft reports near metro stations"],
    "trend_analysis": "15% increase in property crimes compared to previous month"
  }
}

IMPORTANT: 
- Provide specific, actionable recommendations
- Include confidence scores for predictions
- Base all insights on the provided data
- Consider both temporal and spatial patterns
- Prioritize public safety and resource optimization
- Return ONLY valid JSON, no additional text
''';
  }

  /// Summarizes incidents by type for prompt
  String _summarizeIncidentsByType(List incidents) {
    final typeCount = <String, int>{};
    for (var incident in incidents) {
      final type = incident['incident_type'] as String;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    return typeCount.entries.map((e) => '  - ${e.key}: ${e.value}').join('\n');
  }

  /// Summarizes incidents by severity for prompt
  String _summarizeIncidentsBySeverity(List incidents) {
    final severityCount = <String, int>{};
    for (var incident in incidents) {
      final severity = incident['severity'] as String;
      severityCount[severity] = (severityCount[severity] ?? 0) + 1;
    }
    return severityCount.entries
        .map((e) => '  - ${e.key}: ${e.value}')
        .join('\n');
  }

  /// Parses Claude's JSON response into structured data
  Map<String, dynamic> _parseAIResponse(String responseText) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }

      // Fallback: wrap text response in basic structure
      return {
        'pattern_insights': responseText,
        'recommendations': <String>[],
        'predicted_hotspots': <Map<String, dynamic>>[],
        'risk_assessment': {
          'overall_risk_level': 'unknown',
          'high_risk_areas': <String>[],
          'emerging_threats': <String>[],
          'trend_analysis': 'Analysis unavailable',
        },
        'deployment_suggestions': <String>[],
      };
    } catch (e) {
      return {
        'pattern_insights': 'Error parsing AI response: ${e.toString()}',
        'recommendations': <String>[],
        'predicted_hotspots': <Map<String, dynamic>>[],
        'risk_assessment': {
          'overall_risk_level': 'unknown',
          'high_risk_areas': <String>[],
          'emerging_threats': <String>[],
          'trend_analysis': 'Parse error',
        },
        'deployment_suggestions': <String>[],
      };
    }
  }
}
