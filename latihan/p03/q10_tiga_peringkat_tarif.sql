-- Diminta: untuk setiap film, tampilkan judul, kategori, tarif, dan tiga peringkat
-- (ROW_NUMBER, RANK, DENSE_RANK) di dalam kategorinya.
-- Dipilih: klausa WINDOW yang didefinisikan sekali dan dipakai tiga kali.
-- Alternatif: tulis OVER(...) tiga kali; tidak dipilih karena WINDOW lebih DRY.

SELECT
    f.title AS judul,
    c.name AS kategori,
    f.rental_rate AS tarif,
    ROW_NUMBER() OVER w AS row_num,
    RANK() OVER w AS rank_num,
    DENSE_RANK() OVER w AS dense_rank_num
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WINDOW w AS (PARTITION BY c.name ORDER BY f.rental_rate DESC);