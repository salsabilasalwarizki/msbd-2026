-- Diminta: membandingkan ukuran index salah dan benar.
-- Dipilih: pg_relation_size dengan qualified name (schemaname.indexname).
-- Alternatif: pg_indexes_size; tidak dipilih karena kurang spesifik.

-- Pastikan kedua index ada (drop dulu jika ada, lalu buat ulang)
DROP INDEX IF EXISTS lab6.ev_salah_idx;
DROP INDEX IF EXISTS lab6.ev_benar_idx;

-- Buat index dengan urutan "salah" (terjadi_pada, customer_id)
CREATE INDEX ev_salah_idx ON lab6.event_log (terjadi_pada, customer_id);

-- Buat index dengan urutan "benar" (customer_id, terjadi_pada DESC)
CREATE INDEX ev_benar_idx ON lab6.event_log (customer_id, terjadi_pada DESC);

-- Bandingkan ukuran (gunakan qualified name: lab6.ev_salah_idx)
SELECT
  indexname,
  pg_size_pretty(pg_relation_size((schemaname || '.' || indexname)::regclass)) AS ukuran,
  pg_relation_size((schemaname || '.' || indexname)::regclass) AS ukuran_byte
FROM pg_indexes
WHERE schemaname = 'lab6'
  AND indexname IN ('ev_salah_idx', 'ev_benar_idx');

-- Kedua index memiliki kolom yang sama, tetapi urutan berbeda
-- Ukuran bisa berbeda karena: struktur B-Tree, kompresi prefix, distribusi data