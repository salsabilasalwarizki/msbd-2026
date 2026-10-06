-- Diminta: menguji keanggotaan tags dengan @>.
-- Dipilih: query dengan dan tanpa GIN (drop index sementara).
-- Alternatif: hanya dengan GIN; tidak dipilih karena diminta perbandingan.

\timing on
SET max_parallel_workers_per_gather = 0;

-- Dengan GIN index
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, tags
FROM lab6.event_log
WHERE tags @> ARRAY['kanal:1'];

-- Bandingkan dengan seq scan (disable index scan sementara)
SET enable_indexscan = off;
SET enable_bitmapscan = off;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, tags
FROM lab6.event_log
WHERE tags @> ARRAY['kanal:1'];

-- Reset
RESET enable_indexscan;
RESET enable_bitmapscan;

\timing off