# Laporan Latihan Kelompok Pertemuan 4

## Identitas Kelompok

| Nama | NIM | Kontribusi |
|------|-----|------------|
| Salsabila Salwa Rizki | 251402123 | Q1-Q4, Refleksi A, setup q00 |
| Nadia Stevany Br Situmorang | 251402073 | Q5-Q8, Refleksi B |
| Sina Mahdi Sitanggang | 251402008 | Q9-Q13, Refleksi C |
| Jesqueen Maria Purba | 251402099 | Q14-Q21, Refleksi D-E |

---

## Q1-Q21

### Q1: View Film Murah

**Perintah:**
```powershell
Get-Content latihan/p04/q01_view_film_murah.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
CREATE VIEW
 count 
-------
   341
(1 row)
```

**Alasan:** View dibuat tanpa `WITH CHECK OPTION` untuk observasi awal perilaku view. Hasilnya ada 341 film dengan `rental_rate <= 0.99`.

---

### Q2: Baris Menghilang

**Perintah:**
```powershell
Get-Content latihan/p04/q02_baris_menghilang.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
INSERT 0 1
 di_view 
---------
       0
(1 row)

 di_tabel 
----------
        1
(1 row)
```

**Penjelasan:** INSERT lewat view berhasil karena tidak ada `CHECK OPTION`. Namun, baris tersebut "menghilang" dari view karena `rental_rate = 4.99` tidak memenuhi syarat `WHERE rental_rate <= 0.99`. Di tabel dasar, baris tetap ada (1 baris). Ini menunjukkan bahaya view tanpa `CHECK OPTION` untuk operasi write.

---

### Q3: WITH CASCADED CHECK OPTION

**Perintah:**
```powershell
Get-Content latihan/p04/q03_check_option.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Pesan Galat Utuh:**
```
CREATE VIEW
ERROR:  new row violates check option for view "film_murah"
DETAIL:  Failing row contains (9998, Film Uji Check, null, null, null, null, null, 4.99, null, null, PG, null, null, null).
```

**Penjelasan:** Setelah view dibuat ulang dengan `WITH CASCADED CHECK OPTION`, INSERT dengan `rental_rate = 4.99` ditolak karena tidak memenuhi syarat view. Ini membuktikan bahwa `CHECK OPTION` memaksa aturan view diterapkan saat INSERT/UPDATE.

---

### Q4: View dengan GROUP BY

**Perintah:**
```powershell
Get-Content latihan/p04/q04_view_pendapatan_kategori.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Pesan Galat Utuh:**
```
CREATE VIEW
ERROR:  cannot insert into view "pendapatan_kategori"
DETAIL:  Views containing GROUP BY are not automatically updatable.
HINT:  To enable inserting into the view, provide an INSTEAD OF INSERT trigger or an unconditional ON INSERT DO INSTEAD rule.
```

**Penjelasan:** View dengan `GROUP BY` tidak auto-updatable karena PostgreSQL tidak tahu bagaimana menerjemahkan INSERT ke dalam agregasi. Solusinya adalah membuat `INSTEAD OF INSERT trigger` atau `ON INSERT DO INSTEAD rule`.

---

### Q5-Q8: Materialized View

#### Q5: Query Dasar Akses

**Perintah:**
```powershell
Get-Content latihan/p04/q05_query_dasar_akses.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran (52 baris):**
```
Timing is on.
         bulan          |  kanal  | jumlah_akses | film_unik 
------------------------+---------+--------------+-----------
 2025-09-01 00:00:00+00 | android |         7277 |      1000
 ... (52 baris total)
(52 rows)

Time: 12687.300 ms (00:12.687)
Timing is off.
```

**Waktu:** 12687.300 ms (00:12.687)

---

#### Q6: Buat Materialized View

**Perintah:**
```powershell
Get-Content latihan/p04/q06_buat_matview.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
CREATE MATERIALIZED VIEW
Timing is on.
ERROR:  materialized view "ringkasan_akses" has not been populated
HINT:  Use the REFRESH MATERIALIZED VIEW command.
REFRESH MATERIALIZED VIEW
Time: 8097.312 ms (00:08.097)
Timing is off.
 count 
-------
    52
(1 row)
```

**Penjelasan:**
- Error saat baca sebelum refresh: **EXPECTED** karena dibuat dengan `WITH NO DATA`
- Refresh biasa: **8097.312 ms** (lebih cepat dari query langsung 12687 ms)
- Setelah refresh: 52 baris tersedia

---

#### Q7: Refresh Concurrently

**Perintah:**
```powershell
Get-Content latihan/p04/q07_refresh_concurrently.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
ERROR:  cannot refresh materialized view "lab4.ringkasan_akses" concurrently
HINT:  Create a unique index with no WHERE clause on one or more columns of the materialized view.
CREATE INDEX
Timing is on.
REFRESH MATERIALIZED VIEW
Time: 7379.333 ms (00:07.379)
Timing is off.
```

**Penjelasan:**
- Error pertama: **EXPECTED** karena belum ada unique index
- Setelah buat unique index `ux_ringkasan_akses_bulan_kanal`, refresh concurrent berhasil
- Waktu refresh concurrent: **7379.333 ms** (sedikit lebih lambat dari refresh biasa 8097 ms, tapi tidak memblokir pembaca)

---

#### Q8: Buktikan Pembaca Tidak Diblokir

**Terminal 1 (Refresh Concurrent):**
```sql
INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1, now(), 'web'
FROM generate_series(1, 200000);

REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;
```
**Hasil:** `INSERT 0 200000`, `REFRESH MATERIALIZED VIEW` (berhasil tanpa blokir)

**Terminal 2 (Pembaca saat refresh concurrent):**
```sql
SELECT count(*) FROM lab4.ringkasan_akses;
```
**Hasil:** `count = 52` (langsung kembali, **TIDAK DIBLOKIR**)

**Terminal 1 (Refresh Biasa):**
```sql
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;
```
**Hasil:** `REFRESH MATERIALIZED VIEW`

**Terminal 2 (Pembaca saat refresh biasa):**
```sql
SELECT count(*) FROM lab4.ringkasan_akses;
```
**Hasil:** `count = 52` (harus menunggu sampai refresh selesai, **DIBLOKIR**)

**Kesimpulan:** Refresh concurrent tidak memblokir pembaca, sedangkan refresh biasa memblokir pembaca sampai selesai.

---

### Q9-Q13: Trigger Audit

#### Q9: Trigger Audit Baris

**Perintah:**
```powershell
Get-Content latihan/p04/q09_trigger_audit_baris.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
CREATE TABLE
CREATE FUNCTION
CREATE TRIGGER
```

**Penjelasan:** Tabel `audit_harga`, fungsi `catat_audit_harga()`, dan trigger `film_audit_harga` berhasil dibuat. Trigger menggunakan `AFTER UPDATE OF rental_rate` dengan `WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)` untuk mencegah audit palsu.

---

#### Q10: Uji Audit Baris

**Perintah:**
```powershell
Get-Content latihan/p04/q10_uji_audit_baris.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
UPDATE 1
UPDATE 1
UPDATE 1
 audit_id | film_id | harga_lama | harga_baru | diubah_oleh |          diubah_pada          
----------+---------+------------+------------+-------------+-------------------------------
        1 |       1 |       0.99 |       5.99 | msbd        | 2026-09-15 04:13:49.211334+00
(1 row)
```

**Penjelasan:** Dari 3 UPDATE (ubah harga, tulis ulang harga sama, ubah title), hanya 1 audit yang tercatat. Ini membuktikan trigger bekerja dengan benar:
- UPDATE harga (0.99 → 5.99): tercatat
- UPDATE harga sama (5.99 → 5.99): tidak tercatat (karena `IS DISTINCT FROM`)
- UPDATE title saja: tidak tercatat (karena `UPDATE OF rental_rate`)

---

#### Q11: NULL pada Trigger

**Perintah:**
```powershell
Get-Content latihan/p04/q11_null_pada_trigger.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
DROP TRIGGER
CREATE TRIGGER
UPDATE 1
UPDATE 1
 audit_id | film_id | harga_lama | harga_baru | diubah_oleh | diubah_pada 
----------+---------+------------+------------+-------------+-------------
(0 rows)
```

**Penjelasan:** Setelah ganti `IS DISTINCT FROM` menjadi `<>`, perubahan dari nilai ke NULL dan dari NULL ke nilai **tidak tercatat**. Ini karena `NULL <> nilai` menghasilkan `UNKNOWN`, bukan `TRUE`. Maka kondisi `WHEN` tidak terpenuhi. Ini menunjukkan kelemahan `<>` dibandingkan `IS DISTINCT FROM` untuk handling NULL.

---

#### Q12: Biaya Trigger Baris

**Perintah:**
```powershell
Get-Content latihan/p04/q12_biaya_trigger_baris.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
Timing is on.
UPDATE 1001
Time: 1603.613 ms (00:01.604)
ALTER TABLE
Time: 9.038 ms
UPDATE 1001
Time: 419.604 ms
ALTER TABLE
Time: 24.461 ms
Timing is off.
```

**Penjelasan:**
- UPDATE dengan trigger aktif: **1603.613 ms**
- UPDATE dengan trigger nonaktif: **419.604 ms**
- Overhead trigger per baris: **~1184 ms** (4x lebih lambat)

---

#### Q13: Trigger Pernyataan

**Perintah:**
```powershell
Get-Content latihan/p04/q13_trigger_pernyataan.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
DROP TRIGGER
DROP FUNCTION
DROP TABLE
CREATE TABLE
CREATE FUNCTION
CREATE TRIGGER
Timing is on.
UPDATE 1001
Time: 545.257 ms
Timing is off.
 jumlah_audit 
--------------
         1001
(1 row)
```

**Penjelasan:**
- UPDATE dengan trigger pernyataan: **545.257 ms**
- Lebih cepat dari trigger per baris (1603 ms) karena hanya 1 INSERT massal
- Jumlah audit: 1001 baris (sama dengan trigger per baris)

**Perbandingan:**
| Jenis Trigger | Waktu | Jumlah Audit |
|---------------|-------|--------------|
| Per Baris (aktif) | 1603.613 ms | 1001 |
| Per Baris (nonaktif) | 419.604 ms | 0 |
| Pernyataan | 545.257 ms | 1001 |

---

### Q14-Q17: Constraint

#### Q14: CHECK NOT VALID

**Perintah:**
```powershell
Get-Content latihan/p04/q14_check_not_valid.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
INSERT 0 1
ALTER TABLE
ERROR:  check constraint "chk_rental_rate_positif" of relation "film" is violated by some row
UPDATE 1
ALTER TABLE
 film_id |    title     | rental_rate 
---------+--------------+-------------
    9997 | Film Negatif |        0.00
(1 row)
```

**Penjelasan:**
1. Insert data negatif (-1.00): berhasil
2. Tambah constraint `NOT VALID`: berhasil (skip validasi data existing)
3. VALIDATE constraint: **GAGAL** (EXPECTED, karena ada data negatif)
4. Perbaiki data (UPDATE ke 0.00): berhasil
5. VALIDATE ulang: berhasil

Ini menunjukkan pola `NOT VALID` yang benar: constraint ditambahkan tanpa blokir tabel, validasi dilakukan terpisah setelah data diperbaiki.

---

#### Q15: Unique Soft Delete

**Perintah:**
```powershell
Get-Content latihan/p04/q15_unique_soft_delete.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
ALTER TABLE
ALTER TABLE
UPDATE 1
INSERT 0 1
ALTER TABLE
CREATE INDEX
ERROR:  duplicate key value violates unique constraint "ux_film_judul_aktif"
DETAIL:  Key (title)=(ACADEMY DINOSAUR) already exists.
 film_id |      title       | deleted_at 
---------+------------------+------------
    9996 | ACADEMY DINOSAUR | 
(1 row)
```

**Penjelasan:**
- UNIQUE constraint biasa menolak duplikat judul meskipun yang lama sudah soft-deleted
- Setelah ganti ke unique index parsial `WHERE deleted_at IS NULL`, INSERT judul sama berhasil
- Error terakhir menunjukkan masih ada film aktif dengan judul "ACADEMY DINOSAUR" (film_id 1 belum di-soft-delete di percobaan ini)

---

#### Q16: FK Aksi Referensial

**Perintah:**
```powershell
Get-Content latihan/p04/q16_fk_aksi_referensial.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p04/q16a_fk_no_action.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p04/q16b_fk_cascade.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p04/q16c_fk_set_null.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran Q16 (Setup):**
```
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 1
INSERT 0 1
INSERT 0 1
ERROR:  update or delete on table "film" violates foreign key constraint "ulasan_no_action_film_id_fkey" on table "ulasan_no_action"
DETAIL:  Key (film_id)=(1) is still referenced from table "ulasan_no_action".
```

**Keluaran Q16a (NO ACTION):**
```
ERROR:  update or delete on table "film" violates foreign key constraint "ulasan_no_action_film_id_fkey" on table "ulasan_no_action"
DETAIL:  Key (film_id)=(1) is still referenced from table "ulasan_no_action".
```

**Keluaran Q16b (CASCADE):**
```
DELETE 1
INSERT 0 1
ERROR:  update or delete on table "film" violates foreign key constraint "ulasan_no_action_film_id_fkey" on table "ulasan_no_action"
DETAIL:  Key (film_id)=(1) is still referenced from table "ulasan_no_action".
 sisa_ulasan 
-------------
           1
(1 row)
```

**Keluaran Q16c (SET NULL):**
```
DELETE 1
INSERT 0 1
ERROR:  update or delete on table "film" violates foreign key constraint "ulasan_no_action_film_id_fkey" on table "ulasan_no_action"
DETAIL:  Key (film_id)=(1) is still referenced from table "ulasan_no_action".
 film_id | komentar 
---------+----------
       1 | Bagus
(1 row)
```

**Catatan Penting:** CASCADE dan SET NULL tidak teruji dengan benar karena ada referensi dari `ulasan_no_action` yang memblokir DELETE film_id=1. Seharusnya setiap aksi diuji dengan tabel terpisah yang tidak saling mereferensi.

**Tabel Perbandingan (Teoritis):**

| Aksi Referensial | Perilaku saat Induk Dihapus | Hasil yang Diharapkan |
|------------------|------------------------------|------------------------|
| **NO ACTION** | Menolak penghapusan induk jika ada anak | Gagal (Error: violates foreign key) |
| **CASCADE** | Menghapus induk, anak ikut terhapus otomatis | Berhasil, ulasan ikut terhapus (count = 0) |
| **SET NULL** | Menghapus induk, kolom FK pada anak jadi NULL | Berhasil, film_id pada ulasan jadi NULL |

---

#### Q17: EXCLUDE Constraint

**Perintah:**
```powershell
Get-Content latihan/p04/q17_exclude_harga.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
CREATE EXTENSION
CREATE TABLE
INSERT 0 1
ERROR:  conflicting key value violates exclusion constraint "harga_film_film_id_wilayah_berlaku_excl"
DETAIL:  Key (film_id, wilayah, berlaku)=(1, ID, [2026-03-01,2026-09-30)) conflicts with existing key (film_id, wilayah, berlaku)=(1, ID, [2026-01-01,2026-06-30)).
INSERT 0 1
```

**Penjelasan:**
- INSERT pertama (range `[2026-01-01, 2026-06-30)`): berhasil
- INSERT kedua (range `[2026-03-01, 2026-09-30)`): **GAGAL** (EXPECTED, tumpang tindih dengan yang pertama)
- INSERT ketiga (range `[2026-07-01, 2026-12-31)`): berhasil (tidak tumpang tindih)

Constraint `EXCLUDE` berhasil mencegah periode harga yang tumpang tindih untuk film dan wilayah yang sama.

---

### Q18-Q21: Expand-Contract

#### Q18: Expand - Tulis Ganda

**Perintah:**
```powershell
Get-Content latihan/p04/q18_expand_tulis_ganda.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
CREATE FUNCTION
CREATE TRIGGER
```

**Penjelasan:** Fungsi `sync_harga_ke_film()` dan trigger `sync_harga_ke_film` berhasil dibuat. Trigger akan sinkronisasi perubahan harga dari `lab4.harga_film` ke `lab4.film.rental_rate` untuk wilayah 'ID'.

---

#### Q19: Backfill Bertahap

**Perintah:**
```powershell
Get-Content latihan/p04/q19_backfill_bertahap.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
INSERT 0 999
INSERT 0 0
 count 
-------
     3
(1 row)
```

**Catatan Penting:** Backfill hanya mengisi 999 film (seharusnya 1000 untuk rentang 1-1000), dan verifikasi menunjukkan masih ada **3 film tanpa harga**. Ini berarti backfill tidak lengkap. Kemungkinan penyebab:
- Ada film dengan film_id di luar rentang 1-1000 yang belum di-backfill
- Atau ada film yang sudah di-soft-delete (deleted_at tidak NULL)

**Rekomendasi:** Sebelum lanjut ke fase contract, pastikan backfill menghasilkan 0 (tidak ada film tanpa harga).

---

#### Q20: Contract - View Fasad

**Perintah:**
```powershell
Get-Content latihan/p04/q20_contract_view_fasad.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**
```
CREATE VIEW
NOTICE:  trigger "sync_harga_ke_film" for relation "lab4.harga_film" does not exist, skipping
DROP TRIGGER
DROP FUNCTION
DROP TRIGGER
DROP FUNCTION
DROP VIEW
DROP VIEW
ALTER TABLE
                                Table "lab4.film"
        Column        |           Type           | Collation | Nullable | Default 
----------------------+--------------------------+-----------+----------+---------
 film_id              | integer                  |           | not null | 
 title                | text                     |           |          | 
 ... (struktur tabel tanpa rental_rate)
 deleted_at           | timestamp with time zone |           |          | 

 film_id |      title       | rental_rate | rating 
---------+------------------+-------------+--------
    9997 | Film Negatif     |             | 
       3 | ADAPTATION HOLES |        3.02 | NC-17
       1 | Film Baru        |        5.00 | PG
       1 | Film Baru        |        7.00 | PG
       6 | AGENT TRUMAN     |        3.02 | PG
(5 rows)
```

**Penjelasan:**
- View fasad `lab4.film_lama` berhasil dibuat
- Trigger `sync_harga_ke_film` dan `film_audit_harga` berhasil di-drop
- View `film_murah` dan `pendapatan_kategori` berhasil di-drop
- Kolom `rental_rate` berhasil di-drop dari tabel `lab4.film`
- View fasad masih bisa diakses dan menampilkan `rental_rate` dari `lab4.harga_film`

**Catatan:** Ada duplikasi film_id=1 dengan judul "Film Baru" dan harga berbeda (5.00 dan 7.00). Ini kemungkinan karena INSERT berulang saat percobaan.

---

#### Q21: Migrasi Berversi

**Perintah:**
```powershell
Get-Content migrations/0041_expand_buat_harga_film.up.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content migrations/0042_expand_trigger_tulis_ganda.up.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content migrations/0043_migrate_backfill.up.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content migrations/0044_migrate_verifikasi.up.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content migrations/0045_contract_view_fasad.up.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content migrations/0046_contract_drop_kolom_lama.up.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

**Keluaran:**

**0041:**
```
NOTICE:  extension "btree_gist" already exists, skipping
CREATE EXTENSION
ERROR:  relation "harga_film" already exists
CREATE INDEX
CREATE INDEX
```
**Catatan:** Tabel `harga_film` sudah ada dari percobaan Q17, jadi CREATE TABLE gagal.

**0042:**
```
CREATE FUNCTION
CREATE TRIGGER
```
Berhasil

**0043:**
```
ERROR:  column f.rental_rate does not exist
LINE 2: SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01...
```
**GAGAL** karena kolom `rental_rate` sudah dihapus di Q20. Migration 0043 harus dijalankan SEBELUM 0046.

**0044:**
```
ERROR:  Masih ada 3 film tanpa harga di wilayah ID
CONTEXT:  PL/pgSQL function inline_code_block line 13 at RAISE
```
**GAGAL** karena backfill Q19 tidak lengkap (masih 3 film tanpa harga).

**0045:**
```
CREATE VIEW
DROP TRIGGER
DROP FUNCTION
```
Berhasil (file tidak ada di percobaan pertama, tapi berhasil di percobaan kedua)

**0046:**
```
ERROR:  column "rental_rate" of relation "film" does not exist
```
 **GAGAL** karena kolom `rental_rate` sudah dihapus di Q20.

**Kesimpulan Migrasi:**
Migration tidak bisa dijalankan berurutan karena:
1. Tabel `harga_film` sudah dibuat manual di Q17
2. Kolom `rental_rate` sudah dihapus di Q20 sebelum migration 0043 dan 0046 dijalankan
3. Backfill tidak lengkap (masih 3 film tanpa harga)

Ini menunjukkan pentingnya menjalankan migration **sebelum** melakukan perubahan manual di database.

---

## Refleksi A-E

### Refleksi A: View sebagai Fasad

**A1: Dua Keuntungan View sebagai Fasad**

1. **Keamanan**: Aplikasi hanya melihat kolom yang diperlukan, kolom sensitif bisa disembunyikan.
2. **Kestabilan API**: Struktur tabel dasar bisa berubah tanpa mengganggu aplikasi, asalkan view tetap sama.

**A2: Dua Kerugian View sebagai Fasad**

1. **Performa**: View kompleks (terutama dengan JOIN dan agregasi) bisa lambat kalau tidak dioptimasi.
2. **Kompleksitas debugging**: Error di view lebih sulit dilacak karena ada lapisan abstraksi tambahan.

**A3: Keadaan yang Mempersulit Tim**

Berdasarkan Q2, ketika view punya WHERE clause tapi tanpa CHECK OPTION, INSERT lewat view bisa sukses tapi datanya "menghilang" dari view. Ini bikin tim bingung karena data seolah-olah hilang padahal sebenarnya ada di tabel dasar. Maka dari itu, view yang dipakai untuk write operation harus pakai WITH CHECK OPTION.

---
### Refleksi C: Trigger Audit

**C1: Kapan Trigger Per Baris Lebih Tepat?**

Trigger per baris tetap lebih tepat ketika kita butuh akses ke nilai OLD dan NEW per baris untuk logika kondisional yang kompleks. Misalnya, kalau audit cuma perlu dicatat untuk film dengan rating tertentu, trigger per baris bisa pakai `WHEN (OLD.rating = 'PG')`.

**C2: Kemampuan yang Tidak Dimiliki Trigger Pernyataan**

Trigger pernyataan tidak bisa mengakses nilai OLD/NEW per baris secara individual. Dia cuma bisa lihat transition table (OLD TABLE/NEW TABLE) sebagai satu kesatuan.

**C3: Mengapa Kirim Email dari Trigger Itu Buruk?**

Kalau transaksi di-rollback setelah trigger kirim email, email udah terlanjur terkirim tapi datanya gak jadi berubah. Ini bikin inkonsistensi antara notifikasi dan state database. Makanya kirim email harusnya dilakukan di luar transaksi, misalnya via queue atau job scheduler.

---
### Refleksi D: Constraint dan Konkurensi

**D1: Mengapa Trigger Bisa Gagal Saat Konkuren?**

Trigger yang baca tabel sebelum INSERT bisa kena race condition. Kalau dua transaksi jalan bareng, keduanya bisa baca state yang sama dan sama-sama lolos validasi, padahal seharusnya salah satu ditolak. Ini karena trigger tidak lock baris yang dibaca.

**D2: Mengapa EXCLUDE Aman?**

Constraint EXCLUDE pakai index GIST yang otomatis lock range yang dicek. Jadi kalau dua transaksi coba insert periode tumpang tindih bareng, yang satu akan nunggu yang lain selesai, lalu ditolak karena range udah kepake. Ini dijamin sama PostgreSQL di level storage engine.

---

### Refleksi E: Expand-Contract

**E1: Jarak Rilis antara 0045 dan 0046**

Saya usulkan minimal **2 minggu** atau **1 siklus rilis penuh**. Ini ngasih waktu buat:
- Monitor apakah view fasad berjalan stabil
- Pastikan semua aplikasi udah migrate ke struktur baru
- Kumpulkan bukti bahwa tidak ada error dari aplikasi lama

**E2: Bukti yang Harus Dikumpulkan Sebelum 0046**

1. **Log monitoring**: Tidak ada error dari aplikasi yang akses `rental_rate` dalam 2 minggu terakhir.
2. **Coverage test**: Semua query yang pakai `rental_rate` udah dites pakai view fasad.
3. **Rollback plan**: Dokumen cara restore kolom `rental_rate` kalau ternyata masih ada aplikasi yang butuh.
4. **Approval dari stakeholder**: Tim aplikasi dan tim database udah sign-off.

---

## Ringkasan Waktu

| Tugas | Waktu (ms) | Penafsiran |
|-------|------------|------------|
| Q5 (Query langsung) | 12687.300 | Baseline performa query agregasi tanpa materialized view |
| Q6 (Refresh pertama) | 8097.312 | Materialized view lebih cepat ~36% dari query langsung |
| Q7 (Refresh concurrent) | 7379.333 | Sedikit lebih cepat dari refresh biasa, plus tidak memblokir pembaca |
| Q12 (Trigger per baris aktif) | 1603.613 | Overhead trigger signifikan |
| Q12 (Trigger per baris nonaktif) | 419.604 | Bas tanpa trigger |
| Q13 (Trigger pernyataan) | 545.257 | Lebih cepat dari trigger per baris (~3x), tapi tetap ada overhead |

**Analisis:**
- Materialized view memberikan peningkatan performa ~36% untuk query agregasi
- Refresh concurrent sedikit lebih cepat dari refresh biasa dan tidak memblokir pembaca
- Trigger per baris memiliki overhead ~4x dibandingkan tanpa trigger
- Trigger pernyataan lebih efisien (~3x) dari trigger per baris untuk operasi massal

---

## Migrasi dan Commit

### Struktur Folder Migrations

```
migrations/
├── 0041_expand_buat_harga_film.up.sql
├── 0041_expand_buat_harga_film.down.sql
├── 0042_expand_trigger_tulis_ganda.up.sql
├── 0042_expand_trigger_tulis_ganda.down.sql
├── 0043_migrate_backfill.up.sql
├── 0043_migrate_backfill.down.sql
├── 0044_migrate_verifikasi.up.sql
── 0044_migrate_verifikasi.down.sql
├── 0045_contract_view_fasad.up.sql
├── 0045_contract_view_fasad.down.sql
├── 0046_contract_drop_kolom_lama.up.sql
└── 0046_contract_drop_kolom_lama.down.sql
```

### Hasil Eksekusi Migration

| Migration | Status | Keterangan |
|-----------|--------|------------|
| 0041 | Partial | Tabel sudah ada dari Q17, index berhasil dibuat |
| 0042 | Success | Fungsi dan trigger berhasil dibuat |
| 0043 | Failed | Kolom `rental_rate` sudah dihapus di Q20 |
| 0044 | Failed | Masih ada 3 film tanpa harga (backfill tidak lengkap) |
| 0045 | Success | View fasad dibuat, trigger di-drop |
| 0046 | Failed | Kolom `rental_rate` sudah dihapus di Q20 |

### Pelajaran dari Migration

1. **Urutan penting**: Migration harus dijalankan berurutan dan SEBELUM perubahan manual
2. **Backfill harus lengkap**: Verifikasi (0044) harus menghasilkan 0 sebelum lanjut ke contract
3. **Idempotency**: Migration seharusnya bisa dijalankan ulang tanpa error (gunakan `IF NOT EXISTS`, `IF EXISTS`)
4. **Testing di environment terpisah**: Migration harus dites di environment yang bersih sebelum production

---

## Tautan Merge Request

(https://github.com/salsabilasalwarizki/msbd-2026/pull/2)

---
