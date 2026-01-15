import './notification_service.dart';
import './supabase_service.dart';

/// Response Time Alert model
class ResponseTimeAlert {
  final String id;
  final String incidentId;
  final String? benchmarkId;
  final DateTime reportedAt;
  final DateTime? firstResponseAt;
  final DateTime? resolvedAt;
  final int responseTimeMinutes;
  final int targetResponseMinutes;
  final String escalationLevel;
  final String alertStatus;
  final int timesExceeded;
  final DateTime? notificationSentAt;
  final List<String>? notificationTypes;
  final List<String>? notifiedUsers;
  final String? recommendations;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResponseTimeAlert({
    required this.id,
    required this.incidentId,
    this.benchmarkId,
    required this.reportedAt,
    this.firstResponseAt,
    this.resolvedAt,
    required this.responseTimeMinutes,
    required this.targetResponseMinutes,
    required this.escalationLevel,
    required this.alertStatus,
    required this.timesExceeded,
    this.notificationSentAt,
    this.notificationTypes,
    this.notifiedUsers,
    this.recommendations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResponseTimeAlert.fromJson(Map<String, dynamic> json) {
    return ResponseTimeAlert(
      id: json['id'] as String,
      incidentId: json['incident_id'] as String,
      benchmarkId: json['benchmark_id'] as String?,
      reportedAt: DateTime.parse(json['reported_at'] as String),
      firstResponseAt: json['first_response_at'] != null
          ? DateTime.parse(json['first_response_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      responseTimeMinutes: json['response_time_minutes'] as int,
      targetResponseMinutes: json['target_response_minutes'] as int,
      escalationLevel: json['escalation_level'] as String,
      alertStatus: json['alert_status'] as String,
      timesExceeded: json['times_exceeded'] as int,
      notificationSentAt: json['notification_sent_at'] != null
          ? DateTime.parse(json['notification_sent_at'] as String)
          : null,
      notificationTypes: json['notification_type'] != null
          ? List<String>.from(json['notification_type'] as List)
          : null,
      notifiedUsers: json['notified_users'] != null
          ? List<String>.from(json['notified_users'] as List)
          : null,
      recommendations: json['recommendations'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  double get exceedancePercentage {
    final exceeded = responseTimeMinutes - targetResponseMinutes;
    return (exceeded / targetResponseMinutes) * 100;
  }

  String get exceedanceLabel {
    final percentage = exceedancePercentage;
    if (percentage >= 200) return 'Crítico';
    if (percentage >= 100) return 'Urgente';
    if (percentage >= 50) return 'Moderado';
    return 'Advertencia';
  }
}

/// Authority Notification Preferences model
class AuthorityNotificationPreferences {
  final String id;
  final String authorityId;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool notifyOnWarning;
  final bool notifyOnModerate;
  final bool notifyOnUrgent;
  final bool notifyOnCritical;
  final int autoEscalateAfterMinutes;
  final List<String>? escalationRecipients;

  AuthorityNotificationPreferences({
    required this.id,
    required this.authorityId,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.notifyOnWarning,
    required this.notifyOnModerate,
    required this.notifyOnUrgent,
    required this.notifyOnCritical,
    required this.autoEscalateAfterMinutes,
    this.escalationRecipients,
  });

  factory AuthorityNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return AuthorityNotificationPreferences(
      id: json['id'] as String,
      authorityId: json['authority_id'] as String,
      emailEnabled: json['email_enabled'] as bool,
      smsEnabled: json['sms_enabled'] as bool,
      notifyOnWarning: json['notify_on_warning'] as bool,
      notifyOnModerate: json['notify_on_moderate'] as bool,
      notifyOnUrgent: json['notify_on_urgent'] as bool,
      notifyOnCritical: json['notify_on_critical'] as bool,
      autoEscalateAfterMinutes: json['auto_escalate_after_minutes'] as int,
      escalationRecipients: json['escalation_recipients'] != null
          ? List<String>.from(json['escalation_recipients'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authority_id': authorityId,
      'email_enabled': emailEnabled,
      'sms_enabled': smsEnabled,
      'notify_on_warning': notifyOnWarning,
      'notify_on_moderate': notifyOnModerate,
      'notify_on_urgent': notifyOnUrgent,
      'notify_on_critical': notifyOnCritical,
      'auto_escalate_after_minutes': autoEscalateAfterMinutes,
      'escalation_recipients': escalationRecipients,
    };
  }
}

/// Service for managing response time monitoring and automated notifications
class ResponseTimeMonitoringService {
  final _supabase = SupabaseService.client;
  final _notificationService = NotificationService();

  /// Fetches all response time alerts with optional filtering
  ///
  /// [alertStatus] - Filter by alert status (pending, notified, escalated, resolved, dismissed)
  /// [escalationLevel] - Filter by escalation level (warning, moderate, urgent, critical)
  /// [limit] - Maximum number of alerts to fetch
  Future<List<ResponseTimeAlert>> fetchResponseTimeAlerts({
    String? alertStatus,
    String? escalationLevel,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('response_time_alerts')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      if (alertStatus != null) {
        query = query.eq('alert_status', alertStatus);
      }

      if (escalationLevel != null) {
        query = query.eq('escalation_level', escalationLevel);
      }

      final response = await query;
      return (response as List)
          .map((json) => ResponseTimeAlert.fromJson(json))
          .toList();
    } catch (error) {
      print('Error fetching response time alerts: $error');
      return [];
    }
  }

  /// Fetches alerts for a specific incident
  Future<List<ResponseTimeAlert>> fetchAlertsForIncident(
    String incidentId,
  ) async {
    try {
      final response = await _supabase
          .from('response_time_alerts')
          .select()
          .eq('incident_id', incidentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ResponseTimeAlert.fromJson(json))
          .toList();
    } catch (error) {
      print('Error fetching incident alerts: $error');
      return [];
    }
  }

  /// Sends notifications for pending alerts
  ///
  /// This method fetches pending alerts and sends notifications to authorities
  /// based on their notification preferences
  Future<void> processAndSendAlertNotifications() async {
    try {
      final pendingAlerts = await fetchResponseTimeAlerts(
        alertStatus: 'pending',
      );

      for (final alert in pendingAlerts) {
        await _sendAlertNotifications(alert);
      }
    } catch (error) {
      print('Error processing alert notifications: $error');
    }
  }

  /// Sends notifications for a specific alert
  Future<void> _sendAlertNotifications(ResponseTimeAlert alert) async {
    try {
      // Get authorities to notify based on escalation level
      final authoritiesToNotify = await _getAuthoritiesToNotify(
        alert.escalationLevel,
      );

      if (authoritiesToNotify.isEmpty) {
        print(
          'No authorities configured to receive ${alert.escalationLevel} level alerts',
        );
        return;
      }

      final notifiedUserIds = <String>[];
      final notificationTypes = <String>[];

      // Fetch incident details for notification
      final incidentResponse = await _supabase
          .from('incidents')
          .select()
          .eq('id', alert.incidentId)
          .single();

      final incidentTitle = incidentResponse['title'] as String;
      final incidentLocation = incidentResponse['location_address'] as String;
      final incidentSeverity = incidentResponse['severity'] as String;

      // Send notifications to each authority
      for (final authority in authoritiesToNotify) {
        // Send email notification
        if (authority['email_enabled'] == true && authority['email'] != null) {
          final emailSent = await _sendEmailAlert(
            email: authority['email'] as String,
            fullName: authority['full_name'] as String,
            alert: alert,
            incidentTitle: incidentTitle,
            incidentLocation: incidentLocation,
            incidentSeverity: incidentSeverity,
          );

          if (emailSent && !notificationTypes.contains('email')) {
            notificationTypes.add('email');
          }
        }

        // Send SMS notification
        if (authority['sms_enabled'] == true &&
            authority['phone_number'] != null) {
          final smsSent = await _sendSmsAlert(
            phoneNumber: authority['phone_number'] as String,
            alert: alert,
            incidentTitle: incidentTitle,
            incidentLocation: incidentLocation,
          );

          if (smsSent && !notificationTypes.contains('sms')) {
            notificationTypes.add('sms');
          }
        }

        notifiedUserIds.add(authority['authority_id'] as String);
      }

      // Update alert status
      await _supabase
          .from('response_time_alerts')
          .update({
            'alert_status': 'notified',
            'notification_sent_at': DateTime.now().toIso8601String(),
            'notification_type': notificationTypes,
            'notified_users': notifiedUserIds,
          })
          .eq('id', alert.id);
    } catch (error) {
      print('Error sending alert notifications: $error');
    }
  }

  /// Gets authorities to notify based on escalation level
  Future<List<Map<String, dynamic>>> _getAuthoritiesToNotify(
    String escalationLevel,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_authorities_to_notify',
        params: {'esc_level': escalationLevel},
      );

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('Error fetching authorities to notify: $error');
      return [];
    }
  }

  /// Sends email alert to authority
  Future<bool> _sendEmailAlert({
    required String email,
    required String fullName,
    required ResponseTimeAlert alert,
    required String incidentTitle,
    required String incidentLocation,
    required String incidentSeverity,
  }) async {
    final subject = '⚠️ Alerta de Tiempo de Respuesta - BatFinder';
    final html =
        '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: ${_getEscalationGradient(alert.escalationLevel)}; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
          .alert-box { background: white; padding: 20px; margin: 15px 0; border-radius: 8px; border-left: 4px solid ${_getEscalationColor(alert.escalationLevel)}; }
          .metric { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #e5e7eb; }
          .metric-label { font-weight: bold; color: #6b7280; }
          .metric-value { color: #111827; }
          .recommendations { background: #fef3c7; padding: 15px; border-radius: 8px; margin: 15px 0; }
          .footer { text-align: center; padding: 20px; color: #6b7280; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>⚠️ BatFinder</h1>
            <p>Alerta de Tiempo de Respuesta</p>
          </div>
          <div class="content">
            <h2>Hola, $fullName</h2>
            <p>Se ha detectado un incidente que excede el tiempo de respuesta objetivo:</p>
            
            <div class="alert-box">
              <h3>📊 Métricas de Respuesta</h3>
              <div class="metric">
                <span class="metric-label">Incidente:</span>
                <span class="metric-value">$incidentTitle</span>
              </div>
              <div class="metric">
                <span class="metric-label">Ubicación:</span>
                <span class="metric-value">$incidentLocation</span>
              </div>
              <div class="metric">
                <span class="metric-label">Severidad:</span>
                <span class="metric-value">$incidentSeverity</span>
              </div>
              <div class="metric">
                <span class="metric-label">Tiempo de Respuesta:</span>
                <span class="metric-value">${alert.responseTimeMinutes} minutos</span>
              </div>
              <div class="metric">
                <span class="metric-label">Objetivo:</span>
                <span class="metric-value">${alert.targetResponseMinutes} minutos</span>
              </div>
              <div class="metric">
                <span class="metric-label">Excedido por:</span>
                <span class="metric-value" style="color: #dc2626; font-weight: bold;">
                  ${alert.responseTimeMinutes - alert.targetResponseMinutes} minutos (${alert.exceedancePercentage.toStringAsFixed(1)}%)
                </span>
              </div>
              <div class="metric">
                <span class="metric-label">Nivel de Escalación:</span>
                <span class="metric-value" style="color: ${_getEscalationColor(alert.escalationLevel)}; font-weight: bold;">
                  ${alert.exceedanceLabel}
                </span>
              </div>
            </div>
            
            ${alert.recommendations != null ? '''
            <div class="recommendations">
              <h3>💡 Recomendaciones</h3>
              <pre style="white-space: pre-wrap; font-family: Arial; margin: 0;">${alert.recommendations}</pre>
            </div>
            ''' : ''}
            
            <p>Por favor, revisa el incidente en la aplicación BatFinder y toma las acciones necesarias.</p>
          </div>
          <div class="footer">
            <p>BatFinder - Sistema de Monitoreo de Tiempos de Respuesta</p>
            <p>Este es un email automático, por favor no responder.</p>
          </div>
        </div>
      </body>
      </html>
    ''';

    return await _notificationService.sendEmailNotification(
      email: email,
      subject: subject,
      html: html,
      type: 'response_time_alert',
    );
  }

  /// Sends SMS alert to authority
  Future<bool> _sendSmsAlert({
    required String phoneNumber,
    required ResponseTimeAlert alert,
    required String incidentTitle,
    required String incidentLocation,
  }) async {
    final message =
        '''
⚠️ ALERTA TIEMPO DE RESPUESTA
Incidente: $incidentTitle
Ubicación: $incidentLocation
Tiempo: ${alert.responseTimeMinutes}min (Objetivo: ${alert.targetResponseMinutes}min)
Exceso: ${alert.responseTimeMinutes - alert.targetResponseMinutes}min (${alert.exceedancePercentage.toStringAsFixed(0)}%)
Nivel: ${alert.exceedanceLabel}
Revisar BatFinder para detalles
''';

    return await _notificationService.sendSmsNotification(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  /// Fetches notification preferences for the current authority user
  Future<AuthorityNotificationPreferences?> fetchMyNotificationPreferences(
    String authorityId,
  ) async {
    try {
      final response = await _supabase
          .from('authority_notification_preferences')
          .select()
          .eq('authority_id', authorityId)
          .maybeSingle();

      if (response == null) return null;

      return AuthorityNotificationPreferences.fromJson(response);
    } catch (error) {
      print('Error fetching notification preferences: $error');
      return null;
    }
  }

  /// Updates notification preferences for the current authority user
  Future<bool> updateNotificationPreferences(
    AuthorityNotificationPreferences preferences,
  ) async {
    try {
      await _supabase
          .from('authority_notification_preferences')
          .upsert(preferences.toJson());
      return true;
    } catch (error) {
      print('Error updating notification preferences: $error');
      return false;
    }
  }

  /// Dismisses an alert
  Future<bool> dismissAlert(String alertId) async {
    try {
      await _supabase
          .from('response_time_alerts')
          .update({'alert_status': 'dismissed'})
          .eq('id', alertId);
      return true;
    } catch (error) {
      print('Error dismissing alert: $error');
      return false;
    }
  }

  /// Marks alert as resolved
  Future<bool> resolveAlert(String alertId) async {
    try {
      await _supabase
          .from('response_time_alerts')
          .update({
            'alert_status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);
      return true;
    } catch (error) {
      print('Error resolving alert: $error');
      return false;
    }
  }

  /// Real-time subscription to response time alerts
  Stream<List<ResponseTimeAlert>> subscribeToAlerts({
    String? alertStatus,
    String? escalationLevel,
  }) {
    var query = _supabase
        .from('response_time_alerts')
        .stream(primaryKey: ['id']);

    return query.map((data) {
      final alerts = (data as List)
          .map((json) => ResponseTimeAlert.fromJson(json))
          .toList();

      // Apply filters
      return alerts.where((alert) {
        if (alertStatus != null && alert.alertStatus != alertStatus) {
          return false;
        }
        if (escalationLevel != null &&
            alert.escalationLevel != escalationLevel) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  // Helper methods for UI styling
  String _getEscalationColor(String escalationLevel) {
    switch (escalationLevel.toLowerCase()) {
      case 'critical':
        return '#dc2626';
      case 'urgent':
        return '#ea580c';
      case 'moderate':
        return '#f59e0b';
      case 'warning':
        return '#10b981';
      default:
        return '#6b7280';
    }
  }

  String _getEscalationGradient(String escalationLevel) {
    switch (escalationLevel.toLowerCase()) {
      case 'critical':
        return 'linear-gradient(135deg, #dc2626 0%, #991b1b 100%)';
      case 'urgent':
        return 'linear-gradient(135deg, #ea580c 0%, #c2410c 100%)';
      case 'moderate':
        return 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)';
      case 'warning':
        return 'linear-gradient(135deg, #10b981 0%, #059669 100%)';
      default:
        return 'linear-gradient(135deg, #6b7280 0%, #4b5563 100%)';
    }
  }
}