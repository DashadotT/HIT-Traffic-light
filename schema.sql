-- ============================================================
--  SmartNode — Supabase SQL Setup
--  Run this once in your Supabase SQL Editor
-- ============================================================
-- 1. TRAFFIC STATE
CREATE TABLE
    IF NOT EXISTS traffic_state (
        id INT PRIMARY KEY DEFAULT 1,
        phase TEXT DEFAULT 'off',
        countdown INT DEFAULT 0,
        updated_at TIMESTAMPTZ DEFAULT NOW ()
    );

INSERT INTO
    traffic_state (id, phase, countdown)
VALUES
    (1, 'off', 0) ON CONFLICT (id) DO NOTHING;

-- 2. TRAFFIC COMMANDS (dashboard → ESP32)
CREATE TABLE
    IF NOT EXISTS traffic_commands (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        command TEXT NOT NULL,
        payload JSONB DEFAULT '{}',
        consumed BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW ()
    );

CREATE INDEX IF NOT EXISTS idx_cmds_consumed ON traffic_commands (consumed);

-- 3. TRAFFIC EVENT LOG
CREATE TABLE
    IF NOT EXISTS traffic_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        event TEXT,
        details TEXT,
        phase TEXT,
        timestamp TIMESTAMPTZ DEFAULT NOW ()
    );

-- 4. DHT11 SENSOR READINGS
CREATE TABLE
    IF NOT EXISTS sensor_readings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
        temperature FLOAT,
        humidity FLOAT,
        timestamp TIMESTAMPTZ DEFAULT NOW ()
    );

-- ============================================================
--  ENABLE REALTIME
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE traffic_commands;

ALTER PUBLICATION supabase_realtime ADD TABLE traffic_state;

ALTER PUBLICATION supabase_realtime ADD TABLE sensor_readings;

-- ============================================================
--  ROW LEVEL SECURITY (open for ESP32 anon key access)
-- ============================================================
ALTER TABLE traffic_state ENABLE ROW LEVEL SECURITY;

ALTER TABLE traffic_commands ENABLE ROW LEVEL SECURITY;

ALTER TABLE traffic_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "open_traffic_state" ON traffic_state FOR ALL USING (true)
WITH
    CHECK (true);

CREATE POLICY "open_traffic_commands" ON traffic_commands FOR ALL USING (true)
WITH
    CHECK (true);

CREATE POLICY "open_traffic_logs" ON traffic_logs FOR ALL USING (true)
WITH
    CHECK (true);

CREATE POLICY "open_sensor_readings" ON sensor_readings FOR ALL USING (true)
WITH
    CHECK (true);