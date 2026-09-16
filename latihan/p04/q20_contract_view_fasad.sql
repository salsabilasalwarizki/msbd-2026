-- Diminta: membuat view fasad, hentikan tulis ganda, drop kolom lama.
-- Dipilih: drop semua dependency sebelum drop kolom.
-- Alternatif: DROP CASCADE; tidak dipilih karena akan menghapus view yang mungkin masih diperlukan.

-- LANGKAH 1: Buat view fasad (mempertahankan bentuk lama untuk aplikasi lama)
CREATE OR REPLACE VIEW lab4.film_lama AS
SELECT f.film_id, f.title, hf.harga AS rental_rate, f.rating
FROM lab4.film f
LEFT JOIN lab4.harga_film hf ON f.film_id = hf.film_id AND hf.wilayah = 'ID';

-- LANGKAH 2: Hentikan trigger tulis ganda
DROP TRIGGER IF EXISTS sync_harga_ke_film ON lab4.harga_film;
DROP FUNCTION IF EXISTS lab4.sync_harga_ke_film();

-- LANGKAH 3: Drop trigger audit harga (karena kolom rental_rate akan dihapus)
DROP TRIGGER IF EXISTS film_audit_harga ON lab4.film;
DROP FUNCTION IF EXISTS lab4.catat_audit_harga();

-- LANGKAH 4: Drop view yang bergantung pada rental_rate
DROP VIEW IF EXISTS lab4.film_murah CASCADE;
DROP VIEW IF EXISTS lab4.pendapatan_kategori CASCADE;

-- LANGKAH 5: Sekarang drop kolom lama (HATI-HATI: tidak bisa di-rollback!)
ALTER TABLE lab4.film DROP COLUMN rental_rate;

-- Verifikasi: cek struktur tabel film
\d lab4.film

-- Verifikasi: cek view fasad masih bisa diakses
SELECT * FROM lab4.film_lama LIMIT 5;