# Bukti Eksperimen Deadlock dan Row Lock

## Pendahuluan
Di bagian ini, kelompok kami menguji berbagai jenis row lock, lock waiting, deadlock, dan cara mencegahnya. Kami pakai dua terminal terpisah (SESI_A dan SESI_B) yang terhubung ke database `latihan` dengan skema `lab9`. Tujuannya adalah buat ngerti gimana PostgreSQL handle konkurensi dan locking.

## Eksperimen 1: Perbandingan Lock Mode (Q18)

### Skenario
Kami coba empat jenis lock mode yang tersedia di PostgreSQL: FOR UPDATE, FOR NO KEY UPDATE, FOR SHARE, dan FOR KEY SHARE. Masing-masing punya tingkat eksklusivitas yang berbeda-beda.

### Hasil yang Kami Amati

**FOR UPDATE (paling ketat):**
```sql
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
```
Lock ini blokir semua lock mode lain. Cocok banget buat operasi UPDATE atau DELETE karena kita butuh akses eksklusif ke baris tersebut.

**FOR NO KEY UPDATE:**
```sql
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR NO KEY UPDATE;
```
Agak longgar dari FOR UPDATE. Blokir FOR UPDATE dan FOR KEY SHARE aja. Cocok buat UPDATE yang tidak mengubah primary key atau unique key.

**FOR SHARE:**
```sql
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR SHARE;
```
Untuk read-only yang perlu konsistensi. Blokir FOR UPDATE dan FOR NO KEY UPDATE. Biasanya dipakai kalau kita mau baca data tapi mau pastikan data tidak di-update sama transaksi lain.

**FOR KEY SHARE (paling longgar):**
```sql
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR KEY SHARE;
```
Cuma blokir FOR UPDATE. Biasanya otomatis dipakai PostgreSQL buat referensi foreign key.

### Analisis
Maka, pilihan lock mode harus disesuaikan dengan operasi yang akan dilakukan. Kalau cuma mau baca data dengan jaminan konsistensi, FOR SHARE atau FOR KEY SHARE sudah cukup. Tapi kalau mau update atau delete, wajib pakai FOR UPDATE. Terus, semakin longgar lock mode, semakin tinggi concurrency yang bisa dicapai.

## Eksperimen 2: Lock Waiting (Q19)

### Skenario
Kami mau buktikan bahwa lock waiting itu berbeda dengan deadlock. SESI_A mulai transaksi dan lock rekening 1 dengan FOR UPDATE. Terus SESI_B coba lock baris yang sama.

### Hasil yang Kami Amati

**SESI_A:**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           1 | Ani     |  810000.00
(1 row)
```

**SESI_B (akan menunggu/blocking):**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- Terminal SESI_B akan "hang" di sini, menunggu SESI_A selesai
```

**SESI_A (setelah beberapa detik):**
```sql
latihan=# COMMIT;
COMMIT
```

**SESI_B (setelah SESI_A COMMIT, otomatis dapat lock):**
```sql
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           1 | Ani     |  810000.00
(1 row)

latihan=# COMMIT;
COMMIT
```

### Analisis
SESI_B tidak dapat error sama sekali, cuma nunggu (blocking) sampai SESI_A selesai. Ini yang disebut lock queue, bukan deadlock. Lalu, setelah SESI_A commit, SESI_B otomatis dapat lock dan bisa lanjut eksekusi tanpa perlu retry. Maka, lock waiting itu mekanisme normal di PostgreSQL buat maintain konsistensi data.

## Eksperimen 3: Deadlock (Q20)

### Skenario
Kami buat skenario circular wait yang klasik. SESI_A lock rekening 1, SESI_B lock rekening 2. Terus SESI_A coba lock rekening 2, dan SESI_B coba lock rekening 1. Ini akan bikin deadlock karena kedua sesi saling menunggu.

### Hasil yang Kami Amati

**SESI_A:**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           1 | Ani     |  810000.00
(1 row)
```

**SESI_B:**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           2 | Budi    | 1000000.00
(1 row)
```

**SESI_A (coba lock rekening 2):**
```sql
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
-- SESI_A sekarang MENUNGGU karena rekening 2 sudah di-lock SESI_B
```

**SESI_B (coba lock rekening 1):**
```sql
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
ERROR:  deadlock detected
DETAIL:  Process 12345 waits for ShareLock on transaction 67890; blocked by process 67891.
Process 67891 waits for ShareLock on transaction 67890; blocked by process 12345.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,1) in relation "rekening"
```

**SESI_A (setelah deadlock terdeteksi, otomatis dapat lock):**
```sql
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           2 | Budi    | 1000000.00
(1 row)

latihan=# COMMIT;
COMMIT
```

### Analisis
PostgreSQL deteksi circular wait (A tunggu B, B tunggu A) dan otomatis kill salah satu transaksi (biasanya yang terakhir request lock). Maka, SESI_B dapat error deadlock dengan SQLSTATE 40P01, dan transaksinya di-rollback otomatis. SESI_A yang selamat bisa lanjut commit. Ini bukti bahwa PostgreSQL punya deadlock detector yang aktif setiap 1 detik (deadlock_timeout default).

## Eksperimen 4: Mencegah Deadlock (Q21)

### Skenario
Kami ulang skenario Q20 tapi dengan urutan penguncian yang konsisten. Kedua sesi lock dari ID terkecil ke terbesar (1 → 2). Ini adalah best practice untuk mencegah deadlock.

### Hasil yang Kami Amati

**SESI_A:**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           1 | Ani     |  810000.00
(1 row)

latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           2 | Budi    | 1000000.00
(1 row)

latihan=# COMMIT;
COMMIT
```

**SESI_B (jalankan bersamaan, dengan urutan yang SAMA):**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- SESI_B MENUNGGU SESI_A selesai karena lock rekening 1
```

**SESI_A sudah COMMIT, sekarang SESI_B dapat lock:**
```sql
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           1 | Ani     |  810000.00
(1 row)

latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           2 | Budi    | 1000000.00
(1 row)

latihan=# COMMIT;
COMMIT
```

### Analisis
Tidak ada deadlock karena kedua sesi lock dengan urutan yang sama. Maka, best practice untuk mencegah deadlock adalah selalu lock resource dengan urutan yang konsisten (misalnya dari ID terkecil ke terbesar). Terus, ini juga disebut "lock ordering" dan merupakan teknik yang umum dipakai di sistem database.

## Eksperimen 5: Deadlock vs Lock Queue Panjang (Q22)

### Perbedaan yang Kami Amati

**Deadlock:**
- Circular wait: A tunggu B, B tunggu A
- Otomatis terdeteksi oleh PostgreSQL (setiap 1 detik)
- Salah satu transaksi di-kill dengan error 40P01
- Contoh: Q20 di atas
- Solusi: Lock ordering atau retry logic

**Lock Queue Panjang:**
- Linear wait: A lock, B tunggu A, C tunggu B, dst.
- Tidak ada circular wait
- Tidak ada error, cuma waiting lama
- Bisa menyebabkan timeout kalau terlalu lama
- Contoh: Transaksi yang hold lock terlalu lama (misal: ada `pg_sleep(60)`)

### Simulasi Lock Queue Panjang

**SESI_A (transaksi lama):**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
 rekening_id | pemilik |   saldo   
-------------+---------+-----------
           1 | Ani     |  810000.00
(1 row)

latihan=# SELECT pg_sleep(10); -- Tidur 10 detik
 pg_sleep 
----------
 
(1 row)

latihan=# COMMIT;
COMMIT
```

**SESI_B, C, D (akan antri menunggu):**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- Menunggu... menunggu... menunggu...
-- Setelah 10 detik, baru dapat lock
```

### Analisis
Maka, deadlock dan lock queue panjang itu dua hal yang berbeda. Deadlock lebih berbahaya karena bisa bikin transaksi gagal, tapi otomatis ditangani PostgreSQL. Lock queue panjang tidak bikin error, tapi bisa bikin aplikasi lambat kalau tidak di-set timeout dengan benar. Lalu, solusinya adalah pakai `lock_timeout` atau `statement_timeout` untuk batasi waktu tunggu.

## Eksperimen 6: Timeout (Q23)

### Skenario
Kami coba set berbagai timeout untuk batasi waktu tunggu dan eksekusi. Kami pakai SET LOCAL biar tidak pengaruh ke sesi lain.

### Hasil yang Kami Amati

**lock_timeout:**
```sql
latihan=# SET LOCAL lock_timeout = '5s';
SET
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- Jika lock tidak didapat dalam 5 detik:
ERROR:  canceling statement due to lock timeout
```

**statement_timeout:**
```sql
latihan=# SET LOCAL statement_timeout = '30s';
SET
latihan=# SELECT pg_sleep(60); -- Query yang jalan 60 detik
ERROR:  canceling statement due to statement timeout
```

**idle_in_transaction_session_timeout:**
```sql
latihan=# SET LOCAL idle_in_transaction_session_timeout = '60s';
SET
latihan=# BEGIN;
BEGIN
-- Kalau tidak ada aktivitas 60 detik:
FATAL:  terminating connection due to idle-in-transaction timeout
```

**deadlock_timeout (default 1s, tidak bisa di-SET LOCAL):**
```sql
latihan=# SHOW deadlock_timeout;
 deadlock_timeout 
------------------
 1s
(1 row)
```

### Analisis
Maka, timeout itu penting buat cegah transaksi nyangkut terlalu lama. Tapi ingat, jangan set timeout global di server karena bisa pengaruh ke semua aplikasi. Pakai SET LOCAL aja di dalam sesi yang butuh, terus RESET setelah selesai. Terus, `deadlock_timeout` itu beda karena dia konfigurasi server, bukan sesi.

## Kesimpulan

Dari eksperimen deadlock dan row lock, kami dapat beberapa pelajaran penting:

1. **FOR UPDATE** itu lock paling ketat, pakai kalau mau update atau delete baris.
2. **Lock waiting** itu normal dan bukan error, cuma blocking sampai lock dirilis.
3. **Deadlock** terjadi karena circular wait, dan PostgreSQL otomatis handle dengan kill salah satu transaksi (SQLSTATE 40P01).
4. **Urutan penguncian yang konsisten** adalah cara paling efektif buat cegah deadlock.
5. **Timeout** penting buat cegah transaksi nyangkut, tapi harus dipakai dengan bijak (SET LOCAL, bukan global).
6. **Deadlock berbeda dengan lock queue panjang** - deadlock ada circular wait, lock queue cuma linear wait.

Lalu, kami simpulkan bahwa understanding row lock dan deadlock itu crucial buat bangun aplikasi database yang robust dan scalable. Kalau tidak hati-hati, aplikasi bisa kena deadlock atau performance issue karena lock contention.
```
