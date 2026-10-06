-- Diminta: mengaitkan urutan daun B-Tree dengan kemampuan optimizer berhenti mengurutkan.
-- Dipilih: analisis manual berdasarkan EXPLAIN output.
-- Alternatif: benchmark tambahan; tidak dipilih karena cukup dari Q7-Q9.

-- Lihat apakah ada node "Sort" di EXPLAIN Q8 vs Q9
-- Jika index sudah terurut sesuai ORDER BY, tidak perlu Sort node tambahan
-- Ini menghemat waktu dan memori (tidak perlu materialize semua hasil)

SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'lab6'
  AND indexname IN ('ev_salah_idx', 'ev_benar_idx');