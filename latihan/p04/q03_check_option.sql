-- Diminta: membuat ulang view dengan WITH CASCADED CHECK OPTION, ulangi penyisipan Q2.
-- Dipilih: WITH CASCADED CHECK OPTION untuk memaksa aturan view saat INSERT/UPDATE.
-- Alternatif: WITH LOCAL CHECK OPTION; tidak dipilih karena CASCADED lebih ketat.

-- Buat ulang view dengan check option
CREATE OR REPLACE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99
WITH CASCADED CHECK OPTION;

-- Coba sisipkan lagi (harusnya gagal)
INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9998, 'Film Uji Check', 4.99, 'PG');