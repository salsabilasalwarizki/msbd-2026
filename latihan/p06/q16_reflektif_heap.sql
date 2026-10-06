-- Diminta: menjelaskan mengapa Heap Fetches berubah setelah VACUUM.
-- Dipilih: analisis visibility map.
-- Alternatif: tidak ada; ini pertanyaan konseptual.

-- VACUUM mengupdate visibility map, menandai halaman yang semua tuplenya visible
-- Index-only scan bisa skip heap fetch jika halaman fully visible
-- Tanpa VACUUM, PostgreSQL harus cek heap untuk memastikan tuple visible

SELECT
  relname,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables
WHERE relname = 'event_log';