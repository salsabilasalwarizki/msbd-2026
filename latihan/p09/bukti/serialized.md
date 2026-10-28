# Bukti Eksperimen SKIP LOCKED, NOWAIT, dan SERIALIZABLE

## Pendahuluan
Di bagian ini, kelompok kami menguji fitur-fitur advanced PostgreSQL kayak SKIP LOCKED, NOWAIT, dan isolation level SERIALIZABLE. Kami pakai dua terminal terpisah (SESI_A dan SESI_B) yang terhubung ke database `latihan` dengan skema `lab9`. Tujuannya adalah buat ngerti gimana PostgreSQL handle skenario konkurensi yang kompleks.

## Eksperimen 1: SKIP LOCKED (Q24)

### Skenario
Kami buat tabel `antrean_pekerjaan` dengan beberapa baris pekerjaan. SESI_A lock satu baris, terus SESI_B coba ambil baris lain dengan SKIP LOCKED. Ini skenario yang umum di sistem message queue atau job scheduler.

### Setup Tabel
```sql
latihan=# CREATE TABLE lab9.antrean_pekerjaan (
    id SERIAL PRIMARY KEY,
    status TEXT DEFAULT 'pending',
    data TEXT
);
CREATE TABLE

latihan=# INSERT INTO lab9.antrean_pekerjaan (data) VALUES
('Pekerjaan 1'),
('Pekerjaan 2'),
('Pekerjaan 3'),
('Pekerjaan 4');
INSERT 0 4
```

### Hasil yang Kami Amati

**SESI_A (ambil pekerjaan pertama):**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.antrean_pekerjaan 
WHERE status = 'pending' 
ORDER BY id 
LIMIT 1 
FOR UPDATE;
 id | status  |    data     
----+---------+-------------
  1 | pending | Pekerjaan 1
(1 row)

latihan=# UPDATE lab9.antrean_pekerjaan SET status = 'processing' WHERE id = 1;
UPDATE 1
-- JANGAN COMMIT dulu, biarkan transaksi terbuka
```

**SESI_B (ambil pekerjaan berikutnya dengan SKIP LOCKED):**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.antrean_pekerjaan 
WHERE status = 'pending' 
ORDER BY id 
LIMIT 1 
FOR UPDATE SKIP LOCKED;
 id | status  |    data     
----+---------+-------------
  2 | pending | Pekerjaan 2
(1 row)

latihan=# COMMIT;
COMMIT
```

**SESI_A (setelah selesai):**
```sql
latihan=# COMMIT;
COMMIT
```

### Analisis
SKIP LOCKED itu keren banget buat skenario worker antrean. SESI_B tidak perlu nunggu SESI_A selesai, langsung skip baris yang di-lock dan ambil baris berikutnya yang available. Maka, banyak worker bisa proses pekerjaan berbeda secara paralel tanpa saling blokir. Ini cocok banget buat sistem message queue kayak RabbitMQ atau job scheduler kayak Sidekiq. Terus, tidak ada lost update karena setiap worker dapat pekerjaan yang berbeda.

## Eksperimen 2: NOWAIT (Q25)

### Skenario
Kami ulang skenario lock, tapi pakai NOWAIT buat membuktikan fail-fast behavior. Beda sama SKIP LOCKED yang skip baris, NOWAIT langsung error kalau baris tidak bisa di-lock.

### Hasil yang Kami Amati

**SESI_A (lock baris id=2):**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.antrean_pekerjaan WHERE id = 2 FOR UPDATE;
 id | status  |    data     
----+---------+-------------
  2 | pending | Pekerjaan 2
(1 row)
-- JANGAN COMMIT dulu
```

**SESI_B (coba lock baris yang sama dengan NOWAIT):**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SELECT * FROM lab9.antrean_pekerjaan WHERE id = 2 FOR UPDATE NOWAIT;
ERROR:  could not obtain lock on row in relation "antrean_pekerjaan"

latihan=# ROLLBACK;
ROLLBACK
```

**SESI_A (setelah SESI_B error):**
```sql
latihan=# COMMIT;
COMMIT
```

### Analisis
NOWAIT itu kebalikan dari SKIP LOCKED. Kalau SKIP LOCKED skip baris yang di-lock dan ambil baris lain, NOWAIT langsung error kalau baris yang diminta tidak bisa di-lock. Maka, NOWAIT cocok buat aplikasi yang perlu fail-fast (gagal cepat, coba lagi nanti). Contohnya kayak sistem yang mau cek ketersediaan resource tanpa blocking, atau sistem yang mau implementasi optimistic locking. Terus, SQLSTATE untuk error ini adalah 55P03 (lock_not_available).

## Eksperimen 3: Write Skew (Q26)

### Skenario
Kami buat tabel `dokter_jaga` dengan aturan bisnis: minimal 1 dokter harus aktif. Terus kami coba dua transaksi REPEATABLE READ yang masing-masing nonaktifkan dokter berbeda. Ini skenario klasik write skew.

### Setup Tabel
```sql
latihan=# CREATE TABLE lab9.dokter_jaga (
    dokter_id INT PRIMARY KEY,
    nama TEXT,
    aktif BOOLEAN DEFAULT true
);
CREATE TABLE

latihan=# INSERT INTO lab9.dokter_jaga VALUES
(1, 'Dr. Ani', true),
(2, 'Dr. Budi', true);
INSERT 0 2
```

### Hasil yang Kami Amati

**SESI_A:**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET
latihan=# SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
 aktif 
-------
     2
(1 row)

latihan=# UPDATE lab9.dokter_jaga SET aktif = false WHERE dokter_id = 1;
UPDATE 1
-- JANGAN COMMIT dulu
```

**SESI_B:**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET
latihan=# SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
 aktif 
-------
     2
(1 row)

latihan=# UPDATE lab9.dokter_jaga SET aktif = false WHERE dokter_id = 2;
UPDATE 1

latihan=# COMMIT;
COMMIT
```

**SESI_A:**
```sql
latihan=# COMMIT;
COMMIT
```

**Verifikasi:**
```sql
latihan=# SELECT * FROM lab9.dokter_jaga;
 dokter_id |  nama   | aktif 
-----------+---------+-------
         1 | Dr. Ani | f
         2 | Dr. Budi| f
(2 rows)

latihan=# SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
 aktif 
-------
     0
(1 row)
```

### Analisis
Kedua transaksi COMMIT berhasil karena di REPEATABLE READ tidak ada konflik yang terdeteksi. Masing-masing transaksi lihat snapshot yang sama (2 dokter aktif) dan update dokter yang berbeda. Tapi hasilnya, aturan bisnis "minimal 1 dokter aktif" dilanggar! Ini yang disebut write skew. Maka, REPEATABLE READ tidak cukup buat cegah anomali kompleks kayak write skew. Solusinya adalah pakai SERIALIZABLE atau tambah constraint eksplisit.

## Eksperimen 4: SERIALIZABLE (Q27)

### Skenario
Kami ulang skenario Q26 tapi pakai SERIALIZABLE buat membuktikan PostgreSQL bisa deteksi write skew. Ini isolation level paling ketat di PostgreSQL.

### Reset Data
```sql
latihan=# UPDATE lab9.dokter_jaga SET aktif = true;
UPDATE 2
```

### Hasil yang Kami Amati

**SESI_A:**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET
latihan=# SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
 aktif 
-------
     2
(1 row)

latihan=# UPDATE lab9.dokter_jaga SET aktif = false WHERE dokter_id = 1;
UPDATE 1

latihan=# COMMIT;
COMMIT
```

**SESI_B:**
```sql
latihan=# BEGIN;
BEGIN
latihan=# SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET
latihan=# SELECT COUNT(*) AS aktif FROM lab9.dokter_jaga WHERE aktif = true;
 aktif 
-------
     2
(1 row)

latihan=# UPDATE lab9.dokter_jaga SET aktif = false WHERE dokter_id = 2;
UPDATE 1

latihan=# COMMIT;
ERROR:  could not serialize access due to read/write dependencies among transactions
DETAIL:  Reason code: Canceled on identification as a pivot, during commit attempt.
HINT:  The transaction might succeed if retried.

latihan=# ROLLBACK;
ROLLBACK
```

### Analisis
SERIALIZABLE deteksi write skew dan tolak salah satu transaksi dengan error 40001. Maka, aturan bisnis tetap terjaga karena hanya satu dokter yang bisa dinonaktifkan. Tapi konsekuensinya, aplikasi harus implementasi retry logic buat handle serialization failure. Terus, error ini muncul di COMMIT, bukan di UPDATE, karena PostgreSQL pakai deferred checking untuk SERIALIZABLE.

## Eksperimen 5: SIReadLock (Q28)

### Penjelasan Konseptual
PostgreSQL pakai predicate locking buat SERIALIZABLE, bukan row locking kayak FOR UPDATE. Artinya, yang di-lock itu predikat (kondisi WHERE), bukan baris spesifik.

Contoh: `SELECT COUNT(*) WHERE aktif = true` mengunci predikat "aktif = true". Kalau ada transaksi lain yang UPDATE baris dengan `aktif = true`, akan terdeteksi sebagai konflik.

### Cara Lihat SIReadLock
```sql
latihan=# SELECT * FROM pg_locks WHERE locktype = 'transactionid';
```

### Analisis
Maka, SERIALIZABLE itu lebih efisien daripada lock semua baris karena cuma lock predikat yang relevan. Tapi tetap bisa deteksi anomali kompleks kayak write skew. Lalu, pembaca tidak blokir penulis karena MVCC tetap berlaku. Ini yang bikin SERIALIZABLE di PostgreSQL lebih scalable dibanding database lain yang pakai strict two-phase locking.

## Eksperimen 6: Retry Logic (Q29)

### Pseudocode yang Kami Susun
```python
import time
import random

def execute_transaction_with_retry(max_retries=5):
    for attempt in range(max_retries):
        try:
            BEGIN;
            SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
            
            # Baca data
            SELECT COUNT(*) AS aktif FROM dokter_jaga WHERE aktif = true;
            
            # Validasi bisnis
            if aktif < 2:
                ROLLBACK;
                return False  # Aturan bisnis dilanggar
            
            # Update
            UPDATE dokter_jaga SET aktif = false WHERE dokter_id = 1;
            
            COMMIT;
            return True  # Sukses
            
        except SerializationFailure as e:  # SQLSTATE 40001
            if attempt < max_retries - 1:
                ROLLBACK;
                # Exponential backoff dengan jitter
                delay = (2 ** attempt) + random.uniform(0, 1)
                time.sleep(delay)
                continue
            else:
                ROLLBACK;
                raise Exception("Max retries exceeded")
                
        except DeadlockDetected as e:  # SQLSTATE 40P01
            # Sama seperti serialization failure, bisa retry
            if attempt < max_retries - 1:
                ROLLBACK;
                delay = (2 ** attempt) + random.uniform(0, 1)
                time.sleep(delay)
                continue
            else:
                ROLLBACK;
                raise Exception("Max retries exceeded")
```

### Analisis
Retry logic itu wajib kalau pakai SERIALIZABLE karena ada risiko serialization failure. Kami pakai exponential backoff dengan jitter buat cegah thundering herd (banyak transaksi retry bersamaan). Lalu, operasi eksternal kayak kirim email atau notifikasi harus dilakukan SETELAH COMMIT sukses, bukan sebelum. Alasannya, kalau transaksi di-rollback, operasi eksternal sudah terlanjur dan tidak bisa di-undo. Ini yang disebut "side effect" dan harus dihindari di dalam transaksi.

## Kesimpulan

Dari eksperimen SKIP LOCKED, NOWAIT, dan SERIALIZABLE, kami dapat beberapa pelajaran penting:

1. **SKIP LOCKED** cocok buat worker antrean yang perlu proses pekerjaan berbeda secara paralel. Tidak ada blocking, tidak ada error.
2. **NOWAIT** cocok buat aplikasi yang perlu fail-fast tanpa blocking. Langsung error kalau tidak bisa lock.
3. **Write skew** bisa terjadi di REPEATABLE READ dan melanggar aturan bisnis. Ini anomali yang tricky karena tidak terdeteksi oleh isolation level yang lebih rendah.
4. **SERIALIZABLE** bisa deteksi write skew tapi butuh retry logic untuk handle error 40001. Error muncul di COMMIT, bukan di UPDATE.
5. **Predicate locking** (SIReadLock) lebih efisien daripada row locking untuk SERIALIZABLE. Cuma lock predikat yang relevan.
6. **Retry dengan exponential backoff + jitter** adalah best practice untuk handle serialization failure. Jangan lupa ROLLBACK sebelum retry.
7. **Operasi eksternal** (email, notifikasi, API call) harus dilakukan SETELAH COMMIT sukses, bukan di dalam transaksi.

Maka, pilihan antara REPEATABLE READ dan SERIALIZABLE harus dipertimbangkan dengan matang. REPEATABLE READ lebih cepat tapi rentan write skew, sedangkan SERIALIZABLE lebih aman tapi butuh retry logic yang kompleks. Terus, untuk skenario worker antrean, SKIP LOCKED adalah pilihan yang paling tepat karena memberikan concurrency tinggi tanpa risiko deadlock.
```

