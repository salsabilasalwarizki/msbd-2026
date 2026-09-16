-- Migration 0045 UP: Buat view fasad dan hentikan tulis ganda
-- Fase: CONTRACT - mempertahankan kompatibilitas untuk aplikasi lama

CREATE OR REPLACE VIEW lab4.film_lama AS
SELECT f.film_id, f.title, hf.harga AS rental_rate, f.rating
FROM lab4.film f
LEFT JOIN lab4.harga_film hf ON f.film_id = hf.film_id AND hf.wilayah = 'ID';

-- Hentikan trigger tulis ganda
DROP TRIGGER IF EXISTS sync_harga_ke_film ON lab4.harga_film;
DROP FUNCTION IF EXISTS lab4.sync_harga_ke_film();