-- Diminta: membuat index dengan urutan benar (customer_id, terjadi_pada DESC).
-- Dipilih: B-Tree composite dengan kolom selektif di depan.
-- Alternatif: mempertahankan index salah; tidak dipilih karena kurang optimal.

-- Hapus index salah
DROP INDEX IF EXISTS lab6.ev_salah_idx;

-- Buat index dengan urutan "benar"
CREATE INDEX ev_benar_idx ON lab6.event_log (customer_id, terjadi_pada DESC);

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