# Laporan Latihan Kelompok Pertemuan 11
## Keamanan, Kontrol Akses, dan Kepatuhan Data

---

## Anggota dan Kontribusi

| Nama | NIM | Kontribusi | Commit |
| Salsabila Salwa Rizki | 251402123 | Setup dan peran berlapis (q00–q08), Refleksi A, README.md | Tersedia di riyawat Git |
| Jessqueen Maria Purba | 251402099 | RLS multi-penyewa dan SQL injection bagian 1 (q09–q15, rentan.py), Refleksi B | Tersedia riyawat Git |
| Nadia Stevany Br Situmorang | 251402073 | SQL injection bagian 2, enkripsi, penyamaran (q16–q23), Refleksi C, R1 | Tersedia di riyawat Git |
| Sina Mahdi Sitanggang | 251402008 | Audit, retensi, UU PDP (q24–q30), Refleksi D–E, integrasi laporan dan MR | Tersedia di riyawat Git |

---

## Kondisi Uji
* **PostgreSQL:** 17-alpine (via Docker, dengan konfigurasi jaringan terisolasi)
* **Alat:** Terminal `psql` (di dalam kontainer Docker `lab11-db`)
* **Database:** `msbd`, **Skema:** `lab11`
* **Data Baseline:** 3 Tenant, 30.000 Pelanggan, 4 Akun Aplikasi, dan 120.000 Transaksi

---

### Q00. Setup klaster tertutup dan skema lab11

**Peran yang menjalankan:** `postgres`

**Perintah SQL:**
```sql
SELECT (SELECT count(*) FROM lab11.tenant)     AS tenant,
       (SELECT count(*) FROM lab11.pelanggan)  AS pelanggan,
       (SELECT count(*) FROM lab11.akun)       AS akun,
       (SELECT count(*) FROM lab11.transaksi)  AS transaksi;

SELECT tenant_id, count(*) FROM lab11.pelanggan GROUP BY 1 ORDER BY 1;
```

**Keluaran nyata:**
```text
 tenant | pelanggan | akun | transaksi 
--------+-----------+------+-----------
      3 |     30000 |    4 |    120000
(1 row)

 tenant_id | count 
----------+-------
         1 | 10000
         2 | 10000
         3 | 10000
(3 rows)
```

**Alasan keputusan:**
Verifikasi jumlah baris awal memastikan bahwa data deterministik dan skema terisolasi telah termuat dengan sempurna sebelum eksperimen kontrol akses dijalankan.

---

### Q01. Hak pemilik tidak bisa dicabut 

**Peran yang menjalankan:** `postgres` (pencabutan) & `skema_owner` (pengujian dan pemberian kembali)

**Perintah SQL:**
```sql
REVOKE UPDATE ON lab11.pelanggan FROM skema_owner;
SET ROLE skema_owner;
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;  
GRANT UPDATE ON lab11.pelanggan TO skema_owner;                      
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;  
RESET ROLE;
```

**Keluaran nyata:**
```text
REVOKE
SET
ERROR:  permission denied for table pelanggan
ROLLBACK
GRANT
SET
UPDATE 1
ROLLBACK
RESET
```

**Alasan keputusan:**
Pemilik objek (`skema_owner`) memiliki hak istimewa inheren atas tabel buatannya. Meskipun hak diskresioner dicabut sementara, pemilik dapat memberikan hak tersebut kembali kepada dirinya sendiri.

---

### Q02. DROP bukan hak yang bisa dicabut 

**Peran yang menjalankan:** `postgres`

**Perintah SQL:**
```sql
REVOKE DROP ON lab11.akun FROM skema_owner;
```

**Keluaran nyata:**
```text
ERROR:  unrecognized privilege type "drop"
```

**Alasan keputusan:**
Perintah `DROP` dan `ALTER` bukan merupakan hak diskresioner yang diatur melalui `GRANT/REVOKE`, melainkan melekat secara mutlak pada kepemilikan objek (*ownership*).

---

### Q03. Default privileges 

**Peran yang menjalankan:** `postgres` & `skema_owner`

**Perintah SQL:**
```sql
-- (a) Dibuat oleh postgres
CREATE TABLE lab11.catatan_postgres (id int);
SELECT has_table_privilege('app_laporan','lab11.catatan_postgres','SELECT') AS via_postgres;
DROP TABLE lab11.catatan_postgres;

-- (b) Dibuat oleh skema_owner
SET ROLE skema_owner;
CREATE TABLE lab11.catatan_owner (id int);
RESET ROLE;
SELECT has_table_privilege('app_laporan','lab11.catatan_owner','SELECT') AS via_owner;
DROP TABLE lab11.catatan_owner;
```

**Keluaran nyata:**
```text
CREATE TABLE
 via_postgres 
--------------
 f
(1 row)

DROP TABLE
SET
CREATE TABLE
RESET
 via_owner 
-----------
 t
(1 row)

DROP TABLE
```

**Alasan keputusan:**
Pengaturan `ALTER DEFAULT PRIVILEGES` memastikan setiap tabel baru yang dibuat oleh peran pemilik secara otomatis mewarisi hak akses yang ditentukan tanpa perlu perintah manual berulang kali.

---

### Q04. GRANT OPTION dan CASCADE

**Peran yang menjalankan:** `postgres` & `app_write`

**Perintah SQL:**
```sql
GRANT SELECT ON lab11.transaksi TO app_write WITH GRANT OPTION;
SET ROLE app_write;
GRANT SELECT ON lab11.transaksi TO app_analitik;   
RESET ROLE;

REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write;
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write CASCADE;

SELECT has_table_privilege('app_analitik','lab11.transaksi','SELECT') AS analitik,
       has_table_privilege('app_write','lab11.transaksi','SELECT')    AS app_write;

SET ROLE app_write;
SELECT count(*) AS dibaca_app_write FROM lab11.transaksi;
RESET ROLE;
```

**Keluaran nyata:**
```text
GRANT
SET
GRANT
RESET
ERROR:  dependent privileges exist
REVOKE
 analitik | app_write 
----------+-----------
 f        | t
(1 row)

SET
 dibaca_app_write 
------------------
           120000
(1 row)

RESET
```

**Alasan keputusan:**
Pencabutan hak delegasi (`GRANT OPTION`) yang diturunkan ke pihak lain wajib menggunakan `CASCADE` jika terdapat dependensi aktif di bawahnya, namun hak akses dasar pemilik delegasi tetap aman terjaga.

---

### Q05. Tabel tujuh peran

**Peran yang menjalankan:** `postgres`

**Perintah SQL:**
```sql
SELECT rolname AS nama_peran,
       rolcanlogin AS bisa_login,
       rolbypassrls AS bypass_rls,
       rolsuper AS superuser
FROM pg_roles
WHERE rolname IN ('postgres', 'skema_owner', 'app_read', 'app_write', 'app_laporan', 'app_portal', 'app_analitik')
ORDER BY rolcanlogin, rolname;
```

**Keluaran nyata:**
```text
  nama_peran  | bisa_login | bypass_rls | superuser 
--------------+------------+------------+-----------
 app_read     | f          | f          | f
 app_write    | f          | f          | f
 skema_owner  | f          | f          | f
 app_analitik | t          | f          | f
 app_laporan  | t          | f          | f
 app_portal   | t          | f          | f
 postgres     | t          | t          | t
(7 rows)
```

**Alasan keputusan:**
Aplikasi tidak pernah login langsung sebagai pemilik (`skema_owner`) karena akun pemilik memiliki hak bawaan destruktif yang tidak bisa dicabut, sehingga meminimalisir dampak kerentanan aplikasi.

---

### Q06. Default deny RLS

**Peran yang menjalankan:** `postgres` & `app_laporan`

**Perintah SQL:**
```sql
ALTER TABLE lab11.pelanggan ENABLE ROW LEVEL SECURITY;
BEGIN; SET LOCAL ROLE app_laporan;
  SELECT count(*) AS sebelum_ada_kebijakan FROM lab11.pelanggan;
COMMIT;
```

**Keluaran nyata:**
```text
ALTER TABLE
BEGIN
sebelum_ada_kebijakan 
-----------------------
                     0
(1 row)
COMMIT
```

**Alasan keputusan:**
Begitu RLS diaktifkan pada tabel tanpa adanya kebijakan yang mendefinisikan aturan akses, PostgreSQL secara otomatis menerapkan prinsip keamanan *default-deny* (seluruh baris ditolak untuk non-owner).

---

### Q07. Kebijakan penyewa

**Peran yang menjalankan:** `postgres`

**Perintah SQL:**
```sql
CREATE POLICY p_tenant_baca ON lab11.pelanggan
  FOR SELECT TO app_read, app_write
  USING (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

CREATE POLICY p_tenant_tulis ON lab11.pelanggan
  FOR ALL TO app_write
  USING      (tenant_id = nullif(current_setting('app.tenant', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant', true), '')::int);
```

**Keluaran nyata:**
```text
CREATE POLICY
CREATE POLICY
```

**Alasan keputusan:**
Penggunaan `nullif` mencegah galat konversi tipe data integer apabila variabel sesi `app.tenant` bernilai kosong (`''`), menjaga stabilitas koneksi pada kolam koneksi.

---

### Q08. Uji positif dan negatif

**Peran yang menjalankan:** `app_laporan`

**Perintah SQL:**
```sql
BEGIN; SET LOCAL ROLE app_laporan; SET LOCAL app.tenant = '1';
  SELECT count(*) AS terlihat_tenant1 FROM lab11.pelanggan;              
  SELECT count(*) AS harus_nol FROM lab11.pelanggan WHERE tenant_id = 2; 
COMMIT;
```

**Keluaran nyata:**
```text
BEGIN
terlihat_tenant1 
------------------
            10000
(1 row)

 harus_nol 
-----------
         0
(1 row)

COMMIT
```

**Alasan keputusan:**
Uji positif membuktikan data milik penyewa 1 dapat diakses dengan normal (10.000 baris), sementara uji negatif membuktikan bahwa kueri yang mencoba mencatut data penyewa 2 disaring otomatis oleh RLS menjadi 0 baris.

---

## Q09 - Q30

---

## Refleksi A–E

### Refleksi A
Pada Q1, hak biasa bisa dicabut dari pemilik, tetapi risikonya tetap ada. Pencabutan hak tidak menyelesaikan keluhan K1 secara menyeluruh karena pemilik objek memiliki hak inheren (*ownership privilege*) untuk memberikan kembali hak tersebut kepada dirinya kapan saja. Jalan keluarnya adalah memisahkan peran pengembang/aplikasi dari akun pemilik skema (`skema_owner`) dan menerapkan prinsip hak minimum (*principle of least privilege*).

### Refleksi B
Dengan RLS aktif, penyaring `WHERE tenant_id` di aplikasi tetap diperlukan sebagai lapis pertahanan lapis pertama untuk efisiensi kueri dan pengoptimalan indeks. RLS di sisi database bertindak sebagai lapis pertahanan terakhir (*defense in depth*) yang menjamin keamanan data meskipun lapisan aplikasi mengalami cacat logika atau lupa menyaring parameter.

### Refleksi C
### Refleksi D
### Refleksi E

---

## Peta Tiket #1134 ke UU Nomor 27 Tahun 2022 (UU PDP)

| Keluhan | Pasal Relevan | Kontrol Teknis Pencegah (Lab 11) | Bukti |

| **K1**: Satu akun memegang seluruh kunci dan menjalankan `DROP TABLE` | Pasal 35 & Pasal 39 | Pemisahan peran berlapis: pemilik skema tidak login; aplikasi memakai peran terbatas. | Q1–Q5 |
| **K2**: Penyewa A membaca data penyewa B akibat lupa `WHERE tenant_id` | Pasal 35 & Pasal 39 | Penerapan RLS dengan `FORCE ROW LEVEL SECURITY` dan konteks transaksi `SET LOCAL`. | Q6–Q11 |
| **K3**: Kotak pencarian rentan SQL injection dan membuka seluruh tabel | Pasal 35 | Pemisahan saluran perintah dan data melalui query berparameter (`$1`) serta daftar putih. | Q12–Q16 |
| **K4**: Berkas cadangan berpindah ke laptop analis tanpa perlindungan | Pasal 35 & Pasal 36 | Enkripsi kolom (`pgcrypto`) serta tampilan tersamar (`v_pelanggan_samar`) tanpa akses tabel mentah. | Q19–Q24 |
| **K5**: Permintaan hapus datang, tetapi data masih hidup di salinan dan audit | Pasal 8, Pasal 31, & Pasal 43 | Tabel `permintaan_hapus` bertenggat 72 jam, penghapusan berjenjang, dan audit terukur. | Q25–Q29 |

---

## Pernyataan Etika
Seluruh percobaan serangan hanya dijalankan pada kontainer lab11 milik sendiri di jaringan tertutup.

Tanda tangan anggota:
1. Salsabila Salwa Rizki        : `(       )`
2. Jessqueen Maria Purba        : `(       )`
3. Nadia Stevany Br Situmorang  : `(       )`
4. Sina Mahdi Sitanggang        : `(       )`

---

## Penggunaan AI dan Verifikasi

Kelompok kami memanfaatkan bantuan AI untuk membantu menyusun kerangka dokumentasi laporan, memvalidasi sintaks kebijakan *Row-Level Security* (RLS) serta fungsi `SECURITY DEFINER`, dan memperjelas konsep kepatuhan data. Seluruh skrip SQL, pengujian hak akses per peran, serta skenario isolasi *tenant* dieksekusi langsung di dalam lingkungan kontainer Docker PostgreSQL oleh masing-masing anggota sesuai pembagian tugas, dan seluruh hasil yang dilaporkan merupakan keluaran aktual dari pengujian tersebut.

--- 

## Tautan Merge Request
[Masukkan URL merge request GitHub/GitLab di sini]

---