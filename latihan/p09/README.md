# Latihan Kelompok Pertemuan 9: Menguji Transaksi dan Kendali Konkurensi

Repo ini berisi hasil kerja kelompok kami buat latihan pertemuan 9. Di sini kami nguji gimana PostgreSQL nanganin transaksi, isolation level, MVCC, row lock, deadlock, sampai SERIALIZABLE.

## Cara Menjalankan

Biar bisa ngikutin eksperimennya, kamu butuh dua terminal psql yang jalan barengan.

1. Pastikan Docker udah nyala, terus jalanin:
   ```bash
   docker compose up -d
   ```
2. Buka terminal pertama (kita sebut SESI_A), terus connect ke database:
   ```bash
   docker compose exec -it postgres psql -U postgres -d latihan
   ```
3. Buka terminal kedua (SESI_B), lalu connect pakai perintah yang sama.
4. Jalanin file setup awal dulu di SESI_A buat bikin skema `lab9` dan tabel `rekening`:
   ```bash
   \i q00_setup.sql
   ```
5. Nah, sekarang kamu bisa mulai ngikutin langkah-langkah di file `q01_q32_transaksi.sql` atau baca penjelasan lengkapnya di `laporan.md`.

## Struktur Folder

```
latihan/p09/
├── README.md                 # File ini
├── laporan.md                # Laporan lengkap dengan analisis
├── q00_setup.sql             # Setup awal skema dan tabel
├── q01_q32_transaksi.sql     # Semua skrip SQL dari Q1 sampai Q32
└── bukti/                    # Dokumentasi hasil eksperimen
    ├── isolation-level.md    # Bukti uji isolation level
    ├── deadlock.md           # Bukti uji lock dan deadlock
    ├── serializable.md       # Bukti uji SKIP LOCKED, NOWAIT, SERIALIZABLE
    └── hasil-sesi.txt        # Log mentah hasil copy-paste dari terminal
```

## Anggota Kelompok

| Nama | NIM | Kontribusi |
|------|-----|------------|
| Salsabila Salwa Rizki | 251402123 | Q1-Q5, setup awal, dan refleksi batas transaksi |
| Nadia Stevany Br Situmorang | 251402073 | Q6-Q11, uji isolation level dan anomali |
| Sina Mahdi Sitanggang | 251402008 | Q12-Q23, MVCC, row lock, dan deadlock |
| Jesqueen Maria Purba | 251402099 | Q24-Q32, SERIALIZABLE, retry logic, dan analisis akhir |
