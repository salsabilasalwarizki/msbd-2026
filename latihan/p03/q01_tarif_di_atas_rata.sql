-- Diminta: daftar judul film yang tarif sewanya di atas rata-rata tarif seluruh film,
-- diurutkan menurun, menampilkan judul, tarif, rata-rata, dan selisih.
-- Dipilih: subquery skalar di SELECT dan WHERE karena hanya menghasilkan satu nilai.
-- Alternatif: CTE; tidak dipilih karena alurnya singkat dan subquery skalar lebih ringkas.

SELECT
    title AS judul,
    rental_rate AS tarif,
    (SELECT ROUND(AVG(rental_rate)::numeric, 2) FROM film) AS rata_rata,
    ROUND((rental_rate - (SELECT AVG(rental_rate) FROM film))::numeric, 2) AS selisih
FROM film
WHERE rental_rate > (SELECT AVG(rental_rate) FROM film)
ORDER BY rental_rate DESC;