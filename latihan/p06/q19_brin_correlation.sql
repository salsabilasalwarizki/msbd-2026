-- Diminta: memeriksa correlation terjadi_pada dan membandingkan ukuran BRIN dengan B-Tree.
-- Dipilih: pg_stats untuk correlation, pg_relation_size dengan qualified name.
-- Alternatif: hanya ukuran; tidak dipilih karena diminta correlation.

-- Pastikan kedua index ada (buat ulang jika belum ada)
DROP INDEX IF EXISTS lab6.ev_terjadi_pada_brin_idx;
DROP INDEX IF EXISTS lab6.ev_terjadi_pada_idx;

-- BRIN untuk terjadi_pada (data terurut waktu, correlation tinggi)
CREATE INDEX ev_terjadi_pada_brin_idx ON lab6.event_log USING brin (terjadi_pada) WITH (pages_per_range = 128);

-- B-Tree untuk terjadi_pada (untuk perbandingan)
CREATE INDEX ev_terjadi_pada_idx ON lab6.event_log (terjadi_pada DESC);

-- Correlation terjadi_pada
SELECT
  attname AS kolom,
  correlation
FROM pg_stats
WHERE tablename = 'event_log'
  AND schemaname = 'lab6'
  AND attname = 'terjadi_pada';

-- Bandingkan ukuran BRIN dengan B-Tree (gunakan qualified name)
SELECT
  indexname,
  pg_size_pretty(pg_relation_size((schemaname || '.' || indexname)::regclass)) AS ukuran,
  pg_relation_size((schemaname || '.' || indexname)::regclass) AS ukuran_byte
FROM pg_indexes
WHERE schemaname = 'lab6'
  AND indexname IN ('ev_terjadi_pada_brin_idx', 'ev_terjadi_pada_idx');

-- BRIN jauh lebih kecil karena hanya menyimpan min/max per range halaman
-- Efektif jika data terurut (correlation mendekati 1 atau -1)