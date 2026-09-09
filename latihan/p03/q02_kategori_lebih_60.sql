-- Diminta: nama kategori beserta jumlah filmnya, hanya untuk kategori dengan >60 film.
-- Dipilih: derived table di FROM dengan JOIN karena mudah dibaca dan dimodifikasi.
-- Alternatif: HAVING COUNT(*) > 60; tidak dipilih karena ingin menunjukkan derived table.

SELECT k.nama_kategori, k.jumlah_film
FROM (
    SELECT c.name AS nama_kategori, COUNT(f.film_id) AS jumlah_film
    FROM category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN film f ON fc.film_id = f.film_id
    GROUP BY c.name
) k
WHERE k.jumlah_film > 60
ORDER BY k.jumlah_film DESC;