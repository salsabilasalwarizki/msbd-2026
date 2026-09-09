-- Diminta: judul film yang tidak pernah disewa, dengan versi NOT IN dan NOT EXISTS.
-- Dipilih: kedua versi untuk perbandingan; NOT EXISTS lebih aman terhadap NULL.
-- Alternatif: LEFT JOIN + WHERE rental_id IS NULL; tidak dipilih karena diminta NOT IN/EXISTS.

-- Versi NOT IN
SELECT title AS judul_film_not_in
FROM film
WHERE film_id NOT IN (
    SELECT film_id FROM inventory
    WHERE inventory_id IN (SELECT inventory_id FROM rental)
);

-- Versi NOT EXISTS
SELECT title AS judul_film_not_exists
FROM film f
WHERE NOT EXISTS (
    SELECT 1 FROM inventory i
    JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE i.film_id = f.film_id
);