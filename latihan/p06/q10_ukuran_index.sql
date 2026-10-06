-- Diminta: membandingkan ukuran index salah dan benar.
-- Dipilih: pg_relation_size pada index.
-- Alternatif: pg_indexes_size; tidak dipilih karena kurang spesifik.

-- Buat index hanya jika belum ada agar tidak error saat di-run ulang
CREATE INDEX IF NOT EXISTS ev_salah_idx ON lab6.event_log (terjadi_pada, customer_id);
CREATE INDEX IF NOT EXISTS ev_benar_idx ON lab6.event_log (customer_id, terjadi_pada);

SELECT
  indexname,
  pg_size_pretty(pg_relation_size(('lab6.' || indexname)::regclass)) AS ukuran,
  pg_relation_size(('lab6.' || indexname)::regclass) AS ukuran_byte
FROM pg_indexes
WHERE schemaname = 'lab6'
  AND indexname IN ('ev_salah_idx', 'ev_benar_idx');