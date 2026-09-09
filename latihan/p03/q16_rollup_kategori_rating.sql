-- Diminta: jumlah film dan rata-rata tarif untuk setiap kategori-rating, subtotal per kategori,
-- dan grand total dalam satu hasil.
-- Dipilih: ROLLUP dengan GROUPING() untuk label SEMUA.
-- Alternatif: UNION ALL manual; tidak dipilih karena ROLLUP lebih ringkas.

SELECT 
    CASE WHEN GROUPING(c.name) = 1 THEN 'SEMUA' ELSE c.name END AS kategori,
    CASE WHEN GROUPING(f.rating) = 1 THEN 'SEMUA' ELSE f.rating::text END AS rating,
    COUNT(f.film_id) AS jumlah_film,
    ROUND(AVG(f.rental_rate)::numeric, 2) AS rata_tarif
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY ROLLUP(c.name, f.rating)
ORDER BY kategori, rating;