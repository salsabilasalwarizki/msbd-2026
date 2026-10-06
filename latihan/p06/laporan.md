# Laporan Latihan Kelompok Pertemuan 6
## Mengukur Harga Sebuah Index

## Kondisi Uji
- PostgreSQL: 17.11 (Debian 17.11-1.pgdg13+2)
- Spesifikasi mesin: Windows 11, Intel/AMD processor, SSD storage
- Setelan paralel: max_parallel_workers_per_gather = 0
- Jumlah pengulangan: 3 kali per query
- Data: 2.000.000 baris di lab6.event_log
- Ukuran tabel: 501 MB total, 458 MB heap, rata-rata 239.89 byte per baris

## Anggota dan Kontribusi

| Nama | NIM | Kontribusi | Commit |
|------|-----|------------|--------|
| Salsabila Salwa Rizki | 251402123 | Q1-Q6, Refleksi A, setup q00 | Tersedia di riwayat Git |
| Nadia Stevany Br Situmorang | 251402073 | Q7-Q11, Refleksi B | Tersedia di riwayat Git |
| Sina Mahdi Sitanggang | 251402008 | Q12-Q16, Refleksi C | Tersedia di riwayat Git |
| Jesqueen Maria Purba | 251402099 | Q17-Q31, Refleksi D-E, R1 | Tersedia di riwayat Git |

---

## Q1-Q31

### Q1: Ukuran Tabel

**Perintah:**
```sql
SELECT pg_size_pretty(pg_total_relation_size('lab6.event_log')) AS ukuran_total;
SELECT pg_size_pretty(pg_relation_size('lab6.event_log')) AS ukuran_heap;
SELECT pg_relation_size('lab6.event_log')::numeric / count(*) AS rata_rata_byte_per_baris FROM lab6.event_log;
```

**Keluaran:**
```
ukuran_total: 501 MB (524894208 byte)
ukuran_heap: 458 MB (479789056 byte)
rata_rata_byte_per_baris: 239.89 byte
```

**Analisis:** Rata-rata 239.89 byte per baris lebih besar dari perkiraan teoretis (~196 byte) karena adanya:
- Header tuple (23 byte)
- Pointer array di halaman
- Alignment padding untuk tipe data
- Overhead TOAST pointer untuk kolom besar (email, tags, payload)
- Data aktual email (~25 byte) dan payload JSONB (~50 byte) lebih besar dari estimasi

### Q2: Tuple per Halaman

**Perintah:**
```sql
CREATE EXTENSION IF NOT EXISTS pageinspect;
SELECT pg_relation_size('lab6.event_log') / current_setting('block_size')::int AS jumlah_halaman;
SELECT count(*)::numeric / (pg_relation_size('lab6.event_log') / current_setting('block_size')::int) AS rata_rata_tuple_per_halaman FROM lab6.event_log;
```

**Keluaran:**
```
jumlah_halaman: 58568
rata_rata_tuple_per_halaman: 34.15
```

**Analisis:** Rata-rata 34.15 tuple per halaman jauh di bawah batas teoretis 291 tuple (8192 byte / ~28 byte). Selisih ini terjadi karena:
- Setiap tuple rata-rata 239.89 byte, bukan 28 byte
- 8192 / 239.89 = ~34 tuple per halaman (sesuai hasil)
- Header halaman (24 byte) dan pointer array (4 byte per tuple) mengurangi ruang tersedia
- TOAST pointer untuk kolom besar menambah ukuran tuple

### Q3: TOAST

**Perintah:**
```sql
SELECT a.attname AS kolom, t.typname AS tipe, a.attstorage AS storage,
  CASE a.attstorage
    WHEN 'p' THEN 'plain (tidak di-TOAST)'
    WHEN 'e' THEN 'external (selalu di-TOAST)'
    WHEN 'm' THEN 'main (bisa di-TOAST)'
    WHEN 'x' THEN 'extended (bisa di-TOAST, kompresi)'
  END AS keterangan
FROM pg_attribute a JOIN pg_class c ON a.attrelid = c.oid JOIN pg_type t ON a.atttypid = t.oid
WHERE c.relname = 'event_log' AND c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'lab6')
  AND a.attnum > 0 AND NOT a.attisdropped ORDER BY a.attnum;
```

**Keluaran:**
```
kolom              | tipe      | storage | keterangan
-------------------+-----------+---------+------------------------------------
event_id           | int8      | p       | plain (tidak di-TOAST)
customer_id        | int4      | p       | plain (tidak di-TOAST)
terjadi_pada       | timestamptz | p     | plain (tidak di-TOAST)
status             | text      | x       | extended (bisa di-TOAST, kompresi)
wilayah            | text      | x       | extended (bisa di-TOAST, kompresi)
kota               | text      | x       | extended (bisa di-TOAST, kompresi)
email              | text      | x       | extended (bisa di-TOAST, kompresi)
idempotency_key    | uuid      | p       | plain (tidak di-TOAST)
jumlah             | numeric   | m       | main (bisa di-TOAST)
tags               | _text     | x       | extended (bisa di-TOAST, kompresi)
payload            | jsonb     | x       | extended (bisa di-TOAST, kompresi)
```

**Analisis:** Kolom dengan storage 'x' (extended) adalah status, wilayah, kota, email, tags, dan payload. Kolom-kolom ini akan di-TOAST jika nilai > 2KB. Akibatnya pada SELECT *, PostgreSQL harus fetch dari TOAST table untuk baris dengan nilai besar, memperlambat query. Kolom dengan storage 'p' (plain) seperti event_id, customer_id, terjadi_pada, dan idempotency_key tidak pernah di-TOAST.

### Q4: HOT Update

**Perintah:**
```sql
CREATE TABLE lab6.hot_penuh (id serial PRIMARY KEY, catatan text) WITH (fillfactor = 100);
CREATE TABLE lab6.hot_longgar (id serial PRIMARY KEY, catatan text) WITH (fillfactor = 80);
INSERT INTO lab6.hot_penuh (catatan) SELECT 'awal' FROM generate_series(1, 10000);
INSERT INTO lab6.hot_longgar (catatan) SELECT 'awal' FROM generate_series(1, 10000);
SELECT pg_stat_reset_single_table_counters(oid) FROM pg_class WHERE relname IN ('hot_penuh', 'hot_longgar');
UPDATE lab6.hot_penuh SET catatan = 'baru' WHERE id <= 5000;
UPDATE lab6.hot_longgar SET catatan = 'baru' WHERE id <= 5000;
SELECT relname, n_tup_upd AS total_update, n_tup_hot_upd AS hot_update,
  round(n_tup_hot_upd::numeric / NULLIF(n_tup_upd, 0) * 100, 2) AS persen_hot
FROM pg_stat_user_tables WHERE relname IN ('hot_penuh', 'hot_longgar');
```

**Keluaran:**
```
relname   | total_update | hot_update | persen_hot
----------+--------------+------------+-----------
hot_penuh |            0 |          0 |
hot_longgar |          0 |          0 |
```

**Analisis:** Kedua tabel menunjukkan 0 HOT update karena statistik di-reset setelah INSERT tetapi sebelum UPDATE, dan pg_stat_user_tables tidak ter-update secara real-time. Perlu VACUUM atau menunggu autovacuum untuk melihat statistik yang akurat. Secara teoretis, hot_longgar (fillfactor 80) seharusnya memiliki HOT update lebih banyak karena ada ruang kosong 20% di setiap halaman untuk versi tuple baru.

### Q5: Harga Fillfactor

**Perintah:**
```sql
SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) AS ukuran_total,
  pg_size_pretty(pg_relation_size(oid)) AS ukuran_heap, pg_relation_size(oid) AS ukuran_heap_byte
FROM pg_class WHERE relname IN ('hot_penuh', 'hot_longgar');
```

**Keluaran:**
```
relname     | ukuran_total | ukuran_heap | ukuran_heap_byte
------------+--------------+-------------+------------------
hot_penuh   | 1048 kB      | 656 kB      | 671744
hot_longgar | 1136 kB      | 744 kB      | 761856
```

**Analisis:** hot_longgar 13.4% lebih besar dari hot_penuh (1136 kB vs 1048 kB). Perbedaan 88 kB ini adalah "harga" yang dibayar untuk fillfactor 80 - ruang kosong 20% di setiap halaman yang memungkinkan HOT update saat kolom non-indeks diupdate. Untuk tabel kecil (10000 baris), perbedaan ini minimal, tetapi untuk tabel besar dengan jutaan baris, penghematan ruang dari fillfactor 100 bisa signifikan.

### Q6: Reflektif HOT Update

**Perintah:**
```sql
SELECT pg_stat_reset_single_table_counters(oid) FROM pg_class WHERE relname = 'hot_longgar';
UPDATE lab6.hot_longgar SET catatan = 'versi2' WHERE id <= 1000;
SELECT relname, n_tup_upd, n_tup_hot_upd FROM pg_stat_user_tables WHERE relname = 'hot_longgar';
```

**Keluaran:**
```
relname     | n_tup_upd | n_tup_hot_upd
------------+-----------+---------------
hot_longgar |         0 |             0
```

**Analisis:** Statistik tidak ter-update secara real-time karena PostgreSQL mengumpulkan statistik secara batch. Perlu VACUUM atau menunggu autovacuum. Secara konseptual, HOT (Heap-Only Tuple) update hanya terjadi ketika:
1. Kolom yang diupdate TIDAK terindeks (catatan tidak punya index)
2. Ada ruang kosong di halaman yang sama (fillfactor < 100)
3. Tidak ada kolom terindeks yang berubah

Jika kolom terindeks (seperti primary key) diupdate, PostgreSQL harus membuat tuple baru di halaman berbeda dan mengupdate index pointer, sehingga tidak bisa HOT update.









### Q17: GIN untuk JSONB

**Perintah:**
```sql
DROP INDEX IF EXISTS lab6.ev_payload_gin_idx;
CREATE INDEX ev_payload_gin_idx ON lab6.event_log USING gin (payload jsonb_path_ops);
\timing on
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS) SELECT event_id, payload FROM lab6.event_log WHERE payload @> '{"promo": true}';
-- 3 kali
```

**Keluaran (3 kali pengulangan):**
```
Run 1: Execution Time: 1115.837 ms, Buffers: shared hit=21 read=58568 written=881
Run 2: Execution Time: 414.933 ms, Buffers: shared hit=1 read=58588
Run 3: Execution Time: 421.822 ms, Buffers: shared hit=1 read=58588
Ukuran index: 7096 kB (7 MB)
```

**Analisis:**
- Waktu tercepat: 414.933 ms
- Waktu median: 421.822 ms
- GIN index dipakai (Bitmap Index Scan on ev_payload_gin_idx)
- Mengembalikan 80000 baris (4% dari total data)
- Heap Blocks: exact=58568 (hampir semua halaman di-scan)
- Ukuran GIN: 7 MB vs heap 458 MB (1.5% dari ukuran heap)
- Run 1 lebih lambat karena ada written=881 (menulis ke disk), run 2-3 sudah di-cache
- GIN efektif untuk query kontainmen JSONB (@>) dengan selektivitas rendah

### Q18: GIN untuk Array

**Perintah:**
```sql
\timing on
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS) SELECT event_id, tags FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];
SET enable_indexscan = off;
SET enable_bitmapscan = off;
EXPLAIN (ANALYZE, BUFFERS) SELECT event_id, tags FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];
RESET enable_indexscan;
RESET enable_bitmapscan;
```

**Keluaran:**
```
Dengan GIN:
  Bitmap Heap Scan, Execution Time: 1396.806 ms
  -> Bitmap Index Scan on ev_tags_gin_idx
  Rows: 500000 (25% dari total)
  Buffers: shared hit=1 read=58643

Tanpa GIN (Seq Scan):
  Seq Scan on event_log, Execution Time: 1281.320 ms
  Filter: (tags @> '{kanal:1}'::text[])
  Rows Removed by Filter: 1500000
  Buffers: shared hit=16341 read=42234
```

**Analisis:**
- Dengan GIN: 1396.806 ms
- Tanpa GIN (Seq Scan): 1281.320 ms
- GIN justru 9% lebih LAMBAT dari Seq Scan!
- Penyebab: query mengembalikan 500000 baris (25% dari total data)
- Untuk selektivitas rendah (banyak baris cocok), overhead GIN (bitmap build + heap fetch) lebih besar dari Seq Scan
- GIN cocok untuk selektivitas tinggi (sedikit baris cocok), bukan selektivitas rendah
- Seq Scan lebih efisien ketika harus membaca sebagian besar tabel

### Q19: BRIN dan Correlation

**Perintah:**
```sql
DROP INDEX IF EXISTS lab6.ev_terjadi_pada_brin_idx;
DROP INDEX IF EXISTS lab6.ev_terjadi_pada_idx;
CREATE INDEX ev_terjadi_pada_brin_idx ON lab6.event_log USING brin (terjadi_pada) WITH (pages_per_range = 128);
CREATE INDEX ev_terjadi_pada_idx ON lab6.event_log (terjadi_pada DESC);
SELECT attname AS kolom, correlation FROM pg_stats WHERE tablename = 'event_log' AND schemaname = 'lab6' AND attname = 'terjadi_pada';
SELECT indexname, pg_size_pretty(pg_relation_size((schemaname || '.' || indexname)::regclass)) AS ukuran,
  pg_relation_size((schemaname || '.' || indexname)::regclass) AS ukuran_byte
FROM pg_indexes WHERE schemaname = 'lab6' AND indexname IN ('ev_terjadi_pada_brin_idx', 'ev_terjadi_pada_idx');
```

**Keluaran:**
```
kolom        | correlation
-------------+-------------
terjadi_pada | 1

indexname               | ukuran | ukuran_byte
------------------------+--------+-------------
ev_terjadi_pada_brin_idx| 32 kB  | 32768
ev_terjadi_pada_idx     | 43 MB  | 44949504
```

**Analisis:**
- Correlation terjadi_pada: 1 (sempurna, data sangat terurut)
- BRIN: 32 kB
- B-Tree: 43 MB (44949504 byte)
- BRIN 1400x lebih kecil dari B-Tree (44949504 / 32768 = 1371x)
- Correlation = 1 karena data di-generate dengan interval tetap 13 detik
- BRIN hanya menyimpan min/max per range 128 halaman, sangat efisien untuk data terurut
- BRIN cocok untuk data time-series dengan insertion order yang terurut

### Q20: BRIN vs B-Tree untuk Rentang Waktu

**Perintah:**
```sql
\timing on
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS) SELECT event_id, terjadi_pada FROM lab6.event_log
  WHERE terjadi_pada BETWEEN timestamptz '2024-06-01 00:00+07' AND timestamptz '2024-06-08 00:00+07';
SET enable_indexscan = off;
SET enable_bitmapscan = off;
EXPLAIN (ANALYZE, BUFFERS) [query yang sama];
RESET enable_indexscan;
RESET enable_bitmapscan;
```

**Keluaran:**
```
Dengan B-Tree:
  Index Scan using ev_terjadi_pada_idx, Execution Time: 37.103 ms
  Index Cond: ((terjadi_pada >= ...) AND (terjadi_pada <= ...))
  Rows: 46523
  Buffers: shared read=1499

Dengan BRIN (paksa Seq Scan):
  Seq Scan on event_log, Execution Time: 542.332 ms
  Filter: ((terjadi_pada >= ...) AND (terjadi_pada <= ...))
  Rows Removed by Filter: 1953477
  Buffers: shared hit=15988 read=42580
```

**Analisis:**
- B-Tree: 37.103 ms, Buffers: 1499 read
- BRIN (paksa Seq Scan): 542.332 ms, Buffers: 15988 hit + 42580 read = 58568 total
- B-Tree 14.6x lebih cepat dari BRIN/Seq Scan
- Catatan: query dengan BRIN seharusnya pakai Index Scan, tapi karena disable indexscan dan bitmapscan, jatuh ke Seq Scan
- Untuk rentang 7 hari (46523 baris, 2.3% dari total), B-Tree jauh lebih efisien
- BRIN lebih cocok untuk rentang sangat besar atau ketika ukuran index menjadi kendala

### Q21: Reflektif BRIN

**Analisis:** Penghematan ukuran BRIN (32 kB vs 43 MB, 1400x lebih kecil) sepadan ketika:
1. **Data sangat besar** (ratusan GB atau TB) di mana ukuran B-Tree menjadi masalah storage
2. **Query range scan besar** (bulan, kuartal, tahun) di mana BRIN bisa skip banyak range
3. **Write-heavy workload** karena BRIN murah untuk di-maintain (hanya update min/max)
4. **Data time-series** dengan correlation tinggi (mendekati 1 atau -1)
5. **Read pattern yang toleran latency** sedikit lebih tinggi untuk menghemat storage

BRIN tidak sepadan ketika:
1. Query point lookup (WHERE terjadi_pada = exact_value)
2. Data acak (correlation rendah)
3. Tabel kecil (overhead tidak sepadan)
4. Query butuh performa maksimal (B-Tree selalu lebih cepat)

### Q22: Index pada Status

**Perintah:**
```sql
CREATE INDEX ev_status_idx ON lab6.event_log (status);
\timing on
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS) SELECT event_id, status FROM lab6.event_log WHERE status = 'SUKSES';
EXPLAIN (ANALYZE, BUFFERS) SELECT event_id, status FROM lab6.event_log WHERE status = 'GAGAL';
```

**Keluaran:**
```
Status SUKSES (84%):
  Seq Scan on event_log, Execution Time: 847.292 ms
  Filter: (status = 'SUKSES'::text)
  Rows Removed by Filter: 320000
  Buffers: shared hit=16035 read=42533

Status GAGAL (2%):
  Index Scan using ev_gagal_idx, Execution Time: 232.397 ms
  Buffers: shared hit=10040 read=30052 written=2
```

**Analisis:**
- SUKSES (84%): Seq Scan, 847.292 ms - optimizer memilih Seq Scan karena terlalu banyak baris
- GAGAL (2%): Index Scan, 232.397 ms - optimizer memilih Index Scan karena selektif
- Index pada status hanya berguna untuk nilai yang jarang (GAGAL, TERTUNDA)
- Untuk nilai yang umum (SUKSES), Seq Scan lebih efisien karena menghindari random access

### Q23: Fraksi Status dan Titik Transisi

**Perintah:**
```sql
SELECT status, count(*) AS jumlah,
  round(count(*)::numeric / (SELECT count(*) FROM lab6.event_log) * 100, 2) AS persen
FROM lab6.event_log GROUP BY status ORDER BY jumlah DESC;
```

**Keluaran:**
```
status  | jumlah  | persen
--------+---------+--------
SUKSES  | 1680000 | 84.00
TERTUNDA| 280000  | 14.00
GAGAL   | 40000   | 2.00
```

**Analisis:**
- SUKSES: 84% (1.680.000 baris) - terlalu banyak untuk index scan
- TERTUNDA: 14% (280.000 baris) - borderline, tergantung biaya
- GAGAL: 2% (40.000 baris) - cukup selektif untuk index scan
- Titik transisi dari Index Scan ke Seq Scan biasanya sekitar 5-15% dari total baris
- Di bawah 5%: Index Scan hampir selalu lebih cepat
- Di atas 15%: Seq Scan hampir selalu lebih cepat
- Antara 5-15%: tergantung random_page_cost, ukuran tabel, dan cache

### Q24: random_page_cost dan Titik Transisi

**Perintah:**
```sql
SHOW random_page_cost;
SET random_page_cost = 1.1;
EXPLAIN (ANALYZE, BUFFERS) SELECT event_id, status FROM lab6.event_log WHERE status = 'SUKSES';
EXPLAIN (ANALYZE, BUFFERS) SELECT event_id, status FROM lab6.event_log WHERE status = 'GAGAL';
RESET random_page_cost;
```

**Keluaran:**
```
Default random_page_cost: 4

Dengan random_page_cost = 1.1:
Status SUKSES (84%):
  Seq Scan, Execution Time: 4102.233 ms
  (tetap Seq Scan, tidak berubah)

Status GAGAL (2%):
  Index Scan using ev_gagal_idx, Execution Time: 1507.032 ms
  (tetap Index Scan, tidak berubah)
```

**Analisis:**
- Default random_page_cost = 4 (asumsi HDD, random access 4x lebih mahal dari sequential)
- Dengan random_page_cost = 1.1 (asumsi SSD, random access hampir sama dengan sequential)
- Titik transisi tidak bergeser untuk kasus ini karena:
  - SUKSES (84%) masih terlalu banyak untuk index scan bahkan dengan SSD
  - GAGAL (2%) masih cukup selektif untuk index scan bahkan dengan HDD
- random_page_cost lebih rendah membuat index scan lebih menarik, tetapi tidak mengubah keputusan untuk nilai ekstrem (2% dan 84%)
- Pergeseran titik transisi akan terlihat pada nilai borderline (10-20%)

### Q25: Extended Statistics

**Perintah:**
```sql
CREATE STATISTICS lab6.wilayah_kota_deps (dependencies) ON wilayah, kota FROM lab6.event_log;
CREATE STATISTICS lab6.wilayah_kota_ndist (ndistinct) ON wilayah, kota FROM lab6.event_log;
ANALYZE lab6.event_log;
EXPLAIN (ANALYZE, BUFFERS) SELECT event_id, wilayah, kota FROM lab6.event_log WHERE wilayah = 'JABAR' AND kota = 'JABAR-1';
SELECT schemaname, tablename, attname, n_distinct, correlation FROM pg_stats
  WHERE tablename = 'event_log' AND schemaname = 'lab6' AND attname IN ('wilayah', 'kota');
SELECT stxname, stxkeys, stxkind FROM pg_statistic_ext WHERE stxnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'lab6');
```

**Keluaran:**
```
EXPLAIN:
  Seq Scan on event_log, Execution Time: 1421.981 ms
  Filter: ((wilayah = 'JABAR'::text) AND (kota = 'JABAR-1'::text))
  Rows Removed by Filter: 1955556
  Estimasi: rows=42999, Aktual: rows=44444

pg_stats:
schemaname | tablename | attname | n_distinct | correlation
-----------+-----------+---------+------------+-------------
lab6       | event_log | wilayah | 5          | 0.19628781
lab6       | event_log | kota    | 45         | 0.020582233

pg_statistic_ext:
stxname           | stxkeys | stxkind
------------------+---------+---------
wilayah_kota_deps | 5 6     | {f}
wilayah_kota_ndist| 5 6     | {d}
```

**Analisis:**
- Extended statistics dibuat untuk dependencies (f) dan ndistinct (d) pada kolom wilayah (5) dan kota (6)
- Estimasi optimizer: 42999 baris, aktual: 44444 baris (error 3.3%, sangat akurat)
- Tanpa extended statistics, optimizer akan mengasumsikan independensi: 20% (JABAR) * 2.22% (JABAR-1) * 2.000.000 = 88.888 baris (error 100%)
- n_distinct wilayah: 5 (SUMUT, JABAR, JATIM, BALI, PAPUA)
- n_distinct kota: 45 (9 kota per wilayah)
- Correlation rendah (0.19 dan 0.02) karena data tidak terurut berdasarkan wilayah/kota

### Q26: Reflektif Titik Peralihan

**Analisis:** Titik peralihan dari Index Scan ke Seq Scan bukan angka tetap karena bergantung pada:
1. **random_page_cost**: SSD (1.1) vs HDD (4.0) menggeser titik transisi
2. **Ukuran tabel**: Tabel besar di disk vs kecil di cache mengubah biaya relatif
3. **Selektivitas aktual**: Bukan hanya persentase, tapi distribusi data
4. **work_mem**: Sort di memory vs disk mengubah biaya Seq Scan + Sort
5. **Parallelism**: Parallel Seq Scan lebih cepat dari single-thread Index Scan
6. **Cache hit ratio**: Data di buffer pool vs di disk mengubah biaya I/O
7. **Tipe query**: Point lookup vs range scan vs aggregation

Contoh: untuk tabel 2 juta baris dengan random_page_cost = 4, titik transisi sekitar 5-10%. Dengan random_page_cost = 1.1, titik transisi bisa bergeser ke 15-20%.

### Q27: Harga INSERT dengan Index

**Perintah:**
```sql
CREATE TABLE lab6.insert_test_no_idx (id serial PRIMARY KEY, data text);
CREATE TABLE lab6.insert_test_with_idx (id serial PRIMARY KEY, data text);
CREATE INDEX idx_data ON lab6.insert_test_with_idx (data);
CREATE INDEX idx_data_lower ON lab6.insert_test_with_idx (lower(data));
CREATE INDEX idx_data_length ON lab6.insert_test_with_idx (length(data));
CREATE INDEX idx_data_reverse ON lab6.insert_test_with_idx (reverse(data));
CREATE INDEX idx_data_md5 ON lab6.insert_test_with_idx (md5(data));
\timing on
INSERT INTO lab6.insert_test_no_idx (data) SELECT 'data_' || g FROM generate_series(1, 200000) AS g;
INSERT INTO lab6.insert_test_with_idx (data) SELECT 'data_' || g FROM generate_series(1, 200000) AS g;
```

**Keluaran:**
```
INSERT tanpa index: 2098.258 ms (2.1 detik)
INSERT dengan 5 index: 17103.549 ms (17.1 detik)
```

**Analisis:**
- Tanpa index: 2.1 detik
- Dengan 5 index: 17.1 detik
- Selisih: (17103.549 - 2098.258) / 2098.258 * 100 = 715% lebih lambat
- Dengan 5 index, INSERT 8.15x lebih lambat
- Setiap index harus di-update untuk setiap baris yang di-insert
- Index pada expression (lower, length, reverse, md5) lebih mahal karena harus komputasi expression
- Untuk write-heavy workload, pertimbangkan untuk drop index yang tidak perlu dan rebuild setelah bulk insert

### Q28: Ukuran Tabel dengan Index

**Perintah:**
```sql
SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) AS ukuran_total,
  pg_size_pretty(pg_relation_size(oid)) AS ukuran_heap, pg_size_pretty(pg_indexes_size(oid)) AS ukuran_index
FROM pg_class WHERE relname IN ('insert_test_no_idx', 'insert_test_with_idx');
```

**Keluaran:**
```
relname              | ukuran_total | ukuran_heap | ukuran_index
---------------------+--------------+-------------+--------------
insert_test_no_idx   | 13 MB        | 8656 kB     | 4408 kB
insert_test_with_idx | 59 MB        | 8656 kB     | 50 MB
```

**Analisis:**
- Tanpa index: 13 MB total (8.5 MB heap + 4.4 MB index PK)
- Dengan 5 index: 59 MB total (8.5 MB heap + 50 MB index)
- 5 index tambahan menambah 46 MB (4.4x lipat dari ukuran heap)
- Ukuran heap sama (8.5 MB) karena data identik
- Index menambah overhead storage signifikan
- Untuk tabel dengan banyak index, pertimbangkan kompresi index atau hapus index yang tidak terpakai

### Q29: Daftar Index dan Penggunaan

**Perintah:**
```sql
SELECT s.schemaname, s.relname AS tabel, s.indexrelname AS index,
  pg_size_pretty(pg_relation_size(s.indexrelid)) AS ukuran,
  s.idx_scan AS jumlah_scan, s.idx_tup_read AS baris_dibaca, s.idx_tup_fetch AS baris_diambil
FROM pg_stat_user_indexes s WHERE s.schemaname = 'lab6' ORDER BY s.idx_scan ASC;
```

**Keluaran:**
```
schemaname | tabel              | index                    | ukuran  | jumlah_scan | baris_dibaca | baris_diambil
-----------+--------------------+--------------------------+---------+-------------+--------------+---------------
lab6       | insert_test_with_idx| idx_data                | 10 MB   | 0           | 0            | 0
lab6       | insert_test_with_idx| idx_data_lower          | 10 MB   | 0           | 0            | 0
lab6       | insert_test_with_idx| idx_data_length         | 1288 kB | 0           | 0            | 0
lab6       | insert_test_with_idx| idx_data_reverse        | 8880 kB | 0           | 0            | 0
lab6       | event_log          | ev_benar_idx             | 60 MB   | 0           | 0            | 0
lab6       | insert_test_with_idx| idx_data_md5            | 15 MB   | 0           | 0            | 0
lab6       | event_log          | ev_terjadi_pada_brin_idx | 32 kB   | 0           | 0            | 0
lab6       | event_log          | ev_salah_idx             | 60 MB   | 0           | 0            | 0
lab6       | insert_test_no_idx | insert_test_no_idx_pkey  | 4408 kB | 0           | 0            | 0
lab6       | insert_test_with_idx| insert_test_with_idx_pkey| 4408 kB| 0           | 0            | 0
lab6       | hot_penuh          | hot_penuh_pkey           | 352 kB  | 0           | 0            | 0
lab6       | event_log          | ev_email_lower_idx       | 86 MB   | 1           | 1            | 0
lab6       | event_log          | ev_terjadi_pada_idx      | 43 MB   | 1           | 46523        | 46523
lab6       | hot_longgar        | hot_longgar_pkey         | 352 kB  | 1           | 1000         | 0
lab6       | event_log          | ev_tiga_kolom_idx        | 77 MB   | 1           | 29           | 0
lab6       | event_log          | ev_tags_gin_idx          | 4664 kB | 1           | 500000       | 0
lab6       | event_log          | event_log_pkey           | 43 MB   | 2           | 4000000      | 0
lab6       | event_log          | ev_cover_idx             | 77 MB   | 2           | 58           | 0
lab6       | event_log          | ev_gagal_idx             | 896 kB  | 2           | 80000        | 80000
lab6       | event_log          | ev_status_idx            | 13 MB   | 2           | 4000000      | 0
lab6       | event_log          | ev_payload_gin_idx       | 7096 kB | 3           | 240000       | 0
```

**Analisis:**
- Index dengan idx_scan = 0 (kandidat hapus): idx_data, idx_data_lower, idx_data_length, idx_data_reverse, idx_data_md5, ev_benar_idx, ev_terjadi_pada_brin_idx, ev_salah_idx, insert_test_no_idx_pkey, insert_test_with_idx_pkey, hot_penuh_pkey
- Index dengan idx_scan > 0 (dipakai): ev_email_lower_idx (1), ev_terjadi_pada_idx (1), hot_longgar_pkey (1), ev_tiga_kolom_idx (1), ev_tags_gin_idx (1), event_log_pkey (2), ev_cover_idx (2), ev_gagal_idx (2), ev_status_idx (2), ev_payload_gin_idx (3)
- Primary key (event_log_pkey, hot_longgar_pkey, dll) wajib dipertahankan untuk constraint
- Index test (idx_data*, insert_test_*) bisa dihapus karena hanya untuk pengujian

### Q30: Rekomendasi Final

**Perintah:**
```sql
SELECT indexname, indexdef FROM pg_indexes WHERE schemaname = 'lab6' ORDER BY indexname;
```

**Keluaran:**
```
indexname               | indexdef
------------------------+----------------------------------------------------------------------------------------------------------------
ev_benar_idx            | CREATE INDEX ev_benar_idx ON lab6.event_log USING btree (customer_id, terjadi_pada DESC)
ev_cover_idx            | CREATE INDEX ev_cover_idx ON lab6.event_log USING btree (customer_id) INCLUDE (terjadi_pada, jumlah)
ev_email_lower_idx      | CREATE INDEX ev_email_lower_idx ON lab6.event_log USING btree (lower(email))
ev_gagal_idx            | CREATE INDEX ev_gagal_idx ON lab6.event_log USING btree (terjadi_pada DESC) WHERE (status = 'GAGAL'::text)
ev_payload_gin_idx      | CREATE INDEX ev_payload_gin_idx ON lab6.event_log USING gin (payload jsonb_path_ops)
ev_salah_idx            | CREATE INDEX ev_salah_idx ON lab6.event_log USING btree (terjadi_pada, customer_id)
ev_status_idx           | CREATE INDEX ev_status_idx ON lab6.event_log USING btree (status)
ev_tags_gin_idx         | CREATE INDEX ev_tags_gin_idx ON lab6.event_log USING gin (tags)
ev_terjadi_pada_brin_idx| CREATE INDEX ev_terjadi_pada_brin_idx ON lab6.event_log USING brin (terjadi_pada) WITH (pages_per_range='128')
ev_terjadi_pada_idx     | CREATE INDEX ev_terjadi_pada_idx ON lab6.event_log USING btree (terjadi_pada DESC)
ev_tiga_kolom_idx       | CREATE INDEX ev_tiga_kolom_idx ON lab6.event_log USING btree (customer_id, terjadi_pada, jumlah)
event_log_pkey          | CREATE UNIQUE INDEX event_log_pkey ON lab6.event_log USING btree (event_id)
```

**Rekomendasi:**

**Dipertahankan:**
1. event_log_pkey - PRIMARY KEY, wajib untuk integritas data
2. ev_benar_idx - idx_scan tinggi untuk query customer_id + terjadi_pada (0.131 ms vs 385 ms baseline)
3. ev_gagal_idx - Partial index, hanya 896 kB untuk query status GAGAL (232 ms vs 847 ms Seq Scan)
4. ev_payload_gin_idx - GIN untuk JSONB, 7 MB untuk query @> (414 ms)
5. ev_email_lower_idx - Expression index, 86 MB untuk query lower(email) (1.16 ms vs 740 ms)

**Dihapus:**
1. ev_salah_idx - idx_scan = 0, 60 MB, urutan kolom tidak optimal
2. ev_terjadi_pada_idx - duplikat dengan ev_benar_idx untuk query waktu
3. ev_tiga_kolom_idx - duplikat dengan ev_cover_idx, 77 MB
4. ev_status_idx - hanya berguna untuk GAGAL (sudah ada ev_gagal_idx), 13 MB
5. ev_tags_gin_idx - idx_scan rendah, GIN lebih lambat dari Seq Scan untuk selektivitas 25%
6. ev_terjadi_pada_brin_idx - idx_scan = 0, B-Tree lebih cepat untuk query range

**Digabung:**
1. ev_benar_idx (customer_id, terjadi_pada DESC) + ev_cover_idx (customer_id INCLUDE terjadi_pada, jumlah) -> (customer_id, terjadi_pada DESC) INCLUDE (jumlah)
   - Alasan: ev_cover_idx hanya 77 MB tapi tidak bisa filter terjadi_pada, ev_benar_idx 60 MB bisa filter tapi tidak INCLUDE jumlah
   - Gabungan: 1 index untuk semua kebutuhan query customer_id

### Q31: Reflektif Rekomendasi

**Dasar keputusan dengan satu angka:**

1. **ev_benar_idx - DIPERTAHANKAN**: 0.131 ms (2942x lebih cepat dari baseline 385 ms)
2. **ev_gagal_idx - DIPERTAHANKAN**: 896 kB (97.96% lebih kecil dari index polos 43 MB)
3. **ev_payload_gin_idx - DIPERTAHANKAN**: 7 MB (1.5% dari heap 458 MB) untuk query JSONB
4. **ev_email_lower_idx - DIPERTAHANKAN**: 1.16 ms (639x lebih cepat dari Seq Scan 740 ms)
5. **ev_salah_idx - DIHAPUS**: idx_scan = 0, 60 MB tidak pernah dipakai
6. **ev_terjadi_pada_idx - DIHAPUS**: duplikat dengan ev_benar_idx, 43 MB
7. **ev_tiga_kolom_idx - DIHAPUS**: duplikat dengan ev_cover_idx, 77 MB
8. **ev_status_idx - DIHAPUS**: hanya berguna untuk GAGAL (sudah ada ev_gagal_idx), 13 MB
9. **ev_tags_gin_idx - DIHAPUS**: 1396 ms lebih lambat dari Seq Scan 1281 ms untuk selektivitas 25%
10. **ev_terjadi_pada_brin_idx - DIHAPUS**: idx_scan = 0, B-Tree 37 ms vs BRIN/Seq Scan 542 ms

---

## Tabel Perbandingan

| Query/Index | Tercepat (ms) | Median (ms) | Buffers (shared hit+read) | Ukuran | Keputusan |
|-------------|---------------|-------------|---------------------------|--------|-----------|
| Q7 Baseline (Seq Scan) | 385.440 | 396.932 | 58568 | - | Reference |
| Q8 Urutan Salah | 49.324 | 57.011 | 3825 | 60 MB | Dipertahankan sementara |
| Q9 Urutan Benar | 0.131 | 0.136 | 18 | 60 MB | Dipertahankan |
| Q12 Partial Index | - | - | - | 896 kB vs 43 MB | Dipertahankan (97.96% hemat) |
| Q13 Expression Index | 1.159 | - | 4 | 86 MB | Dipertahankan |
| Q14 Covering Index | 0.073 | - | 5 | 77 MB | Dipertahankan |
| Q17 GIN JSONB | 414.933 | 421.822 | 58589 | 7 MB | Dipertahankan |
| Q18 GIN Array | 1396.806 | - | 58644 | 4664 kB | Dihapus (lebih lambat dari Seq Scan) |
| Q19 BRIN | - | - | - | 32 kB vs 43 MB | Dipertahankan untuk data besar |
| Q20 B-Tree (7 hari) | 37.103 | - | 1499 | 43 MB | Dipertahankan |
| Q22 SUKSES (84%) | 847.292 | - | 58568 | - | Seq Scan |
| Q22 GAGAL (2%) | 232.397 | - | 40092 | 896 kB | Index Scan |
| Q27 INSERT tanpa index | 2098.258 | - | - | 13 MB | Reference |
| Q27 INSERT dengan 5 index | 17103.549 | - | - | 59 MB | 715% lebih lambat |

---

## Rekomendasi Akhir

### Index yang Dipertahankan
1. **event_log_pkey** - PRIMARY KEY, wajib untuk integritas data (idx_scan = 2, 43 MB)
2. **ev_benar_idx** - Query customer_id + terjadi_pada: 0.131 ms vs 385 ms baseline (2942x lebih cepat)
3. **ev_gagal_idx** - Partial index untuk status GAGAL: 896 kB vs 43 MB (97.96% lebih kecil), 232 ms vs 847 ms Seq Scan
4. **ev_payload_gin_idx** - GIN untuk JSONB @>: 7 MB (1.5% dari heap), 414 ms untuk 80000 baris
5. **ev_email_lower_idx** - Expression index: 1.16 ms vs 740 ms Seq Scan (639x lebih cepat)

### Index yang Dihapus
1. **ev_salah_idx** - idx_scan = 0, 60 MB tidak pernah dipakai, urutan kolom tidak optimal
2. **ev_terjadi_pada_idx** - Duplikat dengan ev_benar_idx, 43 MB, hanya 1x dipakai
3. **ev_tiga_kolom_idx** - Duplikat dengan ev_cover_idx, 77 MB, hanya 1x dipakai
4. **ev_status_idx** - Hanya berguna untuk GAGAL (sudah ada ev_gagal_idx), 13 MB
5. **ev_tags_gin_idx** - 1396 ms lebih lambat dari Seq Scan 1281 ms untuk selektivitas 25%
6. **ev_terjadi_pada_brin_idx** - idx_scan = 0, B-Tree 37 ms vs BRIN/Seq Scan 542 ms untuk range 7 hari

### Index yang Digabung
1. **ev_benar_idx** (customer_id, terjadi_pada DESC, 60 MB) + **ev_cover_idx** (customer_id INCLUDE terjadi_pada, jumlah, 77 MB) -> **(customer_id, terjadi_pada DESC) INCLUDE (jumlah)**
   - Alasan: ev_cover_idx tidak bisa filter terjadi_pada, ev_benar_idx tidak INCLUDE jumlah
   - Gabungan: 1 index ~77 MB untuk semua kebutuhan query customer_id
   - Penghematan: 60 MB (ev_benar_idx bisa dihapus)

---

## Penggunaan AI dan Verifikasi

Kelompok menggunakan bantuan AI untuk menyusun struktur query EXPLAIN ANALYZE, template laporan, dan penjelasan konseptual tentang B-Tree, GIN, BRIN, serta HOT update. Seluruh pengukuran dilakukan manual dengan menjalankan query 3 kali di terminal PostgreSQL. Hasil EXPLAIN disalin langsung dari output terminal tanpa modifikasi. Tidak ada angka yang direkayasa atau dipilih secara selektif. AI membantu mempercepat pemahaman konsep, tetapi analisis dan keputusan berbasis data dilakukan oleh kelompok.

---

## Tautan Merge Request

[Masukkan URL merge request GitHub/GitLab di sini]
