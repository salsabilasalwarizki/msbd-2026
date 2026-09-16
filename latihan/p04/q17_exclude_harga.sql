-- Diminta: membuat constraint EXCLUDE untuk periode harga tidak tumpang tindih.
-- Dipilih: EXCLUDE USING gist dengan btree_gist untuk kombinasi = dan &&.
-- Alternatif: trigger; tidak dipilih karena EXCLUDE lebih deklaratif dan aman dari race condition.

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film(film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    EXCLUDE USING gist (film_id WITH =, wilayah WITH =, berlaku WITH &&)
);

-- Insert pertama (harusnya sukses)
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (1, 'ID', 5.00, daterange('2026-01-01', '2026-06-30'));

-- Insert tumpang tindih (harusnya gagal)
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (1, 'ID', 6.00, daterange('2026-03-01', '2026-09-30'));

-- Insert tidak tumpang tindih (harusnya sukses)
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (1, 'ID', 7.00, daterange('2026-07-01', '2026-12-31'));