-- Diminta: menguji index-only scan sebelum dan sesudah VACUUM.
-- Dipilih: query yang hanya butuh kolom di index + INCLUDE.
-- Alternatif: query dengan kolom di luar index; tidak dipilih karena tidak bisa index-only.

\timing on
SET max_parallel_workers_per_gather = 0;

-- Query yang bisa pakai covering index (semua kolom ada di index)
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, terjadi_pada, jumlah
FROM lab6.event_log
WHERE customer_id = 4211;

-- VACUUM untuk update visibility map
VACUUM (ANALYZE) lab6.event_log;

-- Query ulang setelah VACUUM
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, terjadi_pada, jumlah
FROM lab6.event_log
WHERE customer_id = 4211;

\timing off

-- Perhatikan "Heap Fetches" - seharusnya berkurang setelah VACUUM