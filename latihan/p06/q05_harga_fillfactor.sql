-- Diminta: membandingkan ukuran kedua tabel setelah UPDATE.
-- Dipilih: pg_total_relation_size untuk ukuran lengkap.
-- Alternatif: pg_relation_size saja; tidak dipilih karena kurang lengkap.

SELECT
  relname,
  pg_size_pretty(pg_total_relation_size(oid)) AS ukuran_total,
  pg_size_pretty(pg_relation_size(oid)) AS ukuran_heap,
  pg_relation_size(oid) AS ukuran_heap_byte
FROM pg_class
WHERE relname IN ('hot_penuh', 'hot_longgar');

-- Tabel dengan fillfactor 80 akan lebih besar karena ada ruang kosong (20%)
-- Ruang ini "dibayar" untuk memungkinkan HOT update saat kolom non-indeks diupdate