CREATE SCHEMA IF NOT EXISTS stocks;

CREATE TABLE stocks.stocks (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticker          TEXT NOT NULL,
    company_name    TEXT NOT NULL,
    exchange        TEXT NOT NULL,
    exchange_token  BIGINT,
    instrument_token BIGINT,
    deleted_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(exchange, ticker)
);

CREATE INDEX idx_stocks_ticker ON stocks.stocks(ticker);
CREATE INDEX idx_stocks_exchange_ticker ON stocks.stocks(exchange, ticker);
CREATE INDEX idx_stocks_exchange_token ON stocks.stocks(exchange_token);
CREATE INDEX idx_stocks_instrument_token ON stocks.stocks(instrument_token);

CREATE TRIGGER trg_stocks_updated
BEFORE UPDATE ON stocks.stocks
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TABLE stocks.stock_embeddings (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id        UUID NOT NULL REFERENCES stocks.stocks(id) ON DELETE CASCADE,
    model           TEXT NOT NULL,
    embedding       vector(1536) NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_stock_embeddings_stock_id ON stocks.stock_embeddings(stock_id);
CREATE INDEX idx_stock_embeddings_model ON stocks.stock_embeddings(model);
CREATE INDEX idx_stock_embeddings_vector ON stocks.stock_embeddings
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE TABLE stocks.company_profiles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id        UUID NOT NULL REFERENCES stocks.stocks(id) ON DELETE CASCADE,
    description     TEXT,
    mg_industry     TEXT,
    isin            TEXT,
    officers        JSONB,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_stock_profile UNIQUE (stock_id)
);

CREATE INDEX idx_company_profiles_stock_id ON stocks.company_profiles(stock_id);
CREATE INDEX idx_company_profiles_isin ON stocks.company_profiles(isin);
CREATE INDEX idx_company_profiles_officers_gin ON stocks.company_profiles
    USING gin (officers jsonb_path_ops);

CREATE TABLE stocks.peer_companies (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id        UUID NOT NULL REFERENCES stocks.stocks(id) ON DELETE CASCADE,
    peer_ticker_id  TEXT,       
    company_name    TEXT,
    price           NUMERIC,
    percent_change  NUMERIC,
    net_change      NUMERIC,
    market_cap      NUMERIC,
    pe_ratio        NUMERIC,
    pb_ratio        NUMERIC,
    roe_5y_avg      NUMERIC,
    roe_ttm         NUMERIC,
    debt_to_equity  NUMERIC,
    net_margin_5y   NUMERIC,
    net_margin_ttm  NUMERIC,
    dividend_yield  NUMERIC,
    shares_out      NUMERIC,
    overall_rating  TEXT,
    yhigh           NUMERIC,
    ylow            NUMERIC,
    image_url       TEXT,
    language_support TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_peer_per_stock UNIQUE (stock_id, peer_ticker_id)
);

CREATE INDEX idx_peer_companies_stock_id ON stocks.peer_companies(stock_id);
CREATE INDEX idx_peer_companies_peer_ticker ON stocks.peer_companies(peer_ticker_id);
CREATE INDEX idx_peer_companies_market_cap ON stocks.peer_companies(market_cap DESC);

CREATE TABLE stocks.quarter_results (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id        UUID NOT NULL REFERENCES stocks.stocks(id) ON DELETE CASCADE,
    quarter_date    DATE NOT NULL,
    metric_name     TEXT NOT NULL,
    metric_value    NUMERIC,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_quarter_metric UNIQUE (stock_id, quarter_date, metric_name)
);

CREATE INDEX idx_quarter_results_stock_quarter ON stocks.quarter_results(stock_id, quarter_date);
CREATE INDEX idx_quarter_results_metric ON stocks.quarter_results(metric_name);

CREATE TABLE stocks.yoy_results (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id        UUID NOT NULL REFERENCES stocks.stocks(id) ON DELETE CASCADE,
    period_label    TEXT NOT NULL,
    period_date     DATE,
    metric_name     TEXT NOT NULL,
    metric_value    NUMERIC,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_yoy_metric UNIQUE (stock_id, period_label, metric_name)
);

CREATE INDEX idx_yoy_results_stock_period ON stocks.yoy_results(stock_id, period_label);
CREATE INDEX idx_yoy_results_metric ON stocks.yoy_results(metric_name);

CREATE TABLE stocks.balance_sheet (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id        UUID NOT NULL REFERENCES stocks.stocks(id) ON DELETE CASCADE,
    period_label    TEXT NOT NULL,
    period_date     DATE,
    metric_name     TEXT NOT NULL,
    metric_value    NUMERIC,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_balance_sheet_metric UNIQUE (stock_id, period_label, metric_name)
);

CREATE INDEX idx_balance_sheet_stock_period ON stocks.balance_sheet(stock_id, period_label);
CREATE INDEX idx_balance_sheet_metric ON stocks.balance_sheet(metric_name);

CREATE TABLE stocks.cashflow (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id        UUID NOT NULL REFERENCES stocks.stocks(id) ON DELETE CASCADE,
    period_label    TEXT NOT NULL,
    period_date     DATE,
    metric_name     TEXT NOT NULL,
    metric_value    NUMERIC,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_cashflow_metric UNIQUE (stock_id, period_label, metric_name)
);

CREATE INDEX idx_cashflow_stock_period ON stocks.cashflow(stock_id, period_label);
CREATE INDEX idx_cashflow_metric ON stocks.cashflow(metric_name);

CREATE TABLE stocks.ratios (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id        UUID NOT NULL REFERENCES stocks.stocks(id) ON DELETE CASCADE,
    period_label    TEXT NOT NULL,
    period_date     DATE,
    metric_name     TEXT NOT NULL,
    metric_value    NUMERIC,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_ratio_metric UNIQUE (stock_id, period_label, metric_name)
);

CREATE INDEX idx_ratios_stock_period ON stocks.ratios(stock_id, period_label);
CREATE INDEX idx_ratios_metric ON stocks.ratios(metric_name);

CREATE TABLE stocks.shareholding_pattern_quarterly (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stock_id        UUID NOT NULL REFERENCES stocks.stocks(id) ON DELETE CASCADE,
    period_label    TEXT NOT NULL,
    period_date     DATE,
    metric_name     TEXT NOT NULL,
    metric_value    NUMERIC,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_shareholding_metric UNIQUE (stock_id, period_label, metric_name)
);

CREATE INDEX idx_shareholding_quarterly_stock_period ON stocks.shareholding_pattern_quarterly(stock_id, period_label);
CREATE INDEX idx_shareholding_quarterly_metric ON stocks.shareholding_pattern_quarterly(metric_name);
