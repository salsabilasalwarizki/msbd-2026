-- Diminta: membandingkan index INCLUDE dengan index tiga kolom biasa.
-- Dipilih: buat index tiga kolom (customer_id, terjadi_pada, jumlah) untuk perbandingan.
-- Alternatif: hanya INCLUDE; tidak dipilih karena diminta perbandingan.

-- Buat index tiga kolom biasa
CREATE INDEX ev_tiga_kolom_idx ON lab6.event_log (customer_id, terjadi_pada, jumlah);

-- Bandingkan ukuran
SELECT
  indexname,
  pg_size_pretty(pg_relation_size(indexname::regclass)) AS ukuran,
  pg_relation_size(indexname::regclass) AS ukuran_byte
FROM pg_indexes
WHERE schemaname = 'lab6'
  AND indexname IN ('ev_cover_idx', 'ev_tiga_kolom_idx');

-- Bandingkan rencana eksekusi
\timing on
SET max_parallel_workers_per_gather = 0;

EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, terjadi_pada, jumlah
FROM lab6.event_log
WHERE customer_id = 4211;

\timing off