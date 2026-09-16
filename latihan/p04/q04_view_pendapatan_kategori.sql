-- Diminta: membuat view dengan GROUP BY, coba sisipkan, catat pesan galat.
-- Dipilih: CREATE VIEW dengan agregasi untuk menguji auto-updatable.
-- Alternatif: view tanpa GROUP BY; tidak dipilih karena diminta yang tidak auto-updatable.

CREATE OR REPLACE VIEW lab4.pendapatan_kategori AS
SELECT c.name AS kategori, SUM(f.rental_rate) AS total_tarif
FROM lab4.film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name;

-- Coba sisipkan (harusnya gagal karena view tidak auto-updatable)
INSERT INTO lab4.pendapatan_kategori (kategori, total_tarif)
VALUES ('Action', 100.00);