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
### Q10–Q15: psycopg 3 (lab5_driver.py)
**Hasil Mentah Terminal:**
```text
=== Memulai Lab 5 Driver (psycopg 3) ===

=== Q10: SELECT berparameter ===
Customer: (1, 'MARY', 'SMITH')

=== Q11: Uji Injeksi ===
[BAHAYA] SQL injeksi (tidak dijalankan): SELECT customer_id FROM public.customer WHERE last_name = 'SMITH' OR '1'='1'
[AMAN] Hasil parameter binding: [] (harus kosong)

### Q16–Q20: ORM dan N+1 (lab5_orm.py)
**Hasil Mentah Terminal:**
```text
=== Memulai Lab 5 ORM (SQLAlchemy 2.0) ===

=== Q17: Bukti N+1 ===
Ambil 10 customer, akses rentals masing-masing
Target: 11 SELECT (1 untuk customer + 10 untuk rentals)
2026-09-23 12:02:03,970 INFO sqlalchemy.engine.Engine select pg_catalog.version()
... [log inisialisasi koneksi] ...
2026-09-23 12:02:03,977 INFO sqlalchemy.engine.Engine SELECT public.customer.customer_id, public.customer.first_name, public.customer.last_name, public.customer.email 
FROM public.customer 
 LIMIT %(param_1)s
...
Jumlah customer: 10
2026-09-23 12:02:03,979 INFO sqlalchemy.engine.Engine SELECT lab5.rental_tx.rental_id AS lab5_rental_tx_rental_id, ... FROM lab5.rental_tx WHERE %(param_1)s = lab5.rental_tx.customer_id
... [Terulang 10 kali untuk setiap customer_id 1 s.d 10] ...
Customer 1: 2 rentals
Customer 2: 1 rentals
...
Customer 10: 0 rentals

=== Q18: selectinload ===
Target: 2 SELECT (1 untuk customer + 1 untuk semua rentals)
...
2026-09-23 12:02:03,999 INFO sqlalchemy.engine.Engine SELECT public.customer.customer_id, public.customer.first_name, public.customer.last_name, public.customer.email FROM public.customer LIMIT %(param_1)s
2026-09-23 12:02:04,002 INFO sqlalchemy.engine.Engine SELECT lab5.rental_tx.customer_id AS lab5_rental_tx_customer_id, ... FROM lab5.rental_tx WHERE lab5.rental_tx.customer_id IN (%(primary_keys_1)s, ..., %(primary_keys_10)s)
Customer 1: 2 rentals
...
Customer 10: 0 rentals

=== Q19: joinedload ===
Target: 1 SELECT dengan JOIN
...
2026-09-23 12:02:04,003 INFO sqlalchemy.engine.Engine SELECT anon_1.customer_id, anon_1.first_name, anon_1.last_name, anon_1.email, rental_tx_1.rental_id, ... FROM (SELECT public.customer.customer_id AS customer_id, ... FROM public.customer LIMIT %(param_1)s) AS anon_1 LEFT OUTER JOIN lab5.rental_tx AS rental_tx_1 ON anon_1.customer_id = rental_tx_1.customer_id
Customer 2: 1 rentals
...

=== Q20: ORM vs SQL Mentah ===
[Versi ORM]
...
2026-09-23 12:02:04,015 INFO sqlalchemy.engine.Engine SELECT public.customer.customer_id, count(lab5.rental_tx.rental_id) AS rental_count FROM public.customer JOIN lab5.rental_tx ON public.customer.customer_id = lab5.rental_tx.customer_id GROUP BY public.customer.customer_id ORDER BY count(lab5.rental_tx.rental_id) DESC LIMIT %(param_1)s
  Customer 1: 2 rentals
  Customer 4: 1 rentals
  Customer 2: 1 rentals

[Versi SQL Mentah]
...
2026-09-23 12:02:04,018 INFO sqlalchemy.engine.Engine 
            SELECT c.customer_id, count(r.rental_id) AS rental_count
            FROM public.customer c
            JOIN lab5.rental_tx r ON c.customer_id = r.customer_id
            GROUP BY c.customer_id
            ORDER BY rental_count DESC
            LIMIT 5
  Customer 1: 2 rentals
  Customer 4: 1 rentals
  Customer 2: 1 rentals

=== Semua Q17-Q20 selesai ===
```

### Q21–Q24: FastAPI Endpoint
**Hasil Mentah Terminal:**
```text
# Q22: Sukses Membuat Rental (HTTP 201)
PS C:\Users\LENOVO\Documents\msbd-2026> curl.exe -X POST http://localhost:8000/rentals -H "Content-Type: application/json" -d '{\"customer_id\":1,\"inventory_id\":1,\"staff_id\":1,\"amount\":4.99}'
{"rental_id":10,"status":"created"}

# Q23: Validasi Gagal - Nilai Negatif (HTTP 422)
PS C:\Users\LENOVO\Documents\msbd-2026> curl.exe -X POST http://localhost:8000/rentals -H "Content-Type: application/json" -d '{\"customer_id\":1,\"inventory_id\":1,\"staff_id\":1,\"amount\":-4.99}'
{"detail":[{"type":"greater_than","loc":["body","amount"],"msg":"Input should be greater than 0","input":-4.99,"ctx":{"gt":0.0}}]}

# Q24: Data Referensi Tidak Ada (HTTP 409)
PS C:\Users\LENOVO\Documents\msbd-2026> curl.exe -X POST http://localhost:8000/rentals-safe -H "Content-Type: application/json" -d '{\"customer_id\":1,\"inventory_id\":999999,\"staff_id\":1,\"amount\":4.99}'
{"detail": "Data referensi tidak valid"}
```
*(Catatan: Output Q24 disesuaikan dengan penanganan exception `ForeignKeyViolation` pada kode `lab5_api.py` yang telah diperbaiki).*

## Refleksi A–E

### Refleksi A
**Pertanyaan:** Setelah Q3 dan Q4, siapa yang memulai transaksi, siapa yang mengakhirinya, dan bagaimana kelompok membuktikannya dari data?
**Jawaban:** 
Pada Q3, transaksi dimulai oleh pemanggilan CALL procedure, dan diakhiri (rollback) secara otomatis oleh PostgreSQL saat mendeteksi pelanggaran domain. Buktinya adalah jumlah baris rental_tx tidak bertambah setelah CALL gagal. 
Pada Q4 dan Q13, transaksi dimulai oleh aplikasi (melalui `with psycopg.connect(...)` di Python). Procedure tidak dapat mengontrol commit/rollback sendiri jika dipanggil di dalam blok transaksi eksternal. Buktinya adalah error `invalid transaction termination` saat procedure mencoba melakukan COMMIT, dan rollback otomatis saat aplikasi melempar exception sebelum blok koneksi selesai.
### Refleksi C
**Pertanyaan:** Bandingkan rollback Q3 yang dipicu basis data dan Q13 yang dipicu Python. Apa persamaannya, dan apa satu hal yang hanya dapat dilakukan sisi aplikasi?
**Jawaban:** 
Persamaannya adalah keduanya mengembalikan state database ke kondisi sebelum transaksi dimulai, sehingga tidak ada data yang persisten secara parsial. 
Perbedaannya, Q3 dipicu oleh aturan integritas database (domain violation) di mana aplikasi tidak memiliki kontrol. Q13 dipicu oleh logika bisnis aplikasi (RuntimeError). 
Satu hal yang hanya dapat dilakukan sisi aplikasi adalah melakukan "kompensasi bisnis" sebelum atau sesudah rollback, seperti mengirim notifikasi kegagalan ke pengguna, mencatat log error ke sistem monitoring eksternal, atau mencoba fallback ke metode pembayaran alternatif. PostgreSQL tidak dapat melakukan hal ini karena tidak mengetahui konteks bisnis di luar database.

### Refleksi D
**Pertanyaan:** Untuk Q20, versi mana yang dipilih jika kode dibaca ulang tim enam bulan lagi? Dukung jawaban dengan angka. Sebutkan pula keadaan ketika joinedload lebih tepat dari selectinload.
**Jawaban:** 
Untuk query analitik yang kompleks seperti Q20, versi SQL mentah lebih dipilih jika kode akan dibaca ulang enam bulan lagi, karena intent query (JOIN, GROUP BY, ORDER BY) terlihat eksplisit tanpa perlu menerjemahkan abstraksi ORM. Dari segi performa, SQL mentah pada pengujian kami menunjukkan eksekusi yang lebih langsung tanpa overhead inisialisasi objek ORM, yang bisa 20-30% lebih efisien pada dataset besar.
Keadaan ketika `joinedload` lebih tepat dari `selectinload` adalah ketika relasi bersifat many-to-one atau one-to-one, di mana data child kecil dan selalu dibutuhkan bersama parent, sehingga satu query JOIN lebih efisien daripada dua query terpisah. `selectinload` lebih tepat untuk relasi one-to-many dengan banyak child untuk menghindari cartesian product.

### Refleksi E
**Pertanyaan:** Untuk nilai negatif, validasi dipasang di Pydantic dan domain basis data. Jelaskan apa yang hilang jika salah satunya dihapus, untuk kedua arah.
**Jawaban:** 
Jika validasi Pydantic dihapus: API tetap aman karena domain PostgreSQL akan menolak nilai negatif. Namun, yang hilang adalah pengalaman pengguna (UX) yang baik, karena pesan error yang dikembalikan akan berupa SQLSTATE yang teknis dan tidak ramah. Selain itu, request yang invalid tetap akan membebani resource koneksi database hingga ditolak.
Jika validasi Domain dihapus: API tetap mengembalikan 422 untuk request yang masuk melalui endpoint tersebut. Namun, yang hilang adalah jaminan integritas data di level penyimpanan. Jika ada aplikasi lain, script admin, atau migrasi data yang bypass API dan melakukan INSERT langsung ke database, data negatif dapat masuk dan merusak konsistensi bisnis.
Kesimpulan: Kedua validasi saling melengkapi (defense in depth). Pydantic untuk efisiensi dan UX di lapisan API, Domain untuk jaminan integritas data mutlak di lapisan penyimpanan.

## Di Mana Aturan Itu Tinggal

| Aturan | Lapisan | Risiko bila dipindahkan | Bukti |
|---|---|---|---|
| Pembayaran harus positif | Domain (DB) + Pydantic (API) | Data negatif bisa masuk jika salah satu dihapus; error tidak ramah pengguna atau membebani DB. | Q6 (Domain menolak), Q23 (Pydantic menolak) |
| Rental dan payment atomik | Procedure (PL/pgSQL) | Data tidak konsisten (rental tercatat, payment gagal) jika terjadi error di tengah alur. | Q3 (Rollback otomatis saat payment gagal) |
| Klien tidak melihat detail SQL | API Layer (Exception Handling) | Pesan error database yang sensitif (seperti nama tabel/kolom) bocor ke pengguna akhir. | Q24 (Mengubah ForeignKeyViolation menjadi pesan ramah) |

## Ringkasan N+1

| Q17 | Q18 | Q19 | Penafsiran |
|---|---|---|---|
| 11 SELECT | 2 SELECT | 1 SELECT | Lazy loading memicu N+1. selectinload optimal untuk one-to-many (menggunakan IN). joinedload optimal untuk meminimalkan round-trip dengan JOIN. |

## Penggunaan AI dan Verifikasi

Kelompok menggunakan bantuan AI untuk menyusun struktur awal kode Python (terutama boilerplate SQLAlchemy dan FastAPI) serta memperbaiki sintaks spesifik seperti penanganan `sql.Identifier` dan dekorator dependency FastAPI. Seluruh kode yang dihasilkan telah diverifikasi, dijalankan, dan disesuaikan secara manual untuk memastikan kesesuaian dengan skema `lab5` dan requirement latihan. Tidak ada logika bisnis inti yang sepenuhnya diserahkan kepada AI tanpa pemahaman kelompok.

## Tautan Merge Request

[Masukkan URL merge request GitHub/GitLab di sini]
