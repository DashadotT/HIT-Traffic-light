create table public.traffic_light (
  id bigserial not null,
  state text null,
  countdown integer null,
  system_enabled boolean null,
  manual_mode boolean null,
  manual_led text null,
  timestamp bigint null,
  constraint traffic_light_pkey primary key (id)
) TABLESPACE pg_default;

