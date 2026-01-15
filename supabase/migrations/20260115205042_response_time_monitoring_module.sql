-- Location: supabase/migrations/20260115205042_response_time_monitoring_module.sql
-- Schema Analysis: Extending existing batfinder schema with response time monitoring
-- Integration Type: PARTIAL_EXISTS - Adding new notification system module
-- Dependencies: incidents, response_time_benchmarks, user_profiles

-- ==================== 1. TYPES ====================

-- Create escalation level enum for tracking alert severity
CREATE TYPE public.escalation_level AS ENUM ('warning', 'moderate', 'urgent', 'critical');

-- Create alert status enum for tracking notification lifecycle
CREATE TYPE public.alert_status AS ENUM ('pending', 'notified', 'escalated', 'resolved', 'dismissed');

-- ==================== 2. NEW TABLES ====================

-- Response time alerts table to track violations and escalations
CREATE TABLE public.response_time_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
    benchmark_id UUID REFERENCES public.response_time_benchmarks(id) ON DELETE SET NULL,
    
    -- Response time tracking
    reported_at TIMESTAMPTZ NOT NULL,
    first_response_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    response_time_minutes INTEGER,
    target_response_minutes INTEGER NOT NULL,
    
    -- Escalation tracking
    escalation_level public.escalation_level DEFAULT 'warning'::public.escalation_level,
    alert_status public.alert_status DEFAULT 'pending'::public.alert_status,
    times_exceeded INTEGER DEFAULT 1,
    
    -- Notification tracking
    notification_sent_at TIMESTAMPTZ,
    notification_type TEXT[], -- ['email', 'sms']
    notified_users UUID[], -- Array of user_profile IDs
    
    -- Performance recommendations
    recommendations TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Authority notification preferences table
CREATE TABLE public.authority_notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    authority_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    
    -- Notification channels
    email_enabled BOOLEAN DEFAULT true,
    sms_enabled BOOLEAN DEFAULT true,
    
    -- Threshold preferences
    notify_on_warning BOOLEAN DEFAULT false,
    notify_on_moderate BOOLEAN DEFAULT true,
    notify_on_urgent BOOLEAN DEFAULT true,
    notify_on_critical BOOLEAN DEFAULT true,
    
    -- Escalation preferences
    auto_escalate_after_minutes INTEGER DEFAULT 30,
    escalation_recipients UUID[], -- Additional users to notify on escalation
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_authority_preferences UNIQUE(authority_id)
);

-- ==================== 3. INDEXES ====================

CREATE INDEX idx_response_time_alerts_incident_id ON public.response_time_alerts(incident_id);
CREATE INDEX idx_response_time_alerts_status ON public.response_time_alerts(alert_status);
CREATE INDEX idx_response_time_alerts_escalation ON public.response_time_alerts(escalation_level);
CREATE INDEX idx_response_time_alerts_created_at ON public.response_time_alerts(created_at);
CREATE INDEX idx_authority_notification_preferences_authority_id ON public.authority_notification_preferences(authority_id);

-- ==================== 4. FUNCTIONS ====================

-- Function to calculate response time in minutes
CREATE OR REPLACE FUNCTION public.calculate_response_time(
    reported TIMESTAMPTZ,
    responded TIMESTAMPTZ
)
RETURNS INTEGER
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT EXTRACT(EPOCH FROM (responded - reported))::INTEGER / 60;
$$;

-- Function to determine escalation level based on time exceeded
CREATE OR REPLACE FUNCTION public.determine_escalation_level(
    response_time_minutes INTEGER,
    target_minutes INTEGER
)
RETURNS public.escalation_level
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    exceeded_by_minutes INTEGER;
    exceeded_percentage NUMERIC;
BEGIN
    exceeded_by_minutes := response_time_minutes - target_minutes;
    exceeded_percentage := (exceeded_by_minutes::NUMERIC / target_minutes) * 100;
    
    IF exceeded_percentage >= 200 THEN
        RETURN 'critical'::public.escalation_level;
    ELSIF exceeded_percentage >= 100 THEN
        RETURN 'urgent'::public.escalation_level;
    ELSIF exceeded_percentage >= 50 THEN
        RETURN 'moderate'::public.escalation_level;
    ELSE
        RETURN 'warning'::public.escalation_level;
    END IF;
END;
$$;

-- Function to generate performance recommendations
CREATE OR REPLACE FUNCTION public.generate_response_recommendations(
    inc_type TEXT,
    sev public.incident_severity,
    response_minutes INTEGER,
    target_minutes INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    exceeded_by INTEGER;
    recommendations TEXT;
BEGIN
    exceeded_by := response_minutes - target_minutes;
    
    recommendations := format(
        'Tiempo de respuesta excedido por %s minutos (%s%% sobre el objetivo de %s minutos).\n\n',
        exceeded_by,
        ROUND((exceeded_by::NUMERIC / target_minutes) * 100),
        target_minutes
    );
    
    recommendations := recommendations || 'Recomendaciones:\n';
    
    IF sev IN ('critical', 'high') THEN
        recommendations := recommendations || '• Priorizar incidentes de alta severidad\n';
        recommendations := recommendations || '• Activar protocolo de respuesta rápida\n';
    END IF;
    
    IF exceeded_by > 60 THEN
        recommendations := recommendations || '• Considerar asignar más recursos al área\n';
        recommendations := recommendations || '• Revisar disponibilidad de personal\n';
    END IF;
    
    recommendations := recommendations || '• Analizar causas del retraso\n';
    recommendations := recommendations || '• Implementar mejoras en el proceso de respuesta\n';
    
    RETURN recommendations;
END;
$$;

-- Function to check response time and create alerts
CREATE OR REPLACE FUNCTION public.check_incident_response_time()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_response_time INTEGER;
    benchmark_record RECORD;
    escalation_lvl public.escalation_level;
    alert_record RECORD;
BEGIN
    -- Only check when status changes to in_progress or resolved
    IF (TG_OP = 'UPDATE' AND 
        NEW.status IN ('in_progress', 'resolved') AND 
        OLD.status != NEW.status) THEN
        
        -- Get benchmark for this incident type and severity
        SELECT * INTO benchmark_record
        FROM public.response_time_benchmarks
        WHERE incident_type = NEW.incident_type
        AND severity = NEW.severity
        ORDER BY created_at DESC
        LIMIT 1;
        
        IF benchmark_record IS NOT NULL THEN
            -- Calculate response time
            current_response_time := public.calculate_response_time(
                NEW.reported_at,
                CURRENT_TIMESTAMP
            );
            
            -- Check if response time exceeds target
            IF current_response_time > benchmark_record.target_response_minutes THEN
                -- Determine escalation level
                escalation_lvl := public.determine_escalation_level(
                    current_response_time,
                    benchmark_record.target_response_minutes
                );
                
                -- Check if alert already exists for this incident
                SELECT * INTO alert_record
                FROM public.response_time_alerts
                WHERE incident_id = NEW.id
                ORDER BY created_at DESC
                LIMIT 1;
                
                IF alert_record IS NULL THEN
                    -- Create new alert
                    INSERT INTO public.response_time_alerts (
                        incident_id,
                        benchmark_id,
                        reported_at,
                        first_response_at,
                        resolved_at,
                        response_time_minutes,
                        target_response_minutes,
                        escalation_level,
                        alert_status,
                        recommendations
                    ) VALUES (
                        NEW.id,
                        benchmark_record.id,
                        NEW.reported_at,
                        CASE WHEN NEW.status = 'in_progress' THEN CURRENT_TIMESTAMP ELSE NULL END,
                        CASE WHEN NEW.status = 'resolved' THEN CURRENT_TIMESTAMP ELSE NULL END,
                        current_response_time,
                        benchmark_record.target_response_minutes,
                        escalation_lvl,
                        'pending'::public.alert_status,
                        public.generate_response_recommendations(
                            NEW.incident_type,
                            NEW.severity,
                            current_response_time,
                            benchmark_record.target_response_minutes
                        )
                    );
                ELSE
                    -- Update existing alert
                    UPDATE public.response_time_alerts
                    SET
                        first_response_at = CASE 
                            WHEN NEW.status = 'in_progress' AND first_response_at IS NULL 
                            THEN CURRENT_TIMESTAMP 
                            ELSE first_response_at 
                        END,
                        resolved_at = CASE 
                            WHEN NEW.status = 'resolved' 
                            THEN CURRENT_TIMESTAMP 
                            ELSE resolved_at 
                        END,
                        response_time_minutes = current_response_time,
                        escalation_level = escalation_lvl,
                        times_exceeded = times_exceeded + 1,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = alert_record.id;
                END IF;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Function to get authorities to notify based on preferences
CREATE OR REPLACE FUNCTION public.get_authorities_to_notify(
    esc_level public.escalation_level
)
RETURNS TABLE(
    authority_id UUID,
    email TEXT,
    phone_number TEXT,
    full_name TEXT,
    email_enabled BOOLEAN,
    sms_enabled BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT 
        up.id,
        up.email,
        up.phone_number,
        up.full_name,
        COALESCE(anp.email_enabled, true),
        COALESCE(anp.sms_enabled, true)
    FROM public.user_profiles up
    LEFT JOIN public.authority_notification_preferences anp ON up.id = anp.authority_id
    WHERE up.role = 'autoridad'
    AND (
        (esc_level = 'warning' AND COALESCE(anp.notify_on_warning, false)) OR
        (esc_level = 'moderate' AND COALESCE(anp.notify_on_moderate, true)) OR
        (esc_level = 'urgent' AND COALESCE(anp.notify_on_urgent, true)) OR
        (esc_level = 'critical' AND COALESCE(anp.notify_on_critical, true))
    );
$$;

-- ==================== 5. ENABLE RLS ====================

ALTER TABLE public.response_time_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.authority_notification_preferences ENABLE ROW LEVEL SECURITY;

-- ==================== 6. RLS POLICIES ====================

-- Response time alerts policies
CREATE POLICY "authorities_view_all_alerts"
ON public.response_time_alerts
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles up
        WHERE up.id = auth.uid() AND up.role = 'autoridad'
    )
);

CREATE POLICY "authorities_update_alerts"
ON public.response_time_alerts
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles up
        WHERE up.id = auth.uid() AND up.role = 'autoridad'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_profiles up
        WHERE up.id = auth.uid() AND up.role = 'autoridad'
    )
);

-- Authority notification preferences policies
CREATE POLICY "authorities_manage_own_preferences"
ON public.authority_notification_preferences
FOR ALL
TO authenticated
USING (authority_id = auth.uid())
WITH CHECK (authority_id = auth.uid());

-- ==================== 7. TRIGGERS ====================

-- Add updated_at trigger for response_time_alerts
CREATE TRIGGER update_response_time_alerts_updated_at
BEFORE UPDATE ON public.response_time_alerts
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Add updated_at trigger for authority_notification_preferences
CREATE TRIGGER update_authority_notification_preferences_updated_at
BEFORE UPDATE ON public.authority_notification_preferences
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Add trigger to check response time on incident updates
CREATE TRIGGER check_response_time_on_incident_update
AFTER UPDATE ON public.incidents
FOR EACH ROW
EXECUTE FUNCTION public.check_incident_response_time();

-- ==================== 8. MOCK DATA ====================

DO $$
DECLARE
    existing_incident_id UUID;
    existing_benchmark_id UUID;
    existing_authority_id UUID;
BEGIN
    -- Get existing incident, benchmark, and authority for testing
    SELECT id INTO existing_incident_id 
    FROM public.incidents 
    WHERE status = 'pending' 
    LIMIT 1;
    
    SELECT id INTO existing_benchmark_id
    FROM public.response_time_benchmarks
    LIMIT 1;
    
    SELECT id INTO existing_authority_id
    FROM public.user_profiles
    WHERE role = 'autoridad'
    LIMIT 1;
    
    -- Only create mock data if we have existing records
    IF existing_incident_id IS NOT NULL AND existing_benchmark_id IS NOT NULL THEN
        -- Create a sample response time alert (simulating a delayed response)
        INSERT INTO public.response_time_alerts (
            incident_id,
            benchmark_id,
            reported_at,
            response_time_minutes,
            target_response_minutes,
            escalation_level,
            alert_status,
            recommendations
        ) VALUES (
            existing_incident_id,
            existing_benchmark_id,
            NOW() - INTERVAL '45 minutes',
            45,
            30,
            'moderate'::public.escalation_level,
            'pending'::public.alert_status,
            'Tiempo de respuesta excedido por 15 minutos (50% sobre el objetivo de 30 minutos).

Recomendaciones:
• Analizar causas del retraso
• Implementar mejoras en el proceso de respuesta'
        );
    END IF;
    
    -- Create notification preferences for authority if exists
    IF existing_authority_id IS NOT NULL THEN
        INSERT INTO public.authority_notification_preferences (
            authority_id,
            email_enabled,
            sms_enabled,
            notify_on_warning,
            notify_on_moderate,
            notify_on_urgent,
            notify_on_critical,
            auto_escalate_after_minutes
        ) VALUES (
            existing_authority_id,
            true,
            true,
            false,
            true,
            true,
            true,
            30
        )
        ON CONFLICT (authority_id) DO NOTHING;
    END IF;
END $$;