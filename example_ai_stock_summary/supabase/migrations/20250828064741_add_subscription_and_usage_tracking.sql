-- Location: supabase/migrations/20250828064741_add_subscription_and_usage_tracking.sql
-- Schema Analysis: Extending existing stock management system with subscription features
-- Integration Type: Addition - Adding subscription and usage tracking
-- Dependencies: user_profiles, ai_summaries (existing tables)

-- 1. CREATE ENUMS
CREATE TYPE public.subscription_tier AS ENUM ('free', 'premium');
CREATE TYPE public.subscription_status AS ENUM ('active', 'expired', 'cancelled');
CREATE TYPE public.ad_type AS ENUM ('rewarded_video', 'interstitial', 'banner');

-- 2. USER SUBSCRIPTION MANAGEMENT
CREATE TABLE public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    tier public.subscription_tier DEFAULT 'free'::public.subscription_tier NOT NULL,
    status public.subscription_status DEFAULT 'active'::public.subscription_status NOT NULL,
    monthly_summary_limit INTEGER DEFAULT 10 NOT NULL,
    current_month_usage INTEGER DEFAULT 0 NOT NULL,
    usage_reset_date DATE DEFAULT CURRENT_DATE + INTERVAL '1 month' NOT NULL,
    subscription_start_date DATE DEFAULT CURRENT_DATE NOT NULL,
    subscription_end_date DATE NULL,
    auto_renew BOOLEAN DEFAULT false,
    purchase_receipt TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. SUMMARY USAGE TRACKING  
CREATE TABLE public.ai_summary_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    summary_id UUID REFERENCES public.ai_summaries(id) ON DELETE CASCADE NOT NULL,
    usage_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE) NOT NULL,
    usage_source TEXT DEFAULT 'normal' CHECK (usage_source IN ('normal', 'ad_reward', 'premium')),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. AD REWARD SYSTEM
CREATE TABLE public.ad_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    ad_type public.ad_type NOT NULL,
    ad_unit_id TEXT NOT NULL,
    reward_earned BOOLEAN DEFAULT false,
    reward_amount INTEGER DEFAULT 1, -- Credits earned
    interaction_date DATE DEFAULT CURRENT_DATE NOT NULL,
    session_id TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. MULTILINGUAL SUMMARY STORAGE
CREATE TABLE public.ai_summary_translations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_summary_id UUID REFERENCES public.ai_summaries(id) ON DELETE CASCADE NOT NULL,
    language_code TEXT NOT NULL, -- 'en', 'es', 'fr', etc.
    translated_title TEXT NOT NULL,
    translated_summary TEXT NOT NULL,
    translated_key_points JSONB,
    translation_service TEXT DEFAULT 'openai',
    translation_quality_score NUMERIC(3,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. INDEXES FOR PERFORMANCE
CREATE INDEX idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX idx_ai_summary_usage_user_month ON public.ai_summary_usage(user_id, usage_month);
CREATE INDEX idx_ai_summary_usage_summary_id ON public.ai_summary_usage(summary_id);
CREATE INDEX idx_ad_interactions_user_date ON public.ad_interactions(user_id, interaction_date);
CREATE INDEX idx_summary_translations_summary_lang ON public.ai_summary_translations(original_summary_id, language_code);

-- 7. ENABLE RLS
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_summary_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_summary_translations ENABLE ROW LEVEL SECURITY;

-- 8. HELPER FUNCTIONS (CREATE BEFORE POLICIES)
CREATE OR REPLACE FUNCTION public.reset_monthly_usage()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Reset usage for users whose reset date has passed
    UPDATE public.user_subscriptions
    SET 
        current_month_usage = 0,
        usage_reset_date = usage_reset_date + INTERVAL '1 month',
        updated_at = CURRENT_TIMESTAMP
    WHERE usage_reset_date <= CURRENT_DATE;
    
    -- Log the reset operation
    INSERT INTO public.notifications (user_id, title, message, notification_type)
    SELECT 
        user_id, 
        'Usage Reset',
        'Your monthly AI summary usage has been reset.',
        'system'::public.notification_type
    FROM public.user_subscriptions 
    WHERE usage_reset_date <= CURRENT_DATE + INTERVAL '1 day';
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_summary_limit(user_uuid UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT COALESCE(
    (SELECT monthly_summary_limit 
     FROM public.user_subscriptions 
     WHERE user_id = user_uuid 
     AND status = 'active'::public.subscription_status
     LIMIT 1), 
    10  -- Default free tier limit
);
$$;

CREATE OR REPLACE FUNCTION public.can_generate_summary(user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS(
    SELECT 1 FROM public.user_subscriptions us
    WHERE us.user_id = user_uuid 
    AND us.status = 'active'::public.subscription_status
    AND us.current_month_usage < us.monthly_summary_limit
);
$$;

-- 9. RLS POLICIES (USING PATTERN 2 - SIMPLE USER OWNERSHIP)
CREATE POLICY "users_manage_own_subscriptions"
ON public.user_subscriptions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_usage"
ON public.ai_summary_usage  
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_ad_interactions"
ON public.ad_interactions
FOR ALL
TO authenticated  
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_view_own_translations"
ON public.ai_summary_translations
FOR SELECT
TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.ai_summaries ais
    WHERE ais.id = original_summary_id
));

CREATE POLICY "admin_manage_translations"
ON public.ai_summary_translations
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- 10. AUTOMATIC USER SUBSCRIPTION CREATION TRIGGER
CREATE OR REPLACE FUNCTION public.create_default_subscription()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_subscriptions (user_id, tier, monthly_summary_limit)
    VALUES (NEW.id, 'free'::public.subscription_tier, 10);
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_user_profile_created_subscription
    AFTER INSERT ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.create_default_subscription();

-- 11. USAGE TRACKING TRIGGER
CREATE OR REPLACE FUNCTION public.track_summary_usage()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Increment usage counter
    UPDATE public.user_subscriptions 
    SET current_month_usage = current_month_usage + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = auth.uid();
    
    -- Track the usage
    INSERT INTO public.ai_summary_usage (user_id, summary_id, usage_source)
    VALUES (auth.uid(), NEW.id, 'normal');
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_ai_summary_generated
    AFTER INSERT ON public.ai_summaries
    FOR EACH ROW EXECUTE FUNCTION public.track_summary_usage();

-- 12. MOCK DATA FOR EXISTING USERS
DO $$
DECLARE
    user_record RECORD;
    admin_user_id UUID;
    regular_user_id UUID;
BEGIN
    -- Get existing users
    SELECT id INTO admin_user_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;
    SELECT id INTO regular_user_id FROM public.user_profiles WHERE role = 'member' LIMIT 1;
    
    -- Create subscriptions for existing users (if any exist)
    IF admin_user_id IS NOT NULL THEN
        INSERT INTO public.user_subscriptions (user_id, tier, monthly_summary_limit, current_month_usage)
        VALUES (admin_user_id, 'premium'::public.subscription_tier, 100, 15);
    END IF;
    
    IF regular_user_id IS NOT NULL THEN
        INSERT INTO public.user_subscriptions (user_id, tier, monthly_summary_limit, current_month_usage)  
        VALUES (regular_user_id, 'free'::public.subscription_tier, 10, 3);
        
        -- Add some ad interaction history
        INSERT INTO public.ad_interactions (user_id, ad_type, ad_unit_id, reward_earned)
        VALUES 
            (regular_user_id, 'rewarded_video'::public.ad_type, 'ca-app-pub-test-rewarded', true),
            (regular_user_id, 'rewarded_video'::public.ad_type, 'ca-app-pub-test-rewarded', true);
    END IF;
    
    -- Add sample translations for existing summaries
    INSERT INTO public.ai_summary_translations (
        original_summary_id, 
        language_code, 
        translated_title, 
        translated_summary,
        translated_key_points
    )
    SELECT 
        id,
        'es',
        'Rendimiento sólido del Q4 esperado',
        'El próximo reporte de ganancias de Apple muestra indicadores positivos...',
        '["Ventas del iPhone 15 por encima del pronóstico", "Crecimiento de servicios del 12%"]'::jsonb
    FROM public.ai_summaries 
    LIMIT 1;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data creation failed: %', SQLERRM;
END $$;