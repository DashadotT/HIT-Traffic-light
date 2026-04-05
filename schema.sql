-- ============================================================
--  SmartNode — Supabase SQL Setup (Simple Integer IDs)
--  Run this once in your Supabase SQL Editor
-- ============================================================
-- 1. TRAFFIC STATE (with fixed ID 1)
create table
    if not exists traffic_state (
        id INT primary key default 1,
        phase TEXT default 'off',
        countdown INT default 0,
        updated_at TIMESTAMPTZ default NOW ()
    );

-- Clear any existing data and insert default
delete from traffic_state;

insert into
    traffic_state (id, phase, countdown, updated_at)
values
    (1, 'off', 0, NOW ());

-- 2. TRAFFIC COMMANDS (dashboard → ESP32) - Using SERIAL for auto-increment
create table
    if not exists traffic_commands (
        id SERIAL primary key,
        command TEXT not null,
        payload JSONB default '{}',
        consumed BOOLEAN default false,
        created_at TIMESTAMPTZ default NOW ()
    );

create index IF not exists idx_cmds_consumed on traffic_commands (consumed);

create index IF not exists idx_cmds_created on traffic_commands (created_at);

-- 3. TRAFFIC EVENT LOG - Using SERIAL for auto-increment
create table
    if not exists traffic_logs (
        id SERIAL primary key,
        event TEXT,
        details TEXT,
        phase TEXT,
        timestamp TIMESTAMPTZ default NOW ()
    );

-- 4. DHT11 SENSOR READINGS - Using SERIAL for auto-increment
create table
    if not exists sensor_readings (
        id SERIAL primary key,
        temperature FLOAT,
        humidity FLOAT,
        timestamp TIMESTAMPTZ default NOW ()
    );

-- ============================================================
--  ENABLE REALTIME
-- ============================================================
alter publication supabase_realtime add table traffic_commands;

alter publication supabase_realtime add table traffic_state;

alter publication supabase_realtime add table sensor_readings;

alter publication supabase_realtime add table traffic_logs;

-- ============================================================
--  ROW LEVEL SECURITY (open for ESP32 anon key access)
-- ============================================================
alter table traffic_state ENABLE row LEVEL SECURITY;

alter table traffic_commands ENABLE row LEVEL SECURITY;

alter table traffic_logs ENABLE row LEVEL SECURITY;

alter table sensor_readings ENABLE row LEVEL SECURITY;

drop policy IF exists "open_traffic_state" on traffic_state;

drop policy IF exists "open_traffic_commands" on traffic_commands;

drop policy IF exists "open_traffic_logs" on traffic_logs;

drop policy IF exists "open_sensor_readings" on sensor_readings;

create policy "open_traffic_state" on traffic_state for all using (true)
with
    check (true);

create policy "open_traffic_commands" on traffic_commands for all using (true)
with
    check (true);

create policy "open_traffic_logs" on traffic_logs for all using (true)
with
    check (true);

create policy "open_sensor_readings" on sensor_readings for all using (true)
with
    check (true);

-- ============================================================
--  OPTIONAL: Create a view for easy monitoring
-- ============================================================
create
or replace view traffic_status as
select
    ts.phase,
    ts.countdown,
    ts.updated_at as state_updated,
    COUNT(tc.id) filter (
        where
            tc.consumed = false
    ) as pending_commands
from
    traffic_state ts
    left join traffic_commands tc on tc.consumed = false
group by
    ts.id,
    ts.phase,
    ts.countdown,
    ts.updated_at;