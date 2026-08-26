1. Verifikasi Docker (Salsabila Salwa Rizki [251402123])
Perintah untuk memastikan Docker dan Docker Compose terinstal dengan benar.
docker --version
docker compose version
docker run --rm hello-world

2. Menjalankan Docker Compose (Salsabila Salwa Rizki [251402123])
Perintah untuk membuat folder, menyalakan container, dan memeriksa status layanan.
# Membuat folder dump (Gunakan ini jika di PowerShell: New-Item -ItemType Directory -Force -Path dump)
mkdir -p dump

# Menjalankan container di background
docker compose up -d

# Memeriksa status container (pastikan postgres berstatus healthy)
docker compose ps

# Melihat 20 baris terakhir log postgres
# (Gunakan ini jika di PowerShell: docker compose logs postgres | Select-Object -Last 20)
docker compose logs postgres | tail -20

3. Mengakses PostgreSQL via psql (Nadia Stefany Br Situmorang [251402073])
Perintah untuk masuk ke dalam shell interaktif PostgreSQL dan menjalankan query dasar.
Masuk ke database:
docker compose exec postgres psql -U msbd -d latihan
Perintah di dalam psql (prompt latihan=#):
-- Melihat versi PostgreSQL
SELECT version();

-- Melihat daftar database
\l

-- Melihat daftar tabel
\dt

-- Melihat daftar skema
\dn

-- Melihat daftar user/role
\du

-- Menampilkan direktori penyimpanan data fisik
SHOW data_directory;

-- Menampilkan alokasi memori shared buffer
SHOW shared_buffers;

-- Mengaktifkan timer untuk melihat durasi eksekusi query
\timing on

-- Keluar dari psql
\q

4. Restore Basis Data Pagila dan Verifikasi (Sina Mahdi Sitanggang [251402008])
Perintah untuk membuat database baru, merestore data dari file dump, dan menjalankan query verifikasi.
Perintah di Terminal (Host):
# 1. Membuat database kosong bernama pagila
docker compose exec postgres createdb -U msbd pagila

# 2. Merestore data dari file dump ke database pagila
docker compose exec postgres pg_restore -U msbd -d pagila --no-owner /dump/pagila.dump

# 3. Verifikasi cepat untuk melihat daftar tabel
docker compose exec postgres psql -U msbd -d pagila -c "\dt"

Masuk ke database pagila untuk query lanjutan:
docker compose exec postgres psql -U msbd -d pagila

Query Verifikasi (di dalam psql prompt pagila=#):
-- V1: Menghitung jumlah tabel pada skema public
SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

-- V2: Menampilkan 10 tabel terbesar beserta ukurannya
SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS ukuran
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;

-- V3: Menampilkan 5 film dengan jumlah penyewaan terbanyak
SELECT f.title, count(*) AS total_sewa
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title
ORDER BY total_sewa DESC
LIMIT 5;

-- V4: Melihat rencana eksekusi (EXPLAIN ANALYZE) untuk query di atas
EXPLAIN ANALYZE
SELECT f.title, count(*)
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title;

5. Inisialisasi dan Konfigurasi Git (Jesqueen Maria Purba [251402099])
Perintah untuk menyiapkan repositori Git tim.
# Menginisialisasi repositori Git
git init

# Membuat file .gitignore 
# (Jika di PowerShell, buat file .gitignore secara manual dan isi dengan teks di bawah)
printf 'dump/\n*.dump\n.env\n.DS_Store\n' > .gitignore

# Menambahkan semua file ke staging area
git add .

# Melakukan commit pertama
git commit -m "chore: menyiapkan lingkungan MSBD"

# Mengubah nama branch utama menjadi main
git branch -M main

# Menghubungkan dengan repositori remote (ganti URL dengan URL repositori tim)
git remote add origin <URL repositori tim>

# Mendorong perubahan ke repositori remote
git push -u origin main

Isi File .gitignore
Pastikan file .gitignore berisi baris berikut agar file sensitif tidak ter-upload:
dump/
*.dump
.env
.DS_Store


6. Tambahan
# Membandingkan perbedaan waktu sembelum dan setelah index
CREATE TABLE besar AS
SELECT g AS id,
       md5(g::text) AS nilai
FROM generate_series(1, 2000000) g;

SELECT *
FROM besar
WHERE nilai = '...';

CREATE INDEX ON besar(nilai);

