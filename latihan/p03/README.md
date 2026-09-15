# Latihan Pertemuan 3 - SQL Lanjutan I

## Tujuan
Latihan ini tujuannya buat ngerjain 20 query SQL lanjutan plus 1 laporan analitik terpadu pakai basis data Pagila. Jadi kita bakal belajar subquery, CTE, recursive CTE, window function, agregasi lanjut, sama JSONB.

## Prasyarat
Sebelum mulai, pastiin dulu:
- Docker Desktop udah jalan
- PostgreSQL 17 terinstall (cek via Docker)
- Basis data Pagila udah terisi datanya

Kalau belum ada Pagila, bisa setup dulu pakai perintah ini:

```powershell
# Buat database Pagila
docker compose exec postgres psql -U msbd -d postgres -c "CREATE DATABASE pagila;"

# Restore schema
Get-Content dump/pagila-schema.sql | docker compose exec -T postgres psql -U msbd -d pagila

# Restore data
Get-Content dump/pagila-data.sql | docker compose exec -T postgres psql -U msbd -d pagila

# Verifikasi
docker compose exec postgres psql -U msbd -d pagila -c "SELECT count(*) AS film FROM film;"
docker compose exec postgres psql -U msbd -d pagila -c "SELECT count(*) AS payment FROM payment;"
```

## Menjalankan Setup

Sebelum masuk ke soal, kita perlu setup tabel `pegawai` dan `notifikasi` dulu. Tabel ini bakal dipakai di Q6-Q9 dan Q19-Q20.

```powershell
Get-Content latihan/p03/q00_setup.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

Kalau berhasil, nanti bakal muncul pesan `DROP TABLE`, `CREATE TABLE`, dan `INSERT` tanpa error.

## Urutan Menjalankan Jawaban

### Q1-Q5: Subquery
```powershell
Get-Content latihan/p03/q01_tarif_di_atas_rata.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q02_kategori_lebih_60.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q03_pelanggan_pembayaran_besar.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q04_film_tidak_pernah_disewa.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q05_tarif_tertinggi_per_toko.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q6-Q9: CTE dan Recursive CTE
```powershell
Get-Content latihan/p03/q06_cte_kategori.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q07_hierarki_pegawai.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q08_bawahan_bima.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q09_rekursi_tahan_siklus.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q10-Q15: Window Function
```powershell
Get-Content latihan/p03/q10_tiga_peringkat_tarif.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q11_tiga_film_tertinggi.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q12_perubahan_omzet_harian.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q13_kumulatif_rerata_7hari.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q14_rows_vs_range.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q15_riwayat_pembayaran_pelanggan.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q16-Q18: Agregasi Lanjutan
```powershell
Get-Content latihan/p03/q16_rollup_kategori_rating.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q17_filter_per_kategori.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q18_rekonsiliasi_inventory_rental.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### Q19-Q20: JSONB
```powershell
Get-Content latihan/p03/q19_notifikasi_lunas.sql | docker compose exec -T postgres psql -U msbd -d pagila
Get-Content latihan/p03/q20_bentangkan_kontak.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

### R1: Laporan Pendapatan Bulanan
```powershell
Get-Content latihan/p03/r1_laporan_bulanan.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

## Catatan Q9

Nah ini yang perlu diperhatikan. Q9 itu ada bagian yang mengubah data sementara di tabel `pegawai` buat nguji siklus. Jadi ada perintah `UPDATE pegawai SET atasan_id = 6 WHERE pegawai_id = 1;` yang bikin siklus di hierarki.

Kalau udah selesai, jangan lupa pulihkan datanya pakai perintah ini:

```sql
UPDATE pegawai SET atasan_id = NULL WHERE pegawai_id = 1;
```

Atau bisa juga langsung jalankan ulang `q00_setup.sql` buat reset tabel pegawai ke kondisi awal:

```powershell
Get-Content latihan/p03/q00_setup.sql | docker compose exec -T postgres psql -U msbd -d pagila
```

Kalau lupa pulihkan dan recursive CTE-nya jalan tanpa pengaman, bisa-bisa query-nya jalan terus dan makan memori. Jadi siapin `Ctrl-C` buat emergency stop.

## Anggota Kelompok

| Nama | NIM |
|------|-----|
| Salsabila Salwa Rizki | 251402123 |
| Nadia Stevany Br Situmorang | 251402073 |
| Jesqueen Maria Purba | 251402099 |
| Sina Mahdi Sitanggang | 251402008 |

## Pembagian Tugas

- Salwa: Q1-Q5 (Subquery), Refleksi A, setup q00
- Nadia: Q6-Q9 (CTE & Recursive CTE), Refleksi B
- Sina: Q10-Q15 (Window Function), Refleksi C
- Jesqueen: Q16-Q20 (Agregasi & JSONB), R1, Refleksi D-E