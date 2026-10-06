-- Setup index GIN dan BRIN

-- GIN untuk JSONB (path_ops lebih kecil dan cepat untuk @>)
CREATE INDEX ev_payload_gin_idx ON lab6.event_log USING gin (payload jsonb_path_ops);

-- GIN untuk array tags
CREATE INDEX ev_tags_gin_idx ON lab6.event_log USING gin (tags);

-- BRIN untuk terjadi_pada (data terurut waktu, correlation tinggi)
CREATE INDEX ev_terjadi_pada_brin_idx ON lab6.event_log USING brin (terjadi_pada) WITH (pages_per_range = 128);