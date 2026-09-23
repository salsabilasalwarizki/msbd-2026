# Laporan Latihan Kelompok Pertemuan 5

## Anggota dan Kontribusi

| Nama | NIM | Kontribusi | Commit |
|---|---|---|---|
| Salsabila Salwa Rizki | 251402123 | Q1-Q5, Refleksi A, setup q00 | Tersedia di riwayat Git |
| Nadia Stevany Br Situmorang | 251402073 | Q6-Q9, Refleksi B | Tersedia di riwayat Git |
| Sina Mahdi Sitanggang | 251402008 | Q10-Q15, Refleksi C, lab5_driver.py | Tersedia di riwayat Git |
| Jesqueen Maria Purba | 251402099 | Q16-Q24, Refleksi D-E, R1, lab5_orm.py, lab5_api.py | Tersedia di riwayat Git |

## Versi dan Lingkungan

- psycopg: 3.2.13
- SQLAlchemy: 2.0.54
- FastAPI: 0.115.14
- PostgreSQL: 17.11 (Debian 17.11-1.pgdg13+2)
- Jumlah customer: 599

## Q1–Q24

### Q1: total_dibayar function
**Perintah:** Membuat function lab5.total_dibayar(p_rental_id bigint) dan mengujinya.
**Keluaran:** 
```sql
CREATE FUNCTION
 total_belum_ada: 0
 total_ada: 7.49
```
**Alasan:** Menggunakan LANGUAGE sql STABLE karena hanya melakukan agregasi SELECT tanpa side effect, lebih efisien daripada plpgsql untuk kasus sederhana.

### Q2: process_rental procedure
**Perintah:** Menjalankan procedure lab5.process_rental dengan nilai sah.
**Keluaran:** 
```sql
CREATE PROCEDURE
 rental_sebelum: 1, payment_sebelum: 2
CALL
 rental_sesudah: 2, payment_sesudah: 3
```
**Alasan:** Procedure menjamin atomicity. Satu pemanggilan berhasil menghasilkan 1 baris baru di rental_tx dan 1 baris baru di payment_tx secara bersamaan.

### Q3: Buktikan rollback
**Perintah:** Memanggil procedure dengan p_amount = -4.99.
**Keluaran:** 
```sql
ERROR: value for domain lab5.positive_amount violates check constraint "positive_amount_check"
 rental_sesudah: 2 (tidak bertambah)
```
**Alasan:** Domain positive_amount menolak nilai negatif. Karena berada dalam satu blok transaksi, INSERT ke rental_tx juga di-rollback, sehingga jumlah baris tetap sama.

### Q4: Commit dalam procedure
**Perintah:** Membuat salinan procedure dengan COMMIT setelah INSERT pertama.
**Keluaran:** 
```sql
CREATE PROCEDURE
CALL berhasil jika dipanggil langsung dari psql.
```
**Alasan:** COMMIT di dalam procedure hanya diizinkan jika procedure dipanggil di luar blok transaksi eksplisit. Jika dipanggil dari dalam `with psycopg.connect()` di Python, akan menghasilkan error `invalid transaction termination`.

### Q5: Exception FK
**Perintah:** Menambahkan EXCEPTION WHEN foreign_key_violation.
**Keluaran:** 
```sql
NOTICE: Data referensi tidak valid: customer, inventory, atau staff tidak ditemukan.
 count: 3 (tidak bertambah)
```
**Alasan:** Menangkap error tingkat rendah database dan mengubahnya menjadi NOTICE yang lebih ramah. Informasi detail SQLSTATE hilang, tetapi ini layak dilakukan untuk endpoint API agar tidak membocorkan struktur database.

## Refleksi A–E

### Refleksi A
**Pertanyaan:** Setelah Q3 dan Q4, siapa yang memulai transaksi, siapa yang mengakhirinya, dan bagaimana kelompok membuktikannya dari data?
**Jawaban:** 
Pada Q3, transaksi dimulai oleh pemanggilan CALL procedure, dan diakhiri (rollback) secara otomatis oleh PostgreSQL saat mendeteksi pelanggaran domain. Buktinya adalah jumlah baris rental_tx tidak bertambah setelah CALL gagal. 
Pada Q4 dan Q13, transaksi dimulai oleh aplikasi (melalui `with psycopg.connect(...)` di Python). Procedure tidak dapat mengontrol commit/rollback sendiri jika dipanggil di dalam blok transaksi eksternal. Buktinya adalah error `invalid transaction termination` saat procedure mencoba melakukan COMMIT, dan rollback otomatis saat aplikasi melempar exception sebelum blok koneksi selesai.
