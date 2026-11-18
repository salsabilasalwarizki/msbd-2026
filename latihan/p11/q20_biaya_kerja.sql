-- Diminta: membandingkan waktu komputasi antara md5(), bcrypt cost 6, dan bcrypt cost 10.
-- Dipilih: mengukur durasi eksekusi menggunakan clock_timestamp().
-- Alternatif: algoritma hash cepat untuk kredensial; tidak dipilih karena memudahkan brute-force GPU jutaan tebakan per detik.

SELECT
  clock_timestamp() AS t0,
  md5('rahasia123') AS h_md5,
  clock_timestamp() AS t1,
  crypt('rahasia123', gen_salt('bf', 6)) AS h_bf6,
  clock_timestamp() AS t2,
  crypt('rahasia123', gen_salt('bf', 10)) AS h_bf10,
  clock_timestamp() AS t3;
