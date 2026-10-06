-- Diminta: membuat index dengan urutan kolom salah (terjadi_pada, customer_id).
-- Dipilih: B-Tree composite index dengan urutan yang tidak optimal.
-- Alternatif: index single column; tidak dipilih karena diminta composite.

-- Buat index dengan urutan "salah"
CREATE INDEX ev_salah_idx ON lab6.event_log (terjadi_pada, customer_id);

-- Ukur query (3 kali)
\timing on
SET max_parallel_workers_per_gather = 0;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;

\timing off