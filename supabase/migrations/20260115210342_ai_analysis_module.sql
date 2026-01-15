-- Location: supabase/migrations/20260115210342_ai_analysis_module.sql
-- Schema Analysis: Existing incidents, incident_hotspots, response_time_alerts, response_time_benchmarks tables
-- Integration Type: Addition - New AI analysis tracking table
-- Dependencies: incidents table for foreign key relationship

-- 1. Create ENUM type for analysis status
CREATE TYPE public.analysis_status AS ENUM ('pending', 'processing', 'completed', 'failed');

-- 2. Create table to store AI analysis results
CREATE TABLE public.ai_incident_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_type TEXT NOT NULL,
    analysis_status public.analysis_status DEFAULT 'pending'::public.analysis_status,
    incident_ids UUID[] NOT NULL,
    prompt_used TEXT NOT NULL,
    analysis_result JSONB,
    pattern_insights TEXT,
    recommendations TEXT[],
    predicted_hotspots JSONB,
    risk_assessment JSONB,
    deployment_suggestions TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    error_message TEXT
);

-- 3. Create indexes for performance
CREATE INDEX idx_ai_analysis_status ON public.ai_incident_analysis(analysis_status);
CREATE INDEX idx_ai_analysis_type ON public.ai_incident_analysis(analysis_type);
CREATE INDEX idx_ai_analysis_created_at ON public.ai_incident_analysis(created_at DESC);

-- 4. Enable RLS
ALTER TABLE public.ai_incident_analysis ENABLE ROW LEVEL SECURITY;

-- 5. Create helper function for role-based access (Pattern 6 - Option A)
CREATE OR REPLACE FUNCTION public.is_authority_from_auth()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND au.raw_user_meta_data->>'role' = 'autoridad'
)
$$;

-- 6. RLS Policies - Only authorities can access AI analysis
CREATE POLICY "authorities_view_ai_analysis"
ON public.ai_incident_analysis
FOR SELECT
TO authenticated
USING (public.is_authority_from_auth());

CREATE POLICY "authorities_create_ai_analysis"
ON public.ai_incident_analysis
FOR INSERT
TO authenticated
WITH CHECK (public.is_authority_from_auth());

CREATE POLICY "authorities_update_ai_analysis"
ON public.ai_incident_analysis
FOR UPDATE
TO authenticated
USING (public.is_authority_from_auth())
WITH CHECK (public.is_authority_from_auth());

-- 7. Create function to get recent incidents for analysis
CREATE OR REPLACE FUNCTION public.get_recent_incidents_for_analysis(
    days_back INTEGER DEFAULT 30,
    incident_types TEXT[] DEFAULT NULL
)
RETURNS TABLE(
    id UUID,
    title TEXT,
    incident_type TEXT,
    severity TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    location_address TEXT,
    occurred_at TIMESTAMPTZ,
    status TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT 
        i.id,
        i.title,
        i.incident_type,
        i.severity::TEXT,
        i.location_lat,
        i.location_lng,
        i.location_address,
        i.occurred_at,
        i.status::TEXT
    FROM public.incidents i
    WHERE i.occurred_at >= NOW() - (days_back || ' days')::INTERVAL
    AND (incident_types IS NULL OR i.incident_type = ANY(incident_types))
    ORDER BY i.occurred_at DESC;
$$;

-- 8. Create function to get hotspot patterns
CREATE OR REPLACE FUNCTION public.get_hotspot_patterns()
RETURNS TABLE(
    id UUID,
    hotspot_type TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    location_address TEXT,
    incident_count INTEGER,
    severity_score NUMERIC,
    prediction_score NUMERIC,
    time_period TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT 
        ih.id,
        ih.hotspot_type,
        ih.location_lat,
        ih.location_lng,
        ih.location_address,
        ih.incident_count,
        ih.severity_score,
        ih.prediction_score,
        ih.time_period
    FROM public.incident_hotspots ih
    ORDER BY ih.prediction_score DESC, ih.severity_score DESC;
$$;

-- 9. Create trigger for updated_at timestamp
CREATE TRIGGER update_ai_analysis_updated_at
    BEFORE UPDATE ON public.ai_incident_analysis
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();