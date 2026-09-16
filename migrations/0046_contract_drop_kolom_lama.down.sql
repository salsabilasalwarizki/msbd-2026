-- Migration 0046 DOWN: Tambah kembali kolom rental_rate
-- PERINGATAN: Hanya membuat ulang struktur, data lama HILANG PERMANEN!

ALTER TABLE lab4.film ADD COLUMN rental_rate numeric(5,2);

-- Isi dengan nilai default dari harga_film jika memungkinkan
UPDATE lab4.film f
SET rental_rate = hf.harga
FROM lab4.harga_film hf
WHERE f.film_id = hf.film_id AND hf.wilayah = 'ID';