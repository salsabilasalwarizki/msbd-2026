-- Diminta: membuat extended statistics untuk wilayah-kota.
-- Dipilih: dependencies dan ndistinct.
-- Alternatif: hanya satu jenis; tidak dipilih karena diminta keduanya.

-- Extended statistics untuk dependencies (kota bergantung pada wilayah)
CREATE STATISTICS lab6.wilayah_kota_deps (dependencies) ON wilayah, kota FROM lab6.event_log;

-- Extended statistics untuk ndistinct (kombinasi unik wilayah-kota)
CREATE STATISTICS lab6.wilayah_kota_ndist (ndistinct) ON wilayah, kota FROM lab6.event_log;

-- ANALYZE untuk mengupdate statistik
ANALYZE lab6.event_log;

-- Query dengan kombinasi wilayah-kota
\timing on
SET max_parallel_workers_per_gather = 0;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, wilayah, kota
FROM lab6.event_log
WHERE wilayah = 'JABAR' AND kota = 'JABAR-1';

\timing off

-- Bandingkan estimasi baris dengan kenyataan
SELECT
  schemaname,
  tablename,
  attname,
  n_distinct,
  correlation
FROM pg_stats
WHERE tablename = 'event_log'
  AND schemaname = 'lab6'
  AND attname IN ('wilayah', 'kota');

-- Lihat extended statistics
SELECT
  stxname,
  stxkeys,
  stxkind
FROM pg_statistic_ext
WHERE stxnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'lab6');