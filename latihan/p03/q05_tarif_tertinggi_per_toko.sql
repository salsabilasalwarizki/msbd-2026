-- Diminta: untuk setiap toko, judul film dengan tarif sewa tertinggi di toko tersebut,
-- diselesaikan tanpa window function.
-- Dipilih: subquery berkorelasi dengan = MAX karena sederhana dan sesuai syarat.
-- Alternatif: = ALL; tidak dipilih karena MAX lebih umum dan mudah dibaca.

SELECT s.store_id, f.title AS judul_film, f.rental_rate AS tarif_tertinggi
FROM store s
JOIN inventory i ON s.store_id = i.store_id
JOIN film f ON i.film_id = f.film_id
WHERE f.rental_rate = (
    SELECT MAX(f2.rental_rate)
    FROM film f2
    JOIN inventory i2 ON f2.film_id = i2.film_id
    WHERE i2.store_id = s.store_id
)
ORDER BY s.store_id, f.rental_rate DESC;