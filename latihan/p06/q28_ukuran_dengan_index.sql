-- Diminta: membandingkan ukuran total tabel tanpa index dan dengan 5 index.
-- Dipilih: pg_total_relation_size.
-- Alternatif: pg_relation_size saja; tidak dipilih karena tidak mencakup index.

SELECT
  relname,
  pg_size_pretty(pg_total_relation_size(oid)) AS ukuran_total,
  pg_size_pretty(pg_relation_size(oid)) AS ukuran_heap,
  pg_size_pretty(pg_indexes_size(oid)) AS ukuran_index
FROM pg_class
WHERE relname IN ('insert_test_no_idx', 'insert_test_with_idx');