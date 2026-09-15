-- Diminta: tiga film dengan tarif sewa tertinggi di setiap kategori.
-- Dipilih: CTE dengan window function, lalu saring di lapisan luar.
-- Alternatif: subquery berkorelasi; tidak dipilih karena window lebih efisien.

WITH peringkat AS (
    SELECT
        f.title AS judul,
        c.name AS kategori,
        f.rental_rate AS tarif,
        ROW_NUMBER() OVER (PARTITION BY c.name ORDER BY f.rental_rate DESC) AS rn
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
)
SELECT judul, kategori, tarif
FROM peringkat
WHERE rn <= 3
ORDER BY kategori, tarif DESC;