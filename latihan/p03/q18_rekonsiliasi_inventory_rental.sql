-- Diminta: film_id yang ada di inventory tapi tidak pernah disewa, dan sebaliknya,
-- dalam satu hasil dengan kolom penanda arah.
-- Dipilih: (A EXCEPT B) UNION ALL (B EXCEPT A) dengan penanda.
-- Alternatif: FULL OUTER JOIN; tidak dipilih karena EXCEPT lebih eksplisit.

SELECT film_id, 'di_inventory_tidak_disewa' AS arah
FROM (
    SELECT DISTINCT film_id FROM inventory
    EXCEPT
    SELECT DISTINCT i.film_id
    FROM inventory i
    JOIN rental r ON i.inventory_id = r.inventory_id
) a

UNION ALL

SELECT film_id, 'disewa_tidak_di_inventory' AS arah
FROM (
    SELECT DISTINCT i.film_id
    FROM inventory i
    JOIN rental r ON i.inventory_id = r.inventory_id
    EXCEPT
    SELECT DISTINCT film_id FROM inventory
) b
ORDER BY film_id, arah;