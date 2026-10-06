-- Diminta: mengukur query baseline tanpa index.
-- Dipilih: EXPLAIN (ANALYZE, BUFFERS) dengan parallel dimatikan.
-- Alternatif: tanpa BUFFERS; tidak dipilih karena diminta lengkap.

\timing on
SET max_parallel_workers_per_gather = 0;

-- Jalankan 3 kali, catat waktu tercepat dan median
-- Run 1
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;

-- Run 2
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;

-- Run 3
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah
FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC
LIMIT 20;

-- Simpan output ke file
\timing off