-- Diminta: membandingkan ukuran partial index dengan index polos.
-- Dipilih: pg_relation_size dengan qualified name (schemaname.indexname).
-- Alternatif: pg_indexes_size; tidak dipilih karena kurang spesifik.

-- Pastikan index ada (buat ulang jika belum ada)
DROP INDEX IF EXISTS lab6.ev_gagal_idx;
DROP INDEX IF EXISTS lab6.ev_terjadi_pada_idx;

-- Partial index (hanya untuk status = 'GAGAL')
CREATE INDEX ev_gagal_idx ON lab6.event_log (terjadi_pada DESC) WHERE status = 'GAGAL';

-- Index polos pada terjadi_pada untuk perbandingan
CREATE INDEX ev_terjadi_pada_idx ON lab6.event_log (terjadi_pada DESC);

-- Bandingkan ukuran (gunakan qualified name)
SELECT
  indexname,
  pg_size_pretty(pg_relation_size((schemaname || '.' || indexname)::regclass)) AS ukuran,
  pg_relation_size((schemaname || '.' || indexname)::regclass) AS ukuran_byte
FROM pg_indexes
WHERE schemaname = 'lab6'
  AND indexname IN ('ev_gagal_idx', 'ev_terjadi_pada_idx');

-- Hitung persentase penghematan
-- (ukuran_polos - ukuran_partial) / ukuran_polos * 100