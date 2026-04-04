CREATE TABLE
    traffic_commands (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        action TEXT NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW ()
    );

CREATE TABLE
    traffic_status (
        id INT PRIMARY KEY DEFAULT 1,
        wifi_connected BOOLEAN DEFAULT FALSE,
        last_seen TIMESTAMPTZ DEFAULT NOW ()
    );

CREATE TABLE
    sensor_readings (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        temperature REAL NOT NULL,
        humidity REAL NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW ()
    );

CREATE TABLE
    device_status (
        id INT PRIMARY KEY DEFAULT 1,
        wifi_connected BOOLEAN DEFAULT FALSE,
        last_seen TIMESTAMPTZ DEFAULT NOW ()
    );

ALTER TABLE traffic_commands ENABLE ROW LEVEL SECURITY;

ALTER TABLE traffic_status ENABLE ROW LEVEL SECURITY;

ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;

ALTER TABLE device_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "allow_all" ON traffic_commands FOR ALL USING (true)
WITH
    CHECK (true);

CREATE POLICY "allow_all" ON traffic_status FOR ALL USING (true)
WITH
    CHECK (true);

CREATE POLICY "allow_all" ON sensor_readings FOR ALL USING (true)
WITH
    CHECK (true);

CREATE POLICY "allow_all" ON device_status FOR ALL USING (true)
WITH
    CHECK (true);