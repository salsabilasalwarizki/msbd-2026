-- Diminta: menambahkan soft delete dengan unique index parsial.
-- Dipilih: unique index dengan WHERE deleted_at IS NULL untuk izinkan duplikat judul soft-deleted.
-- Alternatif: UNIQUE constraint biasa; tidak dipilih karena tidak izinkan soft delete.

-- LANGKAH 1: Tambah kolom deleted_at
ALTER TABLE lab4.film ADD COLUMN deleted_at timestamptz;

-- LANGKAH 2: Tambah UNIQUE constraint biasa (akan bermasalah)
ALTER TABLE lab4.film ADD CONSTRAINT film_judul_unik UNIQUE (title);

-- LANGKAH 3: Soft delete film yang sudah ada (film_id = 1)
UPDATE lab4.film SET deleted_at = now() WHERE film_id = 1;

-- LANGKAH 4: Coba insert judul sama (akan GAGAL karena UNIQUE constraint biasa)
-- Gunakan film_id yang unik dan belum terpakai
INSERT INTO lab4.film (film_id, title, rental_rate) 
VALUES (9996, 'ACADEMY DINOSAUR', 2.99);

-- LANGKAH 5: Hapus constraint biasa
ALTER TABLE lab4.film DROP CONSTRAINT film_judul_unik;

-- LANGKAH 6: Buat unique index parsial (hanya untuk film aktif)
CREATE UNIQUE INDEX ux_film_judul_aktif
ON lab4.film (title) WHERE deleted_at IS NULL;

-- LANGKAH 7: Sekarang insert judul sama harusnya SUKSES
-- (karena yang lama sudah soft-deleted, deleted_at tidak NULL)
INSERT INTO lab4.film (film_id, title, rental_rate) 
VALUES (9995, 'ACADEMY DINOSAUR', 2.99);

-- Verifikasi: cek kedua film dengan judul sama
SELECT film_id, title, deleted_at 
FROM lab4.film 
WHERE title = 'ACADEMY DINOSAUR'
ORDER BY film_id;