-- ============================================================
-- LATIHAN KELOMPOK PERTEMUAN 9
-- Menguji Transaksi dan Kendali Konkurensi
-- Database: latihan | Skema: lab9
-- Alat: Dua terminal psql terpisah (SESI_A dan SESI_B)
-- ============================================================

-- Diminta: mendemonstrasikan transaksi dengan dua sesi PostgreSQL,
--          membedakan anomali konkurensi, serta menguji isolation level.
-- Dipilih: kelompok kami milih pakai dua terminal psql terpisah (SESI_A dan SESI_B)
--          karena lebih mudah mengontrol urutan eksekusi dan melihat state transaksi secara real-time.
-- Alternatif: menggunakan DBeaver dengan 2 SQL Editor; tidak dipilih karena 
--             auto-commit DBeaver kadang sulit dikontrol untuk eksperimen konkurensi.



-- ============================================================
-- Q1: Buktikan kondisi awal
-- (Bisa dijalankan di SESI_A atau SESI_B)
-- ============================================================
SELECT * FROM lab9.rekening ORDER BY rekening_id;
SELECT SUM(saldo) AS total_saldo FROM lab9.rekening;


-- ============================================================
-- Q2: Transaksi dan Visibilitas Antar Sesi
-- ============================================================

-- [SESI_A] Mulai transaksi dan ubah saldo, JANGAN di-COMMIT dulu!
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1;
SELECT * FROM lab9.rekening WHERE rekening_id = 1;

-- [SESI_B] Cek saldo rekening 1 (harus masih melihat nilai lama / 1000000)
SELECT * FROM lab9.rekening WHERE rekening_id = 1;

-- [SESI_A] Commit transaksi agar perubahan permanen
COMMIT;

-- [SESI_B] Cek saldo rekening 1 lagi (sekarang harus melihat nilai baru / 900000)
SELECT * FROM lab9.rekening WHERE rekening_id = 1;


-- ============================================================
-- Q3: Bandingkan COMMIT dan ROLLBACK
-- (Jalankan di SESI_A)
-- ============================================================
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 50000 WHERE rekening_id = 1;

-- Lihat saldo sebelum rollback
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; 

-- Batalkan transaksi
ROLLBACK;

-- Lihat saldo setelah rollback (harus kembali ke nilai sebelum BEGIN)
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; 


-- ============================================================
-- Q4: Transaksi dengan SAVEPOINT
-- (Jalankan di SESI_A)
-- ============================================================
BEGIN;

-- Update pertama
UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; 

-- Buat savepoint
SAVEPOINT sp1;

-- Update kedua
UPDATE lab9.rekening SET saldo = saldo - 20000 WHERE rekening_id = 1;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; 

-- Rollback hanya ke savepoint (update kedua dibatalkan, update pertama tetap)
ROLLBACK TO SAVEPOINT sp1;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; 

-- Commit transaksi
COMMIT;

-- Cek saldo final
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; 


-- ============================================================
-- Q5: Atomicity dan Consistency (Uji Constraint CHECK)
-- (Jalankan di SESI_A)
-- ============================================================
BEGIN;

-- Coba kurangi saldo melebihi jumlah yang ada (akan melanggar CHECK saldo >= 0)
UPDATE lab9.rekening SET saldo = saldo - 2000000 WHERE rekening_id = 1;
-- Catatan: Akan muncul ERROR: new row for relation "rekening" violates check constraint "rekening_saldo_check"

-- Cek apakah saldo berubah (seharusnya tidak, karena transaksi otomatis gagal/rollback parsial)
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;

-- Bersihkan state transaksi yang error
ROLLBACK; 

