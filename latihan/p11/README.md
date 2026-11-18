# Latihan Kelompok Pertemuan 11 — Keamanan, Kontrol Akses, dan Kepatuhan Data

Seluruh hasil disimpan di `latihan/p11/`. Percobaan hanya dijalankan pada kontainer lab11 milik sendiri di jaringan internal tertutup.

## Prasyarat
1. Docker dan Docker Compose terpasang.
2. `docker-compose.lab11.yml` dan `sql/lab11_setup.sql` dari modul praktikum (tidak ada di folder ini; jalankan apa adanya).
3. Python 3 dengan `psycopg` (versi 3) di dalam kontainer `lab11-web`: `pip install "psycopg[binary]"`.
4. `pgcrypto` dibuat di basis data `msbd` (dijalankan di Q19; ekstensi bersifat per basis data).

## Menyalakan Kontainer dan Memuat Skema
```bash
mkdir -p ~/msbd-2026/lab11/sql ~/msbd-2026/lab11/app
cd ~/msbd-2026/lab11
docker compose -f docker-compose.lab11.yml up -d
docker cp sql/lab11_setup.sql lab11-db:/sql/lab11_setup.sql
docker exec -i lab11-db psql -U postgres -d msbd -f /sql/lab11_setup.sql
docker network inspect lab11_labnet --format '{{.Internal}}'   # harapkan: true
```

## Urutan Menjalankan Berkas
1. **Setup**: `q00_setup.sql` (angka harus cocok: 3 | 30000 | 4 | 120000), lalu `q00b_peran_dan_kepemilikan.sql` (membuat peran dan memindahkan kepemilikan; tidak ada di setup modul).
2. **Peran dan hak**: `q01` s.d. `q05`.
3. **Row-Level Security**: `q06` s.d. `q11`. Q9 harus dijalankan sebelum Q11 karena Q11 memakai celah dari Q9.
4. **SQL injection**: `q12` s.d. `q18`. Q12–Q16 dijalankan dari kontainer `lab11-web` dengan `rentan.py`. Q18 dijalankan dengan login langsung sebagai `app_portal`.
5. **Enkripsi, hashing, penyamaran**: `q19` s.d. `q24`. Q21 WAJIB dijalankan sebelum Q25 (lihat catatan di Q25).
6. **Audit, retensi, UU PDP**: `q25` s.d. `q29`, lalu `q30_peta_uu_pdp.md`. Q26 dijalankan dengan login langsung sebagai `app_portal`.
7. **Laporan**: `laporan.md`.

## Catatan Penting
- Keluaran yang ditempel ke laporan harus keluaran nyata dari kontainer sendiri. Angka di komentar "harapkan" hanya pembanding.
- Jika keluaran berbeda dari harapan, jangan diubah. Tulis perbedaannya dan penjelasannya.
- Payload percobaan hanya berupa pembacaan (SELECT) dan tidak boleh merusak data penyewa lain. Uji hak yang ditolak memakai `has_table_privilege` bila memungkinkan.