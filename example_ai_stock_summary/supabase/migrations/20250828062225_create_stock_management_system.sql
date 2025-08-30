-- Location: supabase/migrations/20250828062225_create_stock_management_system.sql
-- Schema Analysis: Fresh project - no existing tables detected
-- Integration Type: complete new schema
-- Module: Stock Management System with Authentication

-- 1. Extensions & Types
CREATE TYPE public.user_role AS ENUM ('admin', 'manager', 'member');
CREATE TYPE public.alert_type AS ENUM ('price_above', 'price_below', 'volume_spike', 'news_alert');
CREATE TYPE public.notification_type AS ENUM ('price_alert', 'system', 'market_news', 'ai_insight');
CREATE TYPE public.portfolio_type AS ENUM ('individual', 'retirement', 'business');

-- 2. Core Tables
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'member'::public.user_role,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.stocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    symbol TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    exchange TEXT NOT NULL,
    sector TEXT,
    industry TEXT,
    market_cap DECIMAL(20,2),
    description TEXT,
    website_url TEXT,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.stock_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    current_price DECIMAL(10,2) NOT NULL,
    open_price DECIMAL(10,2),
    high_price DECIMAL(10,2),
    low_price DECIMAL(10,2),
    previous_close DECIMAL(10,2),
    volume BIGINT,
    market_cap DECIMAL(20,2),
    pe_ratio DECIMAL(8,2),
    eps DECIMAL(8,2),
    dividend_yield DECIMAL(5,2),
    fifty_two_week_high DECIMAL(10,2),
    fifty_two_week_low DECIMAL(10,2),
    price_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.portfolios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    portfolio_type public.portfolio_type DEFAULT 'individual'::public.portfolio_type,
    total_value DECIMAL(12,2) DEFAULT 0,
    total_gain_loss DECIMAL(12,2) DEFAULT 0,
    total_gain_loss_percentage DECIMAL(5,2) DEFAULT 0,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.portfolio_holdings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id UUID REFERENCES public.portfolios(id) ON DELETE CASCADE,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    quantity DECIMAL(12,4) NOT NULL,
    average_cost DECIMAL(10,2) NOT NULL,
    current_value DECIMAL(12,2),
    total_gain_loss DECIMAL(12,2),
    gain_loss_percentage DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.watchlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'My Watchlist',
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.watchlist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    watchlist_id UUID REFERENCES public.watchlists(id) ON DELETE CASCADE,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(watchlist_id, stock_id)
);

CREATE TABLE public.price_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    alert_type public.alert_type NOT NULL,
    target_price DECIMAL(10,2) NOT NULL,
    is_triggered BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.ai_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    sentiment TEXT CHECK (sentiment IN ('bullish', 'bearish', 'neutral')),
    confidence_score DECIMAL(3,2),
    key_points JSONB,
    generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    notification_type public.notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE SET NULL,
    alert_id UUID REFERENCES public.price_alerts(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.market_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    insight_type TEXT NOT NULL,
    icon_name TEXT,
    color_hex TEXT,
    stock_symbols TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_stocks_symbol ON public.stocks(symbol);
CREATE INDEX idx_stock_prices_stock_id ON public.stock_prices(stock_id);
CREATE INDEX idx_stock_prices_date ON public.stock_prices(price_date);
CREATE INDEX idx_portfolios_user_id ON public.portfolios(user_id);
CREATE INDEX idx_portfolio_holdings_portfolio_id ON public.portfolio_holdings(portfolio_id);
CREATE INDEX idx_portfolio_holdings_stock_id ON public.portfolio_holdings(stock_id);
CREATE INDEX idx_watchlists_user_id ON public.watchlists(user_id);
CREATE INDEX idx_watchlist_items_watchlist_id ON public.watchlist_items(watchlist_id);
CREATE INDEX idx_price_alerts_user_id ON public.price_alerts(user_id);
CREATE INDEX idx_price_alerts_stock_id ON public.price_alerts(stock_id);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at);
CREATE INDEX idx_ai_summaries_stock_id ON public.ai_summaries(stock_id);

-- 4. RLS Setup
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio_holdings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_insights ENABLE ROW LEVEL SECURITY;

-- 5. Helper Functions (must be before RLS policies)
CREATE OR REPLACE FUNCTION public.is_admin_from_auth()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND (au.raw_user_meta_data->>'role' = 'admin' 
         OR au.raw_app_meta_data->>'role' = 'admin')
)
$$;

-- 6. RLS Policies
-- Pattern 1: Core user table
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 4: Public read, private write for stocks
CREATE POLICY "public_can_read_stocks"
ON public.stocks
FOR SELECT
TO public
USING (true);

CREATE POLICY "admin_manage_stocks"
ON public.stocks
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- Pattern 4: Public read for stock prices
CREATE POLICY "public_can_read_stock_prices"
ON public.stock_prices
FOR SELECT
TO public
USING (true);

CREATE POLICY "admin_manage_stock_prices"
ON public.stock_prices
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- Pattern 2: Simple user ownership
CREATE POLICY "users_manage_own_portfolios"
ON public.portfolios
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_portfolio_holdings"
ON public.portfolio_holdings
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.portfolios p
        WHERE p.id = portfolio_id AND p.user_id = auth.uid()
    )
);

CREATE POLICY "users_manage_own_watchlists"
ON public.watchlists
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_watchlist_items"
ON public.watchlist_items
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.watchlists w
        WHERE w.id = watchlist_id AND w.user_id = auth.uid()
    )
);

CREATE POLICY "users_manage_own_price_alerts"
ON public.price_alerts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_notifications"
ON public.notifications
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public read for AI summaries and market insights
CREATE POLICY "public_can_read_ai_summaries"
ON public.ai_summaries
FOR SELECT
TO public
USING (true);

CREATE POLICY "admin_manage_ai_summaries"
ON public.ai_summaries
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

CREATE POLICY "public_can_read_market_insights"
ON public.market_insights
FOR SELECT
TO public
USING (true);

CREATE POLICY "admin_manage_market_insights"
ON public.market_insights
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- 7. Triggers and Functions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'member')::public.user_role
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. Mock Data
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    user_uuid UUID := gen_random_uuid();
    aapl_stock_id UUID := gen_random_uuid();
    googl_stock_id UUID := gen_random_uuid();
    msft_stock_id UUID := gen_random_uuid();
    tsla_stock_id UUID := gen_random_uuid();
    amzn_stock_id UUID := gen_random_uuid();
    portfolio_id UUID := gen_random_uuid();
    watchlist_id UUID := gen_random_uuid();
    insight1_id UUID := gen_random_uuid();
    insight2_id UUID := gen_random_uuid();
    insight3_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@stockai.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Stock Admin", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'user@stockai.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Investor", "role": "member"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Insert stocks
    INSERT INTO public.stocks (id, symbol, name, exchange, sector, industry, market_cap, description) VALUES
        (aapl_stock_id, 'AAPL', 'Apple Inc.', 'NASDAQ', 'Technology', 'Consumer Electronics', 3000000000000, 'Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide.'),
        (googl_stock_id, 'GOOGL', 'Alphabet Inc.', 'NASDAQ', 'Technology', 'Internet Content & Information', 1800000000000, 'Alphabet Inc. provides online advertising services in the United States, Europe, the Middle East, Africa, the Asia-Pacific, Canada, and Latin America.'),
        (msft_stock_id, 'MSFT', 'Microsoft Corporation', 'NASDAQ', 'Technology', 'Software', 2800000000000, 'Microsoft Corporation develops, licenses, and supports software, services, devices, and solutions worldwide.'),
        (tsla_stock_id, 'TSLA', 'Tesla, Inc.', 'NASDAQ', 'Consumer Cyclical', 'Auto Manufacturers', 800000000000, 'Tesla, Inc. designs, develops, manufactures, leases, and sells electric vehicles, and energy generation and storage systems.'),
        (amzn_stock_id, 'AMZN', 'Amazon.com, Inc.', 'NASDAQ', 'Consumer Cyclical', 'Internet Retail', 1500000000000, 'Amazon.com, Inc. engages in the retail sale of consumer products and subscriptions in North America and internationally.');

    -- Insert current stock prices
    INSERT INTO public.stock_prices (stock_id, current_price, open_price, high_price, low_price, previous_close, volume, market_cap, pe_ratio, eps, dividend_yield, fifty_two_week_high, fifty_two_week_low, price_date) VALUES
        (aapl_stock_id, 175.84, 173.50, 176.20, 172.80, 173.53, 45000000, 2750000000000, 28.5, 6.16, 0.52, 199.62, 164.08, CURRENT_DATE),
        (googl_stock_id, 2847.92, 2860.00, 2875.30, 2835.60, 2883.16, 1200000, 1800000000000, 25.8, 110.21, 0.00, 3030.93, 2193.62, CURRENT_DATE),
        (msft_stock_id, 378.85, 376.20, 382.40, 375.10, 375.40, 25000000, 2810000000000, 32.1, 11.79, 0.68, 384.30, 309.45, CURRENT_DATE),
        (tsla_stock_id, 248.50, 252.00, 255.80, 245.30, 251.95, 78000000, 790000000000, 62.5, 3.98, 0.00, 407.36, 138.80, CURRENT_DATE),
        (amzn_stock_id, 3342.88, 3350.20, 3368.94, 3330.12, 3278.50, 3500000, 1700000000000, 49.8, 67.12, 0.00, 3773.08, 2671.45, CURRENT_DATE);

    -- Create default portfolio for user
    INSERT INTO public.portfolios (id, user_id, name, portfolio_type, total_value, total_gain_loss, total_gain_loss_percentage, is_default) VALUES
        (portfolio_id, user_uuid, 'My Portfolio', 'individual', 125847.32, 2847.32, 2.31, true);

    -- Create portfolio holdings
    INSERT INTO public.portfolio_holdings (portfolio_id, stock_id, quantity, average_cost, current_value, total_gain_loss, gain_loss_percentage) VALUES
        (portfolio_id, aapl_stock_id, 100, 165.30, 17584.00, 1254.00, 7.59),
        (portfolio_id, googl_stock_id, 20, 2750.00, 56958.40, 1958.40, 3.56),
        (portfolio_id, msft_stock_id, 50, 360.20, 18942.50, 932.50, 5.18),
        (portfolio_id, tsla_stock_id, 30, 260.00, 7455.00, -345.00, -4.42),
        (portfolio_id, amzn_stock_id, 8, 3100.00, 26743.04, 1943.04, 7.85);

    -- Create default watchlist
    INSERT INTO public.watchlists (id, user_id, name, is_default) VALUES
        (watchlist_id, user_uuid, 'My Watchlist', true);

    -- Add stocks to watchlist
    INSERT INTO public.watchlist_items (watchlist_id, stock_id, notes) VALUES
        (watchlist_id, aapl_stock_id, 'Strong Q4 expected'),
        (watchlist_id, googl_stock_id, 'AI integration promising'),
        (watchlist_id, msft_stock_id, 'Azure growth solid'),
        (watchlist_id, tsla_stock_id, 'Production challenges'),
        (watchlist_id, amzn_stock_id, 'AWS expansion');

    -- Create price alerts
    INSERT INTO public.price_alerts (user_id, stock_id, alert_type, target_price, is_active) VALUES
        (user_uuid, aapl_stock_id, 'price_above', 180.00, true),
        (user_uuid, tsla_stock_id, 'price_below', 240.00, true);

    -- Create AI summaries
    INSERT INTO public.ai_summaries (stock_id, title, summary, sentiment, confidence_score, key_points) VALUES
        (aapl_stock_id, 'Strong Q4 Performance Expected', 
         'Apple upcoming earnings report shows positive indicators with iPhone 15 sales exceeding expectations and services revenue growing steadily. The company is benefiting from strong demand in emerging markets and continued expansion of its services ecosystem.',
         'bullish', 0.85, 
         '["iPhone 15 sales above forecast", "Services revenue up 12%", "Strong emerging market demand", "App Store growth solid"]'::jsonb),
        (googl_stock_id, 'AI Integration Driving Growth',
         'Google integration of AI across its product suite is showing promising results, with advertising revenue benefiting from improved targeting capabilities. The company cloud business continues to gain market share against competitors.',
         'bullish', 0.78,
         '["AI-powered ads performing well", "Cloud revenue up 28%", "Search market share stable", "Regulatory concerns persist"]'::jsonb),
        (tsla_stock_id, 'Production Challenges Ahead',
         'Tesla faces potential production bottlenecks in Q1 2024 due to supply chain constraints, but long-term outlook remains positive with new factory expansions and growing EV market demand.',
         'neutral', 0.65,
         '["Supply chain issues", "New factory construction", "EV demand growing", "Competition intensifying"]'::jsonb);

    -- Create market insights
    INSERT INTO public.market_insights (id, title, description, insight_type, icon_name, color_hex, stock_symbols, is_active) VALUES
        (insight1_id, 'Today''s Movers', '5 stocks with significant price changes', 'price_movement', 'trending_up', '#10B981', ARRAY['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN'], true),
        (insight2_id, 'AI Insights Available', '3 new AI summaries ready to view', 'ai_analysis', 'psychology', '#4A90E2', ARRAY['AAPL', 'GOOGL', 'TSLA'], true),
        (insight3_id, 'Recent Alerts', '2 price alerts triggered today', 'alerts', 'notifications_active', '#FF6B35', ARRAY['AAPL', 'TSLA'], true);

    -- Create sample notifications
    INSERT INTO public.notifications (user_id, notification_type, title, message, stock_id, is_read) VALUES
        (user_uuid, 'ai_insight', 'New AI Summary Available', 'Apple Inc. (AAPL) analysis is ready with bullish outlook', aapl_stock_id, false),
        (user_uuid, 'market_news', 'Market Update', 'Technology sector showing strong performance today', null, false),
        (user_uuid, 'price_alert', 'Price Alert Triggered', 'Tesla (TSLA) has dropped below your target price of $250', tsla_stock_id, true);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;