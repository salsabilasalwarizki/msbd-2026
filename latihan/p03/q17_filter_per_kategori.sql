-- Diminta: per kategori, jumlah film total, jumlah film G, jumlah film PG-13,
-- dan rata-rata durasi film > 90 menit.
-- Dipilih: agregat FILTER karena lebih ringkas dan sesuai standar SQL.
-- Alternatif: CASE WHEN; ditunjukkan untuk perbandingan.

-- Versi FILTER
SELECT
    c.name AS kategori,
    COUNT(f.film_id) AS total_film,
    COUNT(f.film_id) FILTER (WHERE f.rating = 'G') AS film_G,
    COUNT(f.film_id) FILTER (WHERE f.rating = 'PG-13') AS film_PG13,
    ROUND(AVG(f.length) FILTER (WHERE f.length > 90)::numeric, 2) AS rata_durasi_90lebih
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY kategori;

-- Versi CASE WHEN (untuk perbandingan)
SELECT
    c.name AS kategori,
    COUNT(f.film_id) AS total_film,
    COUNT(CASE WHEN f.rating = 'G' THEN 1 END) AS film_G,
    COUNT(CASE WHEN f.rating = 'PG-13' THEN 1 END) AS film_PG13,
    ROUND(AVG(CASE WHEN f.length > 90 THEN f.length END)::numeric, 2) AS rata_durasi_90lebih
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY kategori;