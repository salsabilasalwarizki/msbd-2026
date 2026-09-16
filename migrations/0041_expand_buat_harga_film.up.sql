-- Migration 0041 UP: Buat struktur baru untuk harga per wilayah
-- Fase: EXPAND - membuat tabel baru tanpa mengganggu yang lama

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film(film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    EXCLUDE USING gist (film_id WITH =, wilayah WITH =, berlaku WITH &&)
);

CREATE INDEX idx_harga_film_film_id ON lab4.harga_film(film_id);
CREATE INDEX idx_harga_film_wilayah ON lab4.harga_film(wilayah);