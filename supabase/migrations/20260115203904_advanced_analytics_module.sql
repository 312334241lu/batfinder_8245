-- Location: supabase/migrations/20260115203904_advanced_analytics_module.sql
-- Schema Analysis: Building upon existing BatFinder schema with incidents, alert_statistics, user_profiles
-- Integration Type: Addition (PARTIAL_EXISTS - extending existing analytics capabilities)
-- Dependencies: incidents, user_profiles, alert_statistics tables

-- MODULE: Advanced Predictive Analytics for Authorities Dashboard
-- Features: Hotspot mapping, response time benchmarking, community engagement metrics

-- ========================================
-- SECTION 1: NEW TABLES FOR ANALYTICS
-- ========================================

-- 1.1: Geographic Hotspot Data with ML Predictions
CREATE TABLE public.incident_hotspots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_lat DOUBLE PRECISION NOT NULL,
    location_lng DOUBLE PRECISION NOT NULL,
    location_address TEXT,
    radius_meters INTEGER DEFAULT 500,
    incident_count INTEGER DEFAULT 0,
    severity_score NUMERIC(5,2) DEFAULT 0.0,
    prediction_score NUMERIC(5,2) DEFAULT 0.0,
    hotspot_type TEXT NOT NULL,
    time_period TEXT NOT NULL,
    last_incident_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_coordinates CHECK (
        location_lat >= -90 AND location_lat <= 90 AND
        location_lng >= -180 AND location_lng <= 180
    ),
    CONSTRAINT valid_scores CHECK (
        severity_score >= 0 AND severity_score <= 100 AND
        prediction_score >= 0 AND prediction_score <= 100
    )
);

-- 1.2: Response Time Benchmarks (Industry Standards)
CREATE TABLE public.response_time_benchmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_type TEXT NOT NULL,
    severity public.incident_severity NOT NULL,
    target_response_minutes INTEGER NOT NULL,
    industry_average_minutes INTEGER NOT NULL,
    best_practice_minutes INTEGER NOT NULL,
    region TEXT DEFAULT 'general',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_times CHECK (
        target_response_minutes > 0 AND
        industry_average_minutes > 0 AND
        best_practice_minutes > 0
    )
);

-- 1.3: Community Engagement Metrics
CREATE TABLE public.community_engagement_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL UNIQUE,
    active_users INTEGER DEFAULT 0,
    total_reports INTEGER DEFAULT 0,
    verified_reports INTEGER DEFAULT 0,
    report_quality_score NUMERIC(5,2) DEFAULT 0.0,
    volunteer_participants INTEGER DEFAULT 0,
    community_feedback_count INTEGER DEFAULT 0,
    average_response_time_minutes INTEGER DEFAULT 0,
    citizen_satisfaction_score NUMERIC(5,2) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_metrics CHECK (
        active_users >= 0 AND
        total_reports >= 0 AND
        verified_reports >= 0 AND
        report_quality_score >= 0 AND report_quality_score <= 100 AND
        citizen_satisfaction_score >= 0 AND citizen_satisfaction_score <= 100
    )
);

-- ========================================
-- SECTION 2: INDEXES FOR PERFORMANCE
-- ========================================

-- Hotspots indexes
CREATE INDEX idx_incident_hotspots_location ON public.incident_hotspots(location_lat, location_lng);
CREATE INDEX idx_incident_hotspots_type ON public.incident_hotspots(hotspot_type);
CREATE INDEX idx_incident_hotspots_period ON public.incident_hotspots(time_period);
CREATE INDEX idx_incident_hotspots_prediction ON public.incident_hotspots(prediction_score DESC);

-- Benchmarks indexes
CREATE INDEX idx_response_benchmarks_type ON public.response_time_benchmarks(incident_type);
CREATE INDEX idx_response_benchmarks_severity ON public.response_time_benchmarks(severity);

-- Engagement metrics index
CREATE INDEX idx_engagement_metrics_date ON public.community_engagement_metrics(date DESC);

-- ========================================
-- SECTION 3: ENABLE ROW LEVEL SECURITY
-- ========================================

ALTER TABLE public.incident_hotspots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.response_time_benchmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_engagement_metrics ENABLE ROW LEVEL SECURITY;

-- ========================================
-- SECTION 4: RLS POLICIES (Pattern 4 - Public Read, Authority Write)
-- ========================================

-- 4.1: Hotspots policies
CREATE POLICY "public_can_read_hotspots"
ON public.incident_hotspots
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "authorities_manage_hotspots"
ON public.incident_hotspots
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles up
        WHERE up.id = auth.uid() AND up.role = 'autoridad'::public.user_role
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_profiles up
        WHERE up.id = auth.uid() AND up.role = 'autoridad'::public.user_role
    )
);

-- 4.2: Benchmarks policies
CREATE POLICY "public_can_read_benchmarks"
ON public.response_time_benchmarks
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "authorities_manage_benchmarks"
ON public.response_time_benchmarks
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles up
        WHERE up.id = auth.uid() AND up.role = 'autoridad'::public.user_role
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_profiles up
        WHERE up.id = auth.uid() AND up.role = 'autoridad'::public.user_role
    )
);

-- 4.3: Engagement metrics policies
CREATE POLICY "public_can_read_engagement"
ON public.community_engagement_metrics
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "authorities_manage_engagement"
ON public.community_engagement_metrics
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles up
        WHERE up.id = auth.uid() AND up.role = 'autoridad'::public.user_role
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.user_profiles up
        WHERE up.id = auth.uid() AND up.role = 'autoridad'::public.user_role
    )
);

-- ========================================
-- SECTION 5: TRIGGERS FOR AUTO-UPDATE
-- ========================================

-- Reuse existing update_updated_at_column function
CREATE TRIGGER update_incident_hotspots_updated_at
    BEFORE UPDATE ON public.incident_hotspots
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_response_benchmarks_updated_at
    BEFORE UPDATE ON public.response_time_benchmarks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_engagement_metrics_updated_at
    BEFORE UPDATE ON public.community_engagement_metrics
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ========================================
-- SECTION 6: ANALYTICS FUNCTIONS
-- ========================================

-- 6.1: Calculate hotspot prediction score based on historical data
CREATE OR REPLACE FUNCTION public.calculate_hotspot_prediction_score(
    p_location_lat DOUBLE PRECISION,
    p_location_lng DOUBLE PRECISION,
    p_radius_meters INTEGER
)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
    v_recent_incidents INTEGER;
    v_severity_avg NUMERIC;
    v_trend_factor NUMERIC;
    v_prediction_score NUMERIC;
BEGIN
    SELECT 
        COUNT(*),
        AVG(
            CASE 
                WHEN i.severity = 'low'::public.incident_severity THEN 1
                WHEN i.severity = 'medium'::public.incident_severity THEN 2
                WHEN i.severity = 'high'::public.incident_severity THEN 3
                WHEN i.severity = 'critical'::public.incident_severity THEN 4
                ELSE 0
            END
        )
    INTO v_recent_incidents, v_severity_avg
    FROM public.incidents i
    WHERE i.occurred_at >= NOW() - INTERVAL '30 days'
    AND (
        6371000 * acos(
            cos(radians(p_location_lat)) * cos(radians(i.location_lat)) *
            cos(radians(i.location_lng) - radians(p_location_lng)) +
            sin(radians(p_location_lat)) * sin(radians(i.location_lat))
        )
    ) <= p_radius_meters;
    
    v_trend_factor := COALESCE(v_recent_incidents * v_severity_avg, 0);
    v_prediction_score := LEAST(100, (v_trend_factor / 10.0) * 100);
    
    RETURN ROUND(v_prediction_score, 2);
END;
$$;

-- 6.2: Get real-time analytics for authorities dashboard
CREATE OR REPLACE FUNCTION public.get_authorities_analytics()
RETURNS TABLE(
    total_incidents INTEGER,
    pending_incidents INTEGER,
    avg_response_time INTEGER,
    active_hotspots INTEGER,
    community_engagement_score NUMERIC,
    report_quality_score NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM public.incidents WHERE occurred_at >= NOW() - INTERVAL '30 days'),
        (SELECT COUNT(*)::INTEGER FROM public.incidents WHERE status = 'pending'::public.incident_status),
        (SELECT AVG(average_response_time_minutes)::INTEGER FROM public.alert_statistics WHERE date >= CURRENT_DATE - INTERVAL '7 days'),
        (SELECT COUNT(*)::INTEGER FROM public.incident_hotspots WHERE prediction_score >= 50),
        (SELECT AVG(citizen_satisfaction_score) FROM public.community_engagement_metrics WHERE date >= CURRENT_DATE - INTERVAL '30 days'),
        (SELECT AVG(report_quality_score) FROM public.community_engagement_metrics WHERE date >= CURRENT_DATE - INTERVAL '30 days');
END;
$$;

-- 6.3: Get top incident hotspots for map visualization
CREATE OR REPLACE FUNCTION public.get_top_hotspots(p_limit INTEGER DEFAULT 10)
RETURNS TABLE(
    id UUID,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    location_address TEXT,
    incident_count INTEGER,
    severity_score NUMERIC,
    prediction_score NUMERIC,
    hotspot_type TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.id,
        h.location_lat,
        h.location_lng,
        h.location_address,
        h.incident_count,
        h.severity_score,
        h.prediction_score,
        h.hotspot_type
    FROM public.incident_hotspots h
    ORDER BY h.prediction_score DESC, h.incident_count DESC
    LIMIT p_limit;
END;
$$;

-- ========================================
-- SECTION 7: MOCK DATA
-- ========================================

DO $$
DECLARE
    v_hotspot1_id UUID := gen_random_uuid();
    v_hotspot2_id UUID := gen_random_uuid();
    v_hotspot3_id UUID := gen_random_uuid();
BEGIN
    -- Mock hotspot data
    INSERT INTO public.incident_hotspots (
        id, location_lat, location_lng, location_address, radius_meters,
        incident_count, severity_score, prediction_score, hotspot_type, time_period
    ) VALUES
        (v_hotspot1_id, 19.4326, -99.1332, 'Centro Histórico, CDMX', 500, 
         15, 75.5, 82.3, 'robo', 'evening'),
        (v_hotspot2_id, 19.4285, -99.1277, 'Colonia Juárez, CDMX', 400, 
         8, 45.2, 58.7, 'infraestructura', 'night'),
        (v_hotspot3_id, 19.4350, -99.1400, 'Alameda Central, CDMX', 600, 
         12, 65.8, 71.2, 'vandalismo', 'afternoon');

    -- Mock response time benchmarks
    INSERT INTO public.response_time_benchmarks (
        incident_type, severity, target_response_minutes, 
        industry_average_minutes, best_practice_minutes, region
    ) VALUES
        ('robo', 'critical'::public.incident_severity, 5, 8, 3, 'urban'),
        ('robo', 'high'::public.incident_severity, 10, 15, 8, 'urban'),
        ('infraestructura', 'medium'::public.incident_severity, 60, 120, 45, 'urban'),
        ('vandalismo', 'low'::public.incident_severity, 240, 480, 180, 'urban');

    -- Mock community engagement metrics
    INSERT INTO public.community_engagement_metrics (
        date, active_users, total_reports, verified_reports, 
        report_quality_score, volunteer_participants, 
        community_feedback_count, average_response_time_minutes, 
        citizen_satisfaction_score
    ) VALUES
        (CURRENT_DATE, 145, 23, 18, 78.5, 12, 45, 15, 72.3),
        (CURRENT_DATE - INTERVAL '1 day', 132, 19, 15, 75.2, 10, 38, 18, 68.9),
        (CURRENT_DATE - INTERVAL '2 days', 156, 27, 22, 81.3, 15, 52, 12, 76.5);
END $$;