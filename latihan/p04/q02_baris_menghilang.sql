-- Diminta: menyisipkan film lewat view dengan rental_rate = 4.99, lalu catat keluaran.
-- Dipilih: INSERT melalui view untuk mengamati fenomena "baris menghilang".
-- Alternatif: INSERT langsung ke tabel dasar; tidak dipilih karena tidak menguji perilaku view.

-- Sisipkan lewat view (tanpa check option, jadi lolos)
INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9999, 'Film Uji Hilang', 4.99, 'PG');

-- Hitung di view (harusnya 0 karena rental_rate 4.99 > 0.99)
SELECT count(*) AS di_view FROM lab4.film_murah WHERE title = 'Film Uji Hilang';

-- Hitung di tabel dasar (harusnya 1)
SELECT count(*) AS di_tabel FROM lab4.film WHERE title = 'Film Uji Hilang';