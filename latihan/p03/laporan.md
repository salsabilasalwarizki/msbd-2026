# Laporan Latihan Kelompok Pertemuan 3

## Anggota dan Kontribusi

| Nama | NIM | Kontribusi |
|------|-----|------------|
| Salsabila Salwa Rizki | 251402123 | Q1-Q5 (Subquery), Refleksi A, setup q00 |
| Nadia Stevany Br Situmorang | 251402073 | Q6-Q9 (CTE & Recursive CTE), Refleksi B |
| Sina Mahdi Sitanggang | 251402008 | Q10-Q15 (Window Function), Refleksi C |
| Jesqueen Maria Purba | 251402099 | Q16-Q20 (Agregasi & JSONB), R1, Refleksi D-E |

## Refleksi A - Subquery

### A1: Pada Q4, apa tepatnya yang membuat NOT IN berbahaya, dan bagaimana memeriksa apakah sebuah kolom rawan terhadap masalah itu?

NOT IN itu bahaya kalau subquery-nya ngasilin nilai NULL. Contohnya kayak `x NOT IN (1, 2, NULL)`, itu sebenarnya dievaluasi jadi `x <> 1 AND x <> 2 AND x <> NULL`. Nah, masalahnya perbandingan sama NULL itu selalu ngasilin UNKNOWN, bukan TRUE atau FALSE. Maka dari itu, seluruh kondisinya jadi UNKNOWN dan gak ada baris yang dikembalikan sama sekali.

Buat ngecek apakah sebuah kolom rawan terhadap masalah ini, kita bisa pakai query kayak gini:

Kalau di Pagila, kolom `film_id` di tabel `inventory` itu gak ada yang NULL, makanya NOT IN dan NOT EXISTS ngasilin baris yang sama persis. Tapi kalau di database lain yang kolomnya bisa NULL, hasilnya bakalan beda.

### A2: Pada Q5, berapa kali subquery dievaluasi secara konseptual, dan mengapa “sekali per baris luar” belum tentu sama dengan yang benar-benar dikerjakan mesin?

Secara konsep, subquery berkorelasi itu dievaluasi sekali per baris luar. Tapi kenyataannya, mesin query PostgreSQL itu pinter, dia sering ngelakuin optimasi jadi hash join atau semi-join. Maka dari itu, evaluasi aktualnya bisa jauh lebih sedikit dari yang kita kira.

Optimizer-nya bisa ngenalin pola dan milih strategi eksekusi yang lebih efisien daripada evaluasi naif "sekali per baris".

## Refleksi B - CTE dan Recursive CTE

### B1: Pada Q7, mengapa recursive term hanya melihat baris yang baru dihasilkan pada iterasi sebelumnya, dan apa akibatnya jika ia melihat seluruh hasil?

PostgreSQL itu pakai algoritma "working table" buat recursive CTE. Jadi recursive term-nya cuma memproses baris yang dihasilin di iterasi sebelumnya, bukan seluruh hasil akumulatif. Ini buat mencegah duplikasi perhitungan.

Kalau misalnya dia lihat seluruh hasil, bakal terjadi duplikasi dan kemungkinan infinite loop kalau graf-nya bersiklus.

### B2: Kapan mengganti UNION ALL dengan UNION dapat menghentikan siklus, dan mengapa itu tetap bukan solusi yang baik?

UNION (tanpa ALL) itu ngilangin duplikat, jadi kalau suatu baris udah pernah dihasilin, dia gak bakal diproses lagi. Ini emang bisa ngehentiin siklus sederhana. Tapi ini bukan solusi yang bagus karena beberapa alasan:

1. Performanya buruk karena harus ngecek duplikat di setiap iterasi
2. Gak nangani kasus di mana jalur berbeda tapi node-nya sama
3. CYCLE atau pelacakan jalur itu lebih eksplisit dan bisa diandalkan

Maka dari itu, lebih baik pakai CYCLE clause atau pelacakan array buat nangani siklus di recursive CTE.


## Refleksi C - Window Function

### C1: Pada Q14, berapa tanggal yang berbeda, dan sifat data apa pada tabel payment yang menyebabkan perbedaan?

Nah ini yang menarik. Di tabel `payment` Pagila, ada beberapa tanggal yang punya transaksi ganda (disebut peer). Frame RANGE default itu nyertain semua peer dengan nilai ORDER BY yang sama, makanya kumulatifnya jadi "melompat".

Jumlah tanggal yang berbeda antara frame ROWS dan RANGE bisa dilihat dari hasil query Q14:

```sql
Get-Content latihan/p03/q14_rows_vs_range.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

Perbedaan terjadi karena ada tanggal dengan banyak transaksi yang nilainya sama, dan RANGE ngelakuin grouping berdasarkan nilai, bukan berdasarkan baris.

### C2: Jika Q13 menjadi laporan resmi keuangan, versi mana yang benar dan mengapa kesalahan frame sulit ditemukan melalui pengujian biasa?

Kalau Q13 ini jadi laporan resmi keuangan, yang benar itu pakai ROWS. Alasannya karena setiap transaksi harus dihitung sekali secara berurutan. RANGE bisa nggabungin transaksi di hari yang sama, maka kumulatifnya gak bakal mencerminkan aliran kas yang sebenarnya.

Kesalahan frame ini susah ditemukan lewat pengujian biasa karena hasilnya tetap terlihat "masuk akal" (angkanya naik terus), cuma aja gak presisi per transaksi. Makanya penting buat ngerti perbedaan ROWS vs RANGE.

### C3: Pada Q15, apa yang terjadi pada total belanja jika ORDER BY ditambahkan ke dalam OVER tanpa menuliskan frame?

Kalau ORDER BY ditambahin ke OVER() tanpa frame eksplisit, frame default-nya jadi `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. Ini berarti total belanja bakal jadi **running total**, bukan total keseluruhan partisi.

Maka dari itu, kalau mau total keseluruhan, kita harus pakai `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` atau hilangkan ORDER BY sama sekali.


## Refleksi D - Agregasi dan Operasi Himpunan

### D1: Pada Q16, tanpa GROUPING(), bagaimana pembaca membedakan subtotal dari baris data yang kolomnya memang kosong?

Tanpa GROUPING(), nilai NULL itu ambigu. Bisa berarti "tidak ada data" atau bisa juga berarti "subtotal". GROUPING() itu ngembaliin 1 untuk kolom yang di-rollup, maka kita bisa ganti NULL dengan label eksplisit kayak 'SEMUA'.

Ini penting buat readability laporan, soalnya pembaca gak bakal bingung apakah NULL itu data kosong atau subtotal.

### D2: Pada Q17, mengapa versi FILTER dan CASE WHEN dapat memberi rata-rata berbeda walaupun jumlah baris sama?

Kedua pendekatan ini ngasih hasil yang sama kalau dipake dengan benar. Tapi perbedaan muncul kalau CASE WHEN pake ELSE 0, yang mana bakal masukin 0 ke perhitungan AVG.

Maka dari itu, FILTER lebih aman dan lebih ringkas buat agregasi kondisional. Tapi CASE WHEN tetap berguna kalau kita butuh logika yang lebih kompleks.


## Refleksi E - JSONB

### E1: Dari nomor transaksi, status, jumlah, dan identitas pelanggan di dalam payload, mana yang sebaiknya dipromosikan menjadi kolom relasional dengan constraint dan mana yang tepat tetap berada di JSON? Berikan alasan untuk setiap pilihan.

Dari payload JSONB yang kita punya :

- trx (nomor transaksi): Sebaiknya dipromosikan jadi kolom relasional karena unik per transaksi dan sering dipake buat JOIN dan pencarian. Tambahin constraint UNIQUE biar gak ada duplikat.

- status: Juga sebaiknya dipromosikan karena sering dipake buat filtering (kayak `WHERE status = 'lunas'`) dan bisa dikasih constraint CHECK.

- jumlah: Wajib dipromosikan karena sering dipake buat agregasi (SUM, AVG) dan perhitungan matematis. Tambahin constraint CHECK (jumlah > 0) buat validasi.

- pelanggan (id, kota): Bisa dipromosikan kalau pelanggan itu entitas terpisah dengan tabel sendiri. Tapi kalau pelanggannya dinamis atau gak terstruktur, mending tetap di JSON.

- kontak (array): Tetap di JSON aja karena sifatnya dinamis, jumlahnya bervariasi, dan gak butuh constraint ketat. Ini cocok buat data yang strukturnya bisa berubah-ubah.

## Temuan Q14

Query perbandingan antara frame ROWS dan RANGE pada CTE omzet_harian menghasilkan 0 baris yang berbeda. Hal ini terjadi karena setelah data di-group per tanggal (GROUP BY payment_date::date), setiap tanggal hanya memiliki satu baris dengan nilai omzet yang unik. Tidak ada "peer" (baris dengan nilai ORDER BY yang sama), maka frame ROWS dan RANGE menghasilkan nilai kumulatif yang identik.
Perbedaan antara ROWS dan RANGE baru akan muncul ketika terdapat beberapa baris dengan nilai ORDER BY yang sama (peer). Pada kasus ini, karena setiap tanggal unik setelah agregasi harian, tidak ada peer yang menyebabkan perbedaan.
Untuk benar-benar mengamati perbedaan, kita perlu membandingkan pada level data yang lebih granular (per transaksi) dengan ORDER BY yang hanya menggunakan kolom tanggal (tanpa payment_id), sehingga beberapa transaksi di tanggal yang sama menjadi peer.

## Hasil R1

Berikut adalah hasil sepuluh baris pertama hasil laporan pendapatan bulanan:

PS D:\Documents\msbd-2026> Get-Content latihan/p03/r1_laporan_bulanan.sql | docker compose exec -T postgres psql -U msbd -d pagila
   bulan    |  kategori   | pendapatan | peringkat | bulan_lalu | pertumbuhan_persen | pendapatan_kumulatif | porsi_persen 
------------+-------------+------------+-----------+------------+--------------------+----------------------+--------------
 2017-01-01 | Action      |     371.13 |         1 |            |                    |               371.13 |         7.69
 2017-01-01 | Drama       |     370.15 |         2 |            |                    |               370.15 |         7.67
 2017-01-01 | Documentary |     353.14 |         3 |            |                    |               353.14 |         7.32
 2017-01-01 | Sports      |     333.24 |         4 |            |                    |               333.24 |         6.91
 2017-01-01 | Sci-Fi      |     320.16 |         5 |            |                    |               320.16 |         6.64
 2017-01-01 | Family      |     304.15 |         6 |            |                    |               304.15 |         6.30
 2017-01-01 | New         |     303.39 |         7 |            |                    |               303.39 |         6.29
 2017-01-01 | Foreign     |     296.29 |         8 |            |                    |               296.29 |         6.14
 2017-01-01 | Comedy      |     295.28 |         9 |            |                    |               295.28 |         6.12
 2017-01-01 | Games       |     293.31 |        10 |            |                    |               293.31 |         6.08
(10 rows)


## Tautan Merge Request

Merge request untuk latihan ini bisa diakses di:

https://github.com/salsabilasalwarizki/msbd-2026/pull/1
latihan/p03-sql1
