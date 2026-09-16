-- Diminta: menjadikan query Q5 materialized view dengan WITH NO DATA.
-- Dipilih: WITH NO DATA agar pembuatan cepat, refresh dilakukan terpisah.
-- Alternatif: tanpa NO DATA; tidak dipilih karena diminta WITH NO DATA.

-- Buat materialized view
CREATE MATERIALIZED VIEW lab4.ringkasan_akses AS
SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2
WITH NO DATA;

-- Coba baca sebelum refresh (harusnya error)
SELECT * FROM lab4.ringkasan_akses LIMIT 5;

-- Refresh biasa dan catat waktu
\timing on
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;
\timing off

-- Verifikasi
SELECT count(*) FROM lab4.ringkasan_akses;