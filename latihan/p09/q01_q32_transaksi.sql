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


-- ============================================================
-- Q6: Non-repeatable Read (READ COMMITTED)
-- Kelompok kami milih pakai READ COMMITTED karena ini default PostgreSQL
-- ============================================================

-- [SESI_A]
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- JANGAN COMMIT, biarkan transaksi terbuka

-- [SESI_B]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 50000 WHERE rekening_id = 1;
COMMIT;

-- [SESI_A] Jalankan SELECT yang sama lagi
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
COMMIT;
-- Catatan: Nilai akan BERUBAH (non-repeatable read terjadi)


-- ============================================================
-- Q7: Perbandingan Isolation (REPEATABLE READ)
-- Kelompok kami milih pakai REPEATABLE READ untuk membuktikan perbedaan dengan Q6
-- ============================================================

-- [SESI_A]
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;

-- [SESI_B]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 30000 WHERE rekening_id = 1;
COMMIT;

-- [SESI_A] Jalankan SELECT yang sama lagi
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
COMMIT;
-- Catatan: Nilai TIDAK BERUBAH (REPEATABLE READ mencegah non-repeatable read)


-- ============================================================
-- Q8: Phantom Read
-- Kelompok kami milih pakai tabel transaksi_log untuk menguji phantom read
-- ============================================================

-- [SESI_A] Setup tabel eksperimen (jalankan sekali saja)
CREATE TABLE IF NOT EXISTS lab9.transaksi_log (
    id SERIAL PRIMARY KEY,
    rekening_id INT,
    jumlah NUMERIC(12,2),
    waktu TIMESTAMP DEFAULT NOW()
);

INSERT INTO lab9.transaksi_log (rekening_id, jumlah) VALUES
(1, 100000),
(1, 200000),
(2, 150000);

-- [SESI_A] READ COMMITTED - hitung baris
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT COUNT(*) AS jumlah_transaksi FROM lab9.transaksi_log WHERE rekening_id = 1;

-- [SESI_B] Tambahkan baris baru
INSERT INTO lab9.transaksi_log (rekening_id, jumlah) VALUES (1, 300000);

-- [SESI_A] Hitung ulang
SELECT COUNT(*) AS jumlah_transaksi FROM lab9.transaksi_log WHERE rekening_id = 1;
COMMIT;
-- Catatan: Jumlah BERUBAH dari 2 menjadi 3 (phantom read)

-- [SESI_A] Ulangi dengan REPEATABLE READ
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) AS jumlah_transaksi FROM lab9.transaksi_log WHERE rekening_id = 1;

-- [SESI_B] Tambahkan baris baru lagi
INSERT INTO lab9.transaksi_log (rekening_id, jumlah) VALUES (1, 400000);

-- [SESI_A] Hitung ulang
SELECT COUNT(*) AS jumlah_transaksi FROM lab9.transaksi_log WHERE rekening_id = 1;
COMMIT;
-- Catatan: Jumlah TIDAK BERUBAH (REPEATABLE READ mencegah phantom read)


-- ============================================================
-- Q9: Dirty Read dan READ UNCOMMITTED
-- Kelompok kami milih pakai READ UNCOMMITTED untuk membuktikan PostgreSQL tidak mengizinkan dirty read
-- ============================================================

-- [SESI_A]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 2;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 2;
-- JANGAN COMMIT!

-- [SESI_B]
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 2;
COMMIT;
-- Catatan: PostgreSQL TETAP menampilkan nilai lama (1000000), bukan nilai yang belum di-COMMIT
-- Ini membuktikan PostgreSQL tidak mengizinkan dirty read meskipun isolation level READ UNCOMMITTED

-- [SESI_A] Cleanup
ROLLBACK;


-- ============================================================
-- Q10: Lost Update
-- Kelompok kami milih pakai skenario dua sesi membaca nilai yang sama lalu menulis nilai tetap
-- ============================================================

-- [SESI_A]
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Catatan nilai yang dibaca (misal: 840000)

-- [SESI_B]
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Catatan nilai yang dibaca (sama: 840000)

-- [SESI_A] Hitung di aplikasi: 840000 - 50000 = 790000, lalu tulis nilai tetap
UPDATE lab9.rekening SET saldo = 790000 WHERE rekening_id = 1;
COMMIT;

-- [SESI_B] Hitung di aplikasi: 840000 - 30000 = 810000, lalu tulis nilai tetap
UPDATE lab9.rekening SET saldo = 810000 WHERE rekening_id = 1;
COMMIT;

-- [SESI_A atau SESI_B] Verifikasi
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Catatan: Hasil akhir 810000 (update SESI_A hilang/tertimpa)
-- Seharusnya: 840000 - 50000 - 30000 = 760000
-- Ini adalah LOST UPDATE


-- ============================================================
-- Q11: Tabel Ringkasan Anomali
-- (Dijawab di laporan.md, tidak ada SQL khusus)
-- ============================================================


-- ============================================================
-- Q12: Mencegah Lost Update dengan Pembaruan Atomik
-- Kelompok kami milih pakai UPDATE atomik (saldo = saldo - N) karena lebih aman
-- ============================================================

-- [SESI_A]
BEGIN;
UPDATE lab9.rekening
SET saldo = saldo - 10000
WHERE rekening_id = 1 AND saldo >= 10000;
COMMIT;

-- [SESI_B] (jalankan bersamaan dengan SESI_A)
BEGIN;
UPDATE lab9.rekening
SET saldo = saldo - 20000
WHERE rekening_id = 1 AND saldo >= 20000;
COMMIT;

-- [SESI_A atau SESI_B] Verifikasi
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Catatan: Tidak ada lost update karena PostgreSQL mengunci baris saat UPDATE


-- ============================================================
-- Q13: SELECT ... FOR UPDATE
-- Kelompok kami milih pakai FOR UPDATE untuk mengunci baris secara eksklusif
-- ============================================================

-- [SESI_A]
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- JANGAN COMMIT, biarkan transaksi terbuka

-- [SESI_B] (akan menunggu/blocking)
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 5000 WHERE rekening_id = 1;
-- Catatan: SESI_B akan MENUNGGU sampai SESI_A COMMIT atau ROLLBACK

-- [SESI_A]
COMMIT;

-- [SESI_B] (setelah SESI_A COMMIT, UPDATE akan berhasil)
COMMIT;


-- ============================================================
-- Q14: Optimistic Locking dengan Version Number
-- Kelompok kami milih pakai kolom version_no untuk mendeteksi konflik tanpa lock
-- ============================================================

-- [SESI_A] Setup kolom versi (jalankan sekali saja)
ALTER TABLE lab9.rekening ADD COLUMN IF NOT EXISTS version_no INT DEFAULT 1;

-- [SESI_A]
BEGIN;
SELECT saldo, version_no FROM lab9.rekening WHERE rekening_id = 1;
-- Catatan nilai yang dibaca (misal: saldo=840000, version_no=1)

-- [SESI_B]
BEGIN;
SELECT saldo, version_no FROM lab9.rekening WHERE rekening_id = 1;
-- Catatan nilai yang dibaca (sama: saldo=840000, version_no=1)

-- [SESI_A] Update dengan kondisi version_no
UPDATE lab9.rekening 
SET saldo = 790000, version_no = version_no + 1 
WHERE rekening_id = 1 AND version_no = 1;
COMMIT;
-- Catatan: Berhasil (1 row affected), version_no sekarang = 2

-- [SESI_B] Update dengan kondisi version_no yang sama
UPDATE lab9.rekening 
SET saldo = 810000, version_no = version_no + 1 
WHERE rekening_id = 1 AND version_no = 1;
COMMIT;
-- Catatan: GAGAL (0 rows affected) karena version_no sudah bukan 1 lagi
-- Aplikasi bisa cek rows affected = 0 dan tahu data sudah berubah


-- ============================================================
-- Q15: MVCC - Snapshot Isolation
-- Kelompok kami milih pakai dua SELECT di transaksi berbeda untuk membuktikan MVCC
-- ============================================================

-- [SESI_A]
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- Catatan nilai yang dibaca (misal: 790000)

-- [SESI_B]
BEGIN;
UPDATE lab9.rekening SET saldo = 750000 WHERE rekening_id = 1;
-- JANGAN COMMIT dulu

-- [SESI_A] Jalankan SELECT yang sama lagi
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
COMMIT;
-- Catatan: Nilai TETAP 790000 (tidak terpengaruh UPDATE SESI_B)
-- Ini membuktikan MVCC: pembaca melihat snapshot tanpa menunggu penulis

-- [SESI_B] Cleanup
COMMIT;


-- ============================================================
-- Q16: xmin dan xmax
-- Kelompok kami milih pakai query langsung ke tabel untuk melihat metadata transaksi
-- ============================================================

-- [SESI_A atau SESI_B]
SELECT rekening_id, pemilik, saldo, xmin, xmax 
FROM lab9.rekening 
WHERE rekening_id = 1;
-- Catatan: 
-- xmin = ID transaksi yang INSERT baris ini
-- xmax = ID transaksi yang DELETE baris ini (0 = belum di-delete)
-- Ini adalah metadata internal PostgreSQL, bukan kolom bisnis


-- ============================================================
-- Q17: Manfaat MVCC dan VACUUM
-- (Dijawab di laporan.md, tidak ada SQL khusus)
-- Tapi bisa dibuktikan dengan VACUUM:
VACUUM (ANALYZE) lab9.rekening;


-- ============================================================
-- Q18: Perbandingan Lock Mode
-- Kelompok kami milih pakai empat jenis lock untuk membandingkan tingkat eksklusivitas
-- ============================================================

-- [SESI_A] FOR UPDATE (paling ketat)
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- Catatan: Memblokir FOR UPDATE, FOR NO KEY UPDATE, FOR SHARE, FOR KEY SHARE

-- [SESI_B] Coba FOR SHARE (akan menunggu)
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR SHARE;
-- Catatan: SESI_B akan MENUNGGU sampai SESI_A selesai

-- [SESI_A]
COMMIT;

-- [SESI_B] (setelah SESI_A COMMIT, akan berhasil)
COMMIT;

-- Ulangi dengan FOR NO KEY UPDATE dan FOR KEY SHARE untuk perbandingan


-- ============================================================
-- Q19: Lock Waiting
-- Kelompok kami milih pakai FOR UPDATE di kedua sesi untuk membuktikan lock queue
-- ============================================================

-- [SESI_A]
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- JANGAN COMMIT

-- [SESI_B] (akan menunggu)
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- Catatan: SESI_B MENUNGGU (blocking), bukan error

-- [SESI_A]
COMMIT;

-- [SESI_B] (setelah SESI_A COMMIT, akan berhasil)
COMMIT;


-- ============================================================
-- Q20: Deadlock
-- Kelompok kami milih pakai skenario circular wait untuk mereproduksi deadlock
-- ============================================================

-- [SESI_A]
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- JANGAN COMMIT

-- [SESI_B]
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
-- JANGAN COMMIT

-- [SESI_A] Coba lock rekening 2 (yang sudah di-lock SESI_B)
SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
-- Catatan: SESI_A akan MENUNGGU

-- [SESI_B] Coba lock rekening 1 (yang sudah di-lock SESI_A)
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- Catatan: DEADLOCK! PostgreSQL akan mendeteksi dan kill salah satu transaksi
-- Error: ERROR: deadlock detected
-- SQLSTATE: 40P01

-- [SESI yang selamat]
COMMIT;

-- [SESI yang di-kill] akan otomatis ROLLBACK


-- ============================================================
-- Q21: Mencegah Deadlock dengan Urutan Konsisten
-- Kelompok kami milih pakai urutan penguncian dari ID terkecil ke terbesar
-- ============================================================

-- [SESI_A]
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
COMMIT;

-- [SESI_B] (jalankan bersamaan, dengan urutan yang SAMA)
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- Catatan: SESI_B akan MENUNGGU SESI_A selesai (karena lock rekening 1)
SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
COMMIT;
-- Catatan: TIDAK ADA DEADLOCK karena urutan penguncian konsisten


-- ============================================================
-- Q22: Deadlock vs Antrean Lock Panjang
-- (Dijawab di laporan.md, tapi bisa dibuktikan dengan simulasi)
-- ============================================================

-- [SESI_A] Simulasi transaksi lama
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
SELECT pg_sleep(10); -- Tidur 10 detik
COMMIT;

-- [SESI_B, C, D] (akan antri menunggu SESI_A)
-- Catatan: Ini adalah lock queue panjang, bukan deadlock


-- ============================================================
-- Q23: Perbandingan Timeout
-- Kelompok kami milih pakai SET LOCAL untuk menguji timeout tanpa mengubah konfigurasi global
-- ============================================================

-- [SESI_A] Set timeout untuk sesi ini saja
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- Catatan: Jika lock tidak didapat dalam 5 detik, akan error: lock timeout

-- [SESI_A] Reset setelah eksperimen
RESET lock_timeout;
RESET statement_timeout;


-- ============================================================
-- Q24: SKIP LOCKED
-- Kelompok kami milih pakai tabel antrean_pekerjaan untuk menguji SKIP LOCKED
-- ============================================================

-- [SESI_A] Setup tabel antrean (jalankan sekali saja)
CREATE TABLE IF NOT EXISTS lab9.antrean_pekerjaan (
    id SERIAL PRIMARY KEY,
    status TEXT DEFAULT 'pending',
    data TEXT
);

INSERT INTO lab9.antrean_pekerjaan (data) VALUES
('Pekerjaan 1'),
('Pekerjaan 2'),
('Pekerjaan 3'),
('Pekerjaan 4');

-- [SESI_A]
BEGIN;
SELECT * FROM lab9.antrean_pekerjaan 
WHERE status = 'pending' 
ORDER BY id 
LIMIT 1 
FOR UPDATE;
-- Catatan: Dapat id=1
UPDATE lab9.antrean_pekerjaan SET status = 'processing' WHERE id = 1;
-- JANGAN COMMIT dulu

-- [SESI_B]
BEGIN;
SELECT * FROM lab9.antrean_pekerjaan 
WHERE status = 'pending' 
ORDER BY id 
LIMIT 1 
FOR UPDATE SKIP LOCKED;
-- Catatan: Dapat id=2 (skip id=1 yang sudah di-lock SESI_A)
COMMIT;

-- [SESI_A]
COMMIT;


-- ============================================================
-- Q25: NOWAIT
-- Kelompok kami milih pakai FOR UPDATE NOWAIT untuk membuktikan fail-fast behavior
-- ============================================================

-- [SESI_A]
BEGIN;
SELECT * FROM lab9.antrean_pekerjaan WHERE id = 2 FOR UPDATE;
-- JANGAN COMMIT

-- [SESI_B]
BEGIN;
SELECT * FROM lab9.antrean_pekerjaan WHERE id = 2 FOR UPDATE NOWAIT;
-- Catatan: LANGSUNG ERROR (tidak menunggu)
-- Error: ERROR: could not obtain lock on row in relation "antrean_pekerjaan"
-- SQLSTATE: 55P03
ROLLBACK; -- Penting! Rollback setelah error

-- [SESI_A]
COMMIT;


-- ============================================================
-- Q26: Write Skew
-- Kelompok kami milih pakai tabel dokter_jaga dengan aturan minimal 1 dokter aktif
-- ============================================================

-- [SESI_A] Setup tabel dokter (jalankan sekali saja)
CREATE TABLE IF NOT EXISTS lab9.dokter_jaga (
    dokter_id INT PRIMARY KEY,
    nama TEXT,
    aktif BOOLEAN DEFAULT true
);

INSERT INTO lab9.dokter_jaga VALUES
(1, 'Dr. Ani', true),
(2, 'Dr. Budi', true);

-- [SESI_A]
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
-- Catatan: Dapat 2
UPDATE lab9.dokter_jaga SET aktif = false WHERE dokter_id = 1;
-- JANGAN COMMIT dulu

-- [SESI_B]
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
-- Catatan: Dapat 2 (tidak lihat update SESI_A karena REPEATABLE READ)
UPDATE lab9.dokter_jaga SET aktif = false WHERE dokter_id = 2;
COMMIT;

-- [SESI_A]
COMMIT;

-- [SESI_A atau SESI_B] Verifikasi
SELECT * FROM lab9.dokter_jaga;
SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
-- Catatan: Hasil 0 dokter aktif (melanggar aturan bisnis!)
-- Ini adalah WRITE SKEW


-- ============================================================
-- Q27: SERIALIZABLE untuk Mencegah Write Skew
-- Kelompok kami milih pakai SERIALIZABLE untuk membuktikan PostgreSQL mendeteksi write skew
-- ============================================================

-- [SESI_A] Reset data
UPDATE lab9.dokter_jaga SET aktif = true;

-- [SESI_A]
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
-- Catatan: Dapat 2

-- [SESI_B]
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
-- Catatan: Dapat 2

-- [SESI_A]
UPDATE lab9.dokter_jaga SET aktif = false WHERE dokter_id = 1;
COMMIT;

-- [SESI_B]
UPDATE lab9.dokter_jaga SET aktif = false WHERE dokter_id = 2;
COMMIT;
-- Catatan: ERROR!
-- Error: ERROR: could not serialize access due to read/write dependencies among transactions
-- SQLSTATE: 40001
ROLLBACK; -- Penting! Rollback setelah error


-- ============================================================
-- Q28: SIReadLock dan SERIALIZABLE
-- (Dijawab di laporan.md, tidak ada SQL khusus)
-- Tapi bisa dibuktikan dengan query yang sama seperti Q27


-- ============================================================
-- Q29: Retry Logic untuk Serialization Failure
-- (Dijawab di laporan.md dengan pseudocode, tidak ada SQL khusus)
-- Tapi konsepnya:
-- 1. Catch SQLSTATE 40001 atau 40P01
-- 2. ROLLBACK transaksi
-- 3. Tunggu dengan exponential backoff + jitter
-- 4. Retry maksimal N kali
-- 5. Operasi eksternal (email, notifikasi) hanya setelah COMMIT sukses


-- ============================================================
-- Q30: Matriks Anomali
-- (Dijawab di laporan.md, tidak ada SQL khusus)
-- Tapi bisa direproduksi dengan query Q6-Q10 di atas


-- ============================================================
-- Q31: Rekomendasi Isolation Level
-- (Dijawab di laporan.md, tidak ada SQL khusus)
-- Tapi bisa dibuktikan dengan perbandingan Q6 (READ COMMITTED) vs Q7 (REPEATABLE READ) vs Q27 (SERIALIZABLE)


-- ============================================================
-- Q32: Tiga Pelajaran Utama
-- (Dijawab di laporan.md, tidak ada SQL khusus)
-- Tapi didukung oleh bukti dari Q10 (lost update), Q26 (write skew), Q27 (serialization failure)

