-- Diminta: menambahkan CHECK rental_rate >= 0 dengan pola NOT VALID lalu VALIDATE.
-- Dipilih: dua tahap untuk hindari lock lama pada tabel besar.
-- Alternatif: CHECK langsung; tidak dipilih karena akan lock tabel saat validasi.

-- LANGKAH 1: Insert data negatif DULU (sebelum constraint ada)
INSERT INTO lab4.film (film_id, title, rental_rate)
VALUES (9997, 'Film Negatif', -1.00);

-- LANGKAH 2: Tambah constraint NOT VALID (berhasil karena skip validasi data existing)
ALTER TABLE lab4.film
ADD CONSTRAINT chk_rental_rate_positif
CHECK (rental_rate >= 0) NOT VALID;

-- LANGKAH 3: Coba VALIDATE constraint (harusnya GAGAL karena ada data negatif)
ALTER TABLE lab4.film VALIDATE CONSTRAINT chk_rental_rate_positif;

-- LANGKAH 4: Perbaiki data negatif
UPDATE lab4.film SET rental_rate = 0 WHERE rental_rate < 0;

-- LANGKAH 5: Validasi ulang (harusnya SUKSES)
ALTER TABLE lab4.film VALIDATE CONSTRAINT chk_rental_rate_positif;

-- Verifikasi: cek data yang sudah diperbaiki
SELECT film_id, title, rental_rate FROM lab4.film WHERE film_id = 9997;