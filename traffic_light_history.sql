create table public.traffic_light_history (
  id bigserial not null,
  state text null,
  countdown integer null,
  mode text null,
  timestamp bigint null,
  constraint traffic_light_history_pkey primary key (id)
) TABLESPACE pg_default;