import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/ai_pattern_analysis_service.dart';
import './widgets/analysis_status_card_widget.dart';
import './widgets/pattern_insights_widget.dart';
import './widgets/predicted_hotspots_widget.dart';
import './widgets/recommendations_list_widget.dart';

/// Screen displaying AI-powered incident analysis and predictions
/// Accessible only to authorities for strategic planning
class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final _analysisService = AIPatternAnalysisService();
  Map<String, dynamic>? _currentAnalysis;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLatestAnalysis();
  }

  Future<void> _loadLatestAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analyses = await _analysisService.listRecentAnalyses(limit: 1);
      if (analyses.isNotEmpty) {
        setState(() {
          _currentAnalysis = analyses.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load analysis: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _runNewAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analysisId = await _analysisService.analyzeIncidentPatterns(
        daysBack: 30,
      );

      // Wait briefly for analysis to complete
      await Future.delayed(const Duration(seconds: 2));

      final analysis = await _analysisService.getAnalysis(analysisId);
      setState(() {
        _currentAnalysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Analysis failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights & Predictions'),
        backgroundColor: Colors.deepPurple.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runNewAnalysis,
            tooltip: 'Run New Analysis',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.deepPurple.shade700,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Analyzing incident patterns...',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 14.sp, color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _loadLatestAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (_currentAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 2.h),
            Text(
              'No analysis available',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Run your first analysis to get AI-powered insights',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _runNewAnalysis,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLatestAnalysis,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalysisStatusCardWidget(analysis: _currentAnalysis!),
            SizedBox(height: 2.h),
            PatternInsightsWidget(analysis: _currentAnalysis!),
            SizedBox(height: 2.h),
            PredictedHotspotsWidget(analysis: _currentAnalysis!),
            SizedBox(height: 2.h),
            RecommendationsListWidget(analysis: _currentAnalysis!),
          ],
        ),
      ),
    );
  }
}
