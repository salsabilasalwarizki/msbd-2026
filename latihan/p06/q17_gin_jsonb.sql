-- Diminta: menguji query payload @> '{"promo": true}'.
-- Dipilih: EXPLAIN ANALYZE dengan BUFFERS, 3 kali pengulangan.
-- Alternatif: hanya 1 kali; tidak dipilih karena diminta 3 kali.

-- Pastikan index GIN ada (buat ulang jika belum ada)
DROP INDEX IF EXISTS lab6.ev_payload_gin_idx;
CREATE INDEX ev_payload_gin_idx ON lab6.event_log USING gin (payload jsonb_path_ops);

\timing on
SET max_parallel_workers_per_gather = 0;

-- Jalankan 3 kali
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, payload
FROM lab6.event_log
WHERE payload @> '{"promo": true}';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, payload
FROM lab6.event_log
WHERE payload @> '{"promo": true}';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, payload
FROM lab6.event_log
WHERE payload @> '{"promo": true}';

\timing off

-- Bandingkan ukuran GIN index dengan heap
SELECT
  indexname,
  pg_size_pretty(pg_relation_size((schemaname || '.' || indexname)::regclass)) AS ukuran
FROM pg_indexes
WHERE schemaname = 'lab6'
  AND indexname = 'ev_payload_gin_idx';