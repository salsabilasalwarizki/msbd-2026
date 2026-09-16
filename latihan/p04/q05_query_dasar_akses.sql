-- Diminta: menjalankan query agregasi dengan \timing on dan mencatat waktunya.
-- Dipilih: query langsung ke tabel jejak_akses untuk baseline performa.
-- Alternatif: query dengan filter; tidak dipilih karena diminta agregasi penuh.

\timing on

SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2;

\timing off