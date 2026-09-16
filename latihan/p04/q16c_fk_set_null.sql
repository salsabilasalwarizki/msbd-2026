-- Uji SET NULL: hapus induk, film_id di anak jadi NULL
DELETE FROM lab4.ulasan_set_null WHERE film_id = 1;
INSERT INTO lab4.ulasan_set_null (film_id, komentar) VALUES (1, 'Bagus');
DELETE FROM lab4.film WHERE film_id = 1;
SELECT film_id, komentar FROM lab4.ulasan_set_null WHERE komentar = 'Bagus';