-- Diminta: menyiapkan skema lab4 dengan salinan tabel film dan 500000 jejak akses.
-- Dipilih: CREATE TABLE ... AS TABLE untuk menyalin struktur dan data sekaligus.
-- Alternatif: pg_dump + pg_restore; tidak dipilih karena lebih lambat untuk skema kecil.

CREATE SCHEMA IF NOT EXISTS lab4;
SET search_path = lab4, public;

DROP TABLE IF EXISTS lab4.jejak_akses CASCADE;
DROP TABLE IF EXISTS lab4.film CASCADE;

CREATE TABLE lab4.film AS TABLE public.film;
ALTER TABLE lab4.film ADD PRIMARY KEY (film_id);

CREATE TABLE lab4.jejak_akses (
    akses_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    waktu timestamptz NOT NULL,
    kanal text NOT NULL
);

INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1,
       now() - (random() * 365) * interval '1 day',
       (ARRAY['web','android','ios','kiosk'])[(random() * 3)::int + 1]
FROM generate_series(1, 500000);

ANALYZE lab4.jejak_akses;
SELECT count(*) FROM lab4.jejak_akses;