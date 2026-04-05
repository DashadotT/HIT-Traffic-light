-- ============================================================
-- SmartIoT Dashboard — Supabase Schema
-- Paste this entire file into Supabase → SQL Editor → Run
-- ============================================================


-- ============================================================
-- 1. TRAFFIC COMMANDS
--    Dashboard sends commands here; ESP32 polls and reads them.
-- ============================================================
CREATE TABLE IF NOT EXISTS traffic_commands (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  command    TEXT NOT NULL,        -- e.g. 'system', 'led', 'builtin_led', 'buzzer'
  value      TEXT NOT NULL,        -- e.g. 'on', 'off', 'red', 'yellow', 'green', 'beep'
  source     TEXT DEFAULT 'dashboard',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast latest-row lookup by ESP32
CREATE INDEX IF NOT EXISTS idx_traffic_commands_id ON traffic_commands (id DESC);


-- ============================================================
-- 2. SENSOR READINGS
--    ESP32 inserts temperature + humidity every 5 seconds.
--    Dashboard reads and charts these in real-time.
-- ============================================================
CREATE TABLE IF NOT EXISTS sensor_readings (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  temperature FLOAT NOT NULL,
  humidity    FLOAT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast time-ordered queries
CREATE INDEX IF NOT EXISTS idx_sensor_readings_created ON sensor_readings (created_at DESC);


-- ============================================================
-- 3. DEVICE STATUS
--    ESP32 updates its online/offline status here.
--    Dashboard subscribes to this for the status bar indicators.
-- ============================================================
CREATE TABLE IF NOT EXISTS device_status (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  device     TEXT UNIQUE NOT NULL,  -- 'esp32-traffic' or 'esp32-dht'
  online     BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed the two device rows so ESP32 can do PUT (upsert) instead of INSERT
INSERT INTO device_status (device, online)
VALUES ('esp32-traffic', false), ('esp32-dht', false)
ON CONFLICT (device) DO NOTHING;


-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Allow anonymous read + write for all three tables.
-- Required for the dashboard and ESP32 to access without login.
-- ============================================================

ALTER TABLE traffic_commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensor_readings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_status    ENABLE ROW LEVEL SECURITY;

-- traffic_commands: anon can read and insert
CREATE POLICY "anon read traffic_commands"
  ON traffic_commands FOR SELECT TO anon USING (true);

CREATE POLICY "anon insert traffic_commands"
  ON traffic_commands FOR INSERT TO anon WITH CHECK (true);

-- sensor_readings: anon can read and insert
CREATE POLICY "anon read sensor_readings"
  ON sensor_readings FOR SELECT TO anon USING (true);

CREATE POLICY "anon insert sensor_readings"
  ON sensor_readings FOR INSERT TO anon WITH CHECK (true);

-- device_status: anon can read, insert, and update
CREATE POLICY "anon read device_status"
  ON device_status FOR SELECT TO anon USING (true);

CREATE POLICY "anon insert device_status"
  ON device_status FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon update device_status"
  ON device_status FOR UPDATE TO anon USING (true);


-- ============================================================
-- REALTIME
-- Enable real-time subscriptions for live dashboard updates.
-- Run these one at a time if needed.
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE sensor_readings;
ALTER PUBLICATION supabase_realtime ADD TABLE device_status;
ALTER PUBLICATION supabase_realtime ADD TABLE traffic_commands;


-- ============================================================
-- OPTIONAL: Auto-cleanup old traffic commands
-- Keeps the table small; ESP32 only needs the latest row.
-- Deletes commands older than 1 hour automatically.
-- ============================================================

CREATE OR REPLACE FUNCTION cleanup_old_commands()
RETURNS void LANGUAGE sql AS $$
  DELETE FROM traffic_commands
  WHERE created_at < NOW() - INTERVAL '1 hour';
$$;

-- Run cleanup manually anytime:
-- SELECT cleanup_old_commands();


-- ============================================================
-- OPTIONAL: Auto-cleanup old sensor readings
-- Keeps only the last 7 days of DHT data.
-- ============================================================

CREATE OR REPLACE FUNCTION cleanup_old_readings()
RETURNS void LANGUAGE sql AS $$
  DELETE FROM sensor_readings
  WHERE created_at < NOW() - INTERVAL '7 days';
$$;

-- Run cleanup manually anytime:
-- SELECT cleanup_old_readings();


-- ============================================================
-- VERIFY: Check all tables exist
-- ============================================================
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('traffic_commands', 'sensor_readings', 'device_status');