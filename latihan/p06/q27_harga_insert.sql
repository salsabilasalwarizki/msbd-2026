-- Diminta: membandingkan INSERT 200000 baris tanpa index dan dengan 5 index.
-- Dipilih: tabel baru tanpa index, lalu tambah index, bandingkan waktu INSERT.
-- Alternatif: hapus index dari event_log; tidak dipilih karena terlalu berisiko.

-- Buat tabel tanpa index
CREATE TABLE lab6.insert_test_no_idx (
  id serial PRIMARY KEY,
  data text
);

-- Buat tabel dengan 5 index
CREATE TABLE lab6.insert_test_with_idx (
  id serial PRIMARY KEY,
  data text
);
CREATE INDEX idx_data ON lab6.insert_test_with_idx (data);
CREATE INDEX idx_data_lower ON lab6.insert_test_with_idx (lower(data));
CREATE INDEX idx_data_length ON lab6.insert_test_with_idx (length(data));
CREATE INDEX idx_data_reverse ON lab6.insert_test_with_idx (reverse(data));
CREATE INDEX idx_data_md5 ON lab6.insert_test_with_idx (md5(data));

\timing on

-- INSERT tanpa index
INSERT INTO lab6.insert_test_no_idx (data)
SELECT 'data_' || g FROM generate_series(1, 200000) AS g;

-- INSERT dengan 5 index
INSERT INTO lab6.insert_test_with_idx (data)
SELECT 'data_' || g FROM generate_series(1, 200000) AS g;

\timing off

-- Bandingkan waktu dan hitung persentase selisih