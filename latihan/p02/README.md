# msbd-2026 - Latihan 2- Kelompok 9

Domain: Sistem Distribusi Bantuan Kesehatan dan Pendampingan Lansia

## Anggota Kelompok

*   Salsabila Salwa Rizki (251402123) - Project Manager
*   Jesqueen Maria Purba (251402099)
*   Nadia Stevany Br Situmorang (251402073)
*   Sina Mahdi Sitanggang (251402008)

## Cara Menjalankan Docker Compose

1. Pastikan Docker Desktop sudah berjalan di komputer Anda.
2. Buka terminal (PowerShell) di direktori root repositori ini (`msbd-2026`).
3. Jalankan perintah berikut untuk menyalakan seluruh layanan (PostgreSQL, Flyway, MongoDB, Redis):
   powershell
   docker compose up -d
4. Tunggu beberapa saat hingga status container `msbd-pg` (PostgreSQL) berubah menjadi `healthy`. Anda dapat memeriksa statusnya dengan perintah:
   powershell
   docker compose ps
5. Jika database `proyek_dev` belum dibuat, jalankan perintah berikut untuk membuatnya:
   powershell
   docker compose exec postgres psql -U msbd -d postgres -c "CREATE DATABASE proyek_dev;"


## Cara Menjalankan Migration

Migrasi skema basis data dikelola menggunakan Flyway. Pastikan container Docker sudah berjalan sebelum mengeksekusi migrasi.

1. Jalankan perintah berikut untuk menerapkan file migrasi (DDL) ke dalam database `proyek_dev`:
   powershell
   docker compose run --rm flyway migrate
   
2. Untuk melihat riwayat migrasi yang telah berhasil diterapkan, gunakan perintah:
   powershell
   docker compose run --rm flyway info
   

## Cara Menjalankan Seed Data

Seed data digunakan untuk mengisi data awal (DML) ke dalam tabel yang sudah terbentuk. Perintah di bawah ini disesuaikan untuk PowerShell.

1. Pastikan migrasi telah berhasil dijalankan tanpa error.
2. Jalankan perintah berikut untuk memasukkan data seed:
   powershell
   Get-Content latihan/p02/seeds/01_master_data.sql | docker compose exec -T postgres psql -U msbd -d proyek_dev
3. Untuk memastikan data berhasil dimasukkan dan bersifat idempoten (tidak duplikat jika dijalankan berulang), Anda dapat memverifikasi jumlah barisnya:
   powershell
   docker compose exec postgres psql -U msbd -d proyek_dev -c "SELECT count(*) FROM jenis_bantuan;"
   