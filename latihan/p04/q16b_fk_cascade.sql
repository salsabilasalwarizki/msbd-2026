-- Uji CASCADE: hapus induk, anak ikut terhapus
DELETE FROM lab4.ulasan_cascade WHERE film_id = 1;
INSERT INTO lab4.ulasan_cascade (film_id, komentar) VALUES (1, 'Bagus');
DELETE FROM lab4.film WHERE film_id = 1;
SELECT count(*) AS sisa_ulasan FROM lab4.ulasan_cascade WHERE film_id = 1;