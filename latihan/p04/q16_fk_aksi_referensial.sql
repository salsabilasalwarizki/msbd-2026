-- Diminta: membuat tabel ulasan dengan foreign key, uji NO ACTION, CASCADE, SET NULL.
-- Dipilih: tiga tabel terpisah untuk menguji ketiga aksi referensial.
-- Alternatif: satu tabel dengan alter; tidak dipilih karena lebih jelas dengan tabel terpisah.

-- Tabel dengan NO ACTION (default)
CREATE TABLE lab4.ulasan_no_action (
    ulasan_id serial PRIMARY KEY,
    film_id integer REFERENCES lab4.film(film_id) ON DELETE NO ACTION,
    komentar text
);

-- Tabel dengan CASCADE
CREATE TABLE lab4.ulasan_cascade (
    ulasan_id serial PRIMARY KEY,
    film_id integer REFERENCES lab4.film(film_id) ON DELETE CASCADE,
    komentar text
);

-- Tabel dengan SET NULL
CREATE TABLE lab4.ulasan_set_null (
    ulasan_id serial PRIMARY KEY,
    film_id integer REFERENCES lab4.film(film_id) ON DELETE SET NULL,
    komentar text
);

-- Isi data
INSERT INTO lab4.ulasan_no_action (film_id, komentar) VALUES (1, 'Bagus');
INSERT INTO lab4.ulasan_cascade (film_id, komentar) VALUES (1, 'Bagus');
INSERT INTO lab4.ulasan_set_null (film_id, komentar) VALUES (1, 'Bagus');

-- Uji hapus induk
DELETE FROM lab4.film WHERE film_id = 1;