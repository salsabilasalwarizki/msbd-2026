-- Diminta: membandingkan HOT update pada fillfactor 100 vs 80.
-- Dipilih: dua tabel dengan fillfactor berbeda, update kolom non-indeks.
-- Alternatif: satu tabel dengan ALTER; tidak dipilih karena perlu perbandingan side-by-side.

-- Buat tabel dengan fillfactor 100 (penuh)
CREATE TABLE lab6.hot_penuh (
  id serial PRIMARY KEY,
  catatan text
) WITH (fillfactor = 100);

-- Buat tabel dengan fillfactor 80 (longgar)
CREATE TABLE lab6.hot_longgar (
  id serial PRIMARY KEY,
  catatan text
) WITH (fillfactor = 80);

-- Isi 10000 baris
INSERT INTO lab6.hot_penuh (catatan) SELECT 'awal' FROM generate_series(1, 10000);
INSERT INTO lab6.hot_longgar (catatan) SELECT 'awal' FROM generate_series(1, 10000);

-- Reset statistik
SELECT pg_stat_reset_single_table_counters(oid)
FROM pg_class WHERE relname IN ('hot_penuh', 'hot_longgar');

-- Update kolom non-indeks (catatan)
UPDATE lab6.hot_penuh SET catatan = 'baru' WHERE id <= 5000;
UPDATE lab6.hot_longgar SET catatan = 'baru' WHERE id <= 5000;

-- Bandingkan n_tup_hot_upd
SELECT
  relname,
  n_tup_upd AS total_update,
  n_tup_hot_upd AS hot_update,
  round(n_tup_hot_upd::numeric / NULLIF(n_tup_upd, 0) * 100, 2) AS persen_hot
FROM pg_stat_user_tables
WHERE relname IN ('hot_penuh', 'hot_longgar');