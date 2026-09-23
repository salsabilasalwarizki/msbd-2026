-- Diminta: mencoba set status EXPIRED, lalu tambahkan nilai enum.
-- Dipilih: ALTER TYPE ADD VALUE untuk extend enum.
-- Alternatif: buat enum baru; tidak dipilih karena ALTER TYPE lebih sederhana.

-- Uji status EXPIRED (harus GAGAL)
UPDATE lab5.rental_tx SET status = 'EXPIRED' WHERE rental_id = 1;

-- Tambahkan nilai EXPIRED ke enum
ALTER TYPE lab5.rental_status ADD VALUE 'EXPIRED';

-- COMMIT diperlukan sebelum pakai nilai enum baru (PostgreSQL 12+)
-- Uji lagi (harus BERHASIL)
UPDATE lab5.rental_tx SET status = 'EXPIRED' WHERE rental_id = 1;

-- Verifikasi
SELECT rental_id, status FROM lab5.rental_tx WHERE rental_id = 1;