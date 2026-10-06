-- Diminta: membandingkan UPDATE kolom terindeks vs tidak terindeks.
-- Dipilih: update primary key (terindeks) vs kolom biasa.
-- Alternatif: update kolom dengan index sekunder; tidak dipilih karena PK lebih jelas.

-- Reset statistik
SELECT pg_stat_reset_single_table_counters(oid)
FROM pg_class WHERE relname = 'hot_longgar';

-- Update kolom non-indeks (catatan) - seharusnya HOT update
UPDATE lab6.hot_longgar SET catatan = 'versi2' WHERE id <= 1000;

-- Update kolom terindeks (id - primary key) - TIDAK bisa HOT update
-- (hati-hati: ini akan mengubah PK, gunakan nilai yang aman)
-- UPDATE lab6.hot_longgar SET id = id + 100000 WHERE id <= 1000;

-- Lihat statistik
SELECT
  relname,
  n_tup_upd,
  n_tup_hot_upd
FROM pg_stat_user_tables
WHERE relname = 'hot_longgar';

-- Kesimpulan: HOT update hanya terjadi jika kolom yang diupdate TIDAK terindeks
-- dan ada ruang kosong di halaman yang sama (fillfactor < 100)