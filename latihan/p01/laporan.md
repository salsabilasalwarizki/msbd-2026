Laporan Latihan 1 - Pertemuan 1 - Kelompok 9 - Manajemen Sistem Basis Data

Anggota Kelompok :
- Sina Mahdi Sitanggang (251402008)
- Nadia Stevany Br Situmorang (251402073)
- Jesqueen Maria Purba (251402099)
- Salsabila Salwa Rizki (251402123) : Project Manager


A. Keluaran docker --version:
    Docker version 29.7.2, buid a7dcaa6

B. Keluaran docker compose version
    Docker Compose version v5.4.0

C. Keluaran docker compose ps
    NAME         IMAGE            COMMAND                  SERVICE    CREATED       STATUS                 PORTS
    msbd-mongo   mongo:8          "docker-entrypoint.s…"   mongo      3 hours ago   Up 3 hours             0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
    msbd-pg      postgres:17      "docker-entrypoint.s…"   postgres   3 hours ago   Up 3 hours (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
    msbd-redis   redis:7-alpine   "docker-entrypoint.s…"   redis      3 hours ago   Up 3 hours             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp

D. Keluaran SELECT version();
    PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
    (1 row)

E. Jawaban tiga pertanyaan tentang Image, Container, dan Volume
    1. Apa yang dimaksud dengan Docker Image?

    Jawaban: Docker Image adalah sebuah templat atau cetakan yang berisi semua instruksi, kode, dan library yang dibutuhkan untuk menjalankan sebuah aplikasi. Image ini bersifat read-only (hanya bisa dibaca) dan tidak bisa diubah secara langsung. Ibaratnya, image ini adalah file installer atau resep dasar dari sebuah aplikasi sebelum dijalankan.

    2. Apa yang dimaksud dengan Container?

    Jawaban: Container adalah versi yang sedang berjalan (aktif) dari sebuah Docker Image. Jika image adalah cetakannya, maka container adalah hasil jadinya yang benar-benar bekerja di dalam sistem kita. Setiap container berjalan secara terisolasi (terpisah) dari sistem utama, namun tetap menggunakan sumber daya dari komputer host.

    3. Apa fungsi Volume?
    Jawaban: Volume berfungsi sebagai tempat penyimpanan data yang terpisah dari container. Tujuannya adalah agar data yang disimpan di dalam container (seperti data basis data) tidak ikut hilang ketika container tersebut dimatikan, dihapus, atau diperbarui. Dengan menggunakan volume, data kita akan tetap aman, tersimpan secara permanen, dan bisa digunakan kembali oleh container yang baru.

F. Jawaban empat pertanyaan pada Langkah 2
    1. Apa yang terjadi jika bagian volumes: pada layanan PostgreSQL dihapus, kemudian container dihentikan menggunakan docker compose down -v?

    Jawaban: Jika bagian volumes: dihapus dari konfigurasi, data PostgreSQL akan disimpan di dalam container itu sendiri (bukan di volume terpisah). Kalau container dihentikan dengan perintah docker compose down -v, flag -v akan menghapus semua volume yang terdaftar. Akibatnya, seluruh data basis data akan hilang permanen, termasuk semua tabel, user, password, dan data yang sudah dimasukkan. Container yang baru dibuat nanti akan benar-benar kosong seperti instalasi baru.

    2. Mengapa pemetaan port ditulis "5432:5432" dan bukan cukup satu angka? Apa yang harus diubah apabila komputer sudah memiliki PostgreSQL lain yang menggunakan port 5432?

    Jawaban: Penulisan "5432:5432" terdiri dari dua angka yang punya arti yang berbeda:
    Angka kiri (5432) adalah port di komputer/laptop kita (host)
    Angka kanan (5432) adalah port di dalam container Docker
    Jadi formatnya adalah "host_port:container_port". Kita butuh dua angka karena port di komputer kita bisa berbeda dengan port di dalam container.
    Jika komputer sudah memiliki PostgreSQL lain yang menggunakan port 5432, cukup ubah angka sebelah kiri saja. Misalnya menjadi "5433:5432". Artinya, PostgreSQL di container tetap berjalan di port 5432 (internal), tapi mengaksesnya melalui port 5433 di laptop.

    3. Apa fungsi blok healthcheck? Mengapa healthcheck penting ketika terdapat layanan lain yang bergantung pada basis data?

    Jawaban: Fungsi blok healthcheck adalah untuk memastikan bahwa PostgreSQL benar-benar siap menerima koneksi, bukan sekadar container-nya sudah berjalan. Perintah pg_isready -U msbd akan terus memeriksa apakah database sudah responsif.
    Healthcheck penting karena ada perbedaan antara "container berjalan" dengan "database siap". Container bisa saja sudah running, tapi PostgreSQL masih butuh waktu untuk loading dan initialization. Jika ada layanan lain (seperti aplikasi web atau API) yang mencoba terhubung ke database sebelum database benar-benar siap, maka koneksi akan gagal dan menyebabkan error. Dengan healthcheck, Docker akan menunggu sampai database benar-benar healthy sebelum mengizinkan layanan lain untuk menggunakannya.

    4. Menyimpan password langsung di dalam docker-compose.yml merupakan praktik yang kurang baik. Sebutkan satu cara yang lebih aman dan jelaskan mengapa hal tersebut penting ketika berkas masuk ke repositori Git.

    Jawaban: Cara yang lebih aman adalah dengan menggunakan file .env untuk menyimpan password dan kredensial sensitif, lalu memanggilnya di docker-compose.yml menggunakan variabel environment.
    Kemudian, file .env wajib dimasukkan ke dalam .gitignore agar tidak ikut ter-upload ke repositori Git.
    Hal ini penting karena repositori Git (terutama yang public atau yang dibagikan ke tim) bisa diakses oleh banyak orang. Jika password tersimpan langsung di docker-compose.yml yang ter-commit ke Git, maka siapa saja yang memiliki akses ke repositori tersebut bisa melihat password database. Ini sangat berisiko untuk keamanan data. Dengan menggunakan file .env yang di-ignore oleh Git, password tetap aman di komputer lokal dan tidak tersebar ke repositori.

G. Perbandingan penggunaan psql dan DBeaver
    1. Satu aktivitas yang menurut Anda lebih cepat dilakukan menggunakan psql.
    
    Jawaban: Melihat daftar database yang ada dengan perintah \l lebih cepat di psql karena cukup ketik satu perintah dan langsung muncul hasilnya, tanpa perlu navigasi menu.

    2. Satu aktivitas yang menurut Anda lebih cepat dilakukan menggunakan DBeaver.
    
    Jawaban: Melihat struktur tabel dan relasi antar tabel lebih cepat di DBeaver karena bisa langsung lihat ER Diagram secara visual tanpa perlu ketik query manual.

H. Hasil query V1
pagila=# SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';
 count 
-------
    21
(1 row)

I. Hasil query V2
pagila=# SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS ukuran
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;
     relname      | ukuran  
------------------+---------
 rental           | 2352 kB
 film             | 952 kB
 payment_p2017_04 | 656 kB
 payment_p2017_03 | 568 kB
 film_actor       | 488 kB
 inventory        | 440 kB
 payment_p2017_02 | 296 kB
 payment_p2017_01 | 248 kB
 customer         | 216 kB
 address          | 160 kB
(10 rows)

J. Hasil query V3
pagila=# SELECT f.title, count(*) AS total_sewa
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title
ORDER BY total_sewa DESC
LIMIT 5;
        title        | total_sewa 
---------------------+------------
 BUCKET BROTHERHOOD  |         34
 ROCKETEER MOTHER    |         33
 RIDGEMONT SUBMARINE |         32
 SCALAWAG DUCK       |         32
 FORWARD TEMPLE      |         32
(5 rows)

K. Hasil V4 — EXPLAIN ANALYZE
QUERY PLAN               
 HashAggregate  (cost=713.69..723.69 rows=1000 width=23) (actual time=235.564..236.176 rows=958 loops=1)
   Group Key: f.title
   Batches: 1  Memory Usage: 193kB
   ->  Hash Join  (cost=238.57..633.47 rows=16044 width=15) (actual time=24.623..180.266 rows=16044 loops=1)
         Hash Cond: (i.film_id = f.film_id)
         ->  Hash Join  (cost=128.07..480.67 rows=16044 width=2) (actual time=6.421..135.332 rows=16044 loops=1)
               Hash Cond: (r.inventory_id = i.inventory_id)
               ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=4) (actual time=0.078..28.973 rows=16044 loops=1)
               ->  Hash  (cost=70.81..70.81 rows=4581 width=6) (actual time=6.231..6.235 rows=4581 loops=1)
                     Buckets: 8192  Batches: 1  Memory Usage: 234kB
                     ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.022..2.791 rows=4581 loops=1)
         ->  Hash  (cost=98.00..98.00 rows=1000 width=19) (actual time=18.181..18.182 rows=1000 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 60kB
               ->  Seq Scan on film f  (cost=0.00..98.00 rows=1000 width=19) (actual time=0.054..17.111 rows=1000 loops=1)
 Planning Time: 195.253 ms
 Execution Time: 255.284 ms
(16 rows)

(END)

L. Kalimat: “Yang paling membingungkan dari keluaran ini adalah ...”
Yang paling membingungkan dari keluaran ini adalah adanya banyak baris dengan tulisan 'Seq Scan', 'Hash Join', dan angka-angka seperti 'cost=...' serta 'rows=...'. Saya belum paham apa arti dari angka cost tersebut dan mengapa ada beberapa langkah yang harus dilalui database sebelum menghasilkan jawaban akhir.

M. Tautan repositori Git tim
https://github.com/salsabilasalwarizki/msbd-2026

N. Daftar commit masing-masing anggota
1. Salsabila Salwa Rizki (251402123) (Project Manager) : Konfigurasi Awal & Docker (Langkah 1 & 2)
2. Sina Mahdi Sitanggang (251402008) : Koneksi psql & DBeaver (Langkah 3)
3. Nadia Stevany Br Situmorang (251402073) : Verifikasi Query (Langkah 4)
4. Jesqueen Maria Purba (251402099) : Struktur Folder & Laporan (Langkah 5)




# Tantangan Tambahan - Eksperimen Index

## Waktu Pencarian Sebelum Index
Time: 2411.789 ms (00:02.412)
## Waktu Pencarian Setelah Index
Time: 12.543 ms

## Kesimpulan
Jadi, perbedaannya sangat jauh. Awalnya pas belum ada index, database harus baca satu-satu dari 2 juta baris (Sequential Scan) dan butuh waktu lebih dari 2 detik. Tapi setelah kita bikin index, database langsung tau harus nyari di mana (Index Scan) dan waktunya turun drastis jadi cuma beberapa milidetik. Ini ngebuktiin kalau index itu super penting buat ngebutin query, apalagi kalau datanya udah jutaan. Walaupun proses bikin index-nya sendiri lumayan makan waktu (sekitar 50 detik di percobaan ini), tapi hasilnya sangat worth it banget buat performa pencarian ke depannya.