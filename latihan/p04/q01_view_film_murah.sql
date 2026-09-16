-- Diminta: membuat view lab4.film_murah berisi film dengan rental_rate <= 0.99.
-- Dipilih: CREATE VIEW sederhana tanpa WITH CHECK OPTION untuk observasi awal.
-- Alternatif: WITH LOCAL CHECK OPTION; tidak dipilih karena diminta tanpa check option dulu.

CREATE OR REPLACE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99;

-- Uji: lihat isi view
SELECT count(*) FROM lab4.film_murah;