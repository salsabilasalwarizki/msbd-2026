-- Diminta: tulis ulang Q2 dengan CTE, tambahkan CTE kedua untuk rata-rata tarif per kategori.
-- Dipilih: dua CTE berurutan karena mudah dibaca dan CTE kedua dapat merujuk CTE pertama.
-- Alternatif: subquery bertingkat; tidak dipilih karena CTE lebih jelas alurnya.

WITH jumlah_film AS (
    SELECT c.name AS nama_kategori, COUNT(f.film_id) AS jumlah_film
    FROM category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN film f ON fc.film_id = f.film_id
    GROUP BY c.name
),
rata_tarif AS (
    SELECT c.name AS nama_kategori, ROUND(AVG(f.rental_rate)::numeric, 2) AS rata_tarif
    FROM category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN film f ON fc.film_id = f.film_id
    GROUP BY c.name
)
SELECT j.nama_kategori, j.jumlah_film, r.rata_tarif
FROM jumlah_film j
JOIN rata_tarif r ON j.nama_kategori = r.nama_kategori
WHERE j.jumlah_film > 60
ORDER BY j.jumlah_film DESC;
