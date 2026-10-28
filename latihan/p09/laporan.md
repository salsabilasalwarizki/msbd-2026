# Laporan Latihan Kelompok Pertemuan 9
## Menguji Transaksi dan Kendali Konkurensi

## Kondisi Uji
- PostgreSQL: 17.11 (via Docker)
- Alat: Dua terminal psql terpisah (SESI_A dan SESI_B)
- Database: `latihan`, Skema: `lab9`
- Konfigurasi default: `transaction_isolation = read committed`, `deadlock_timeout = 1s`, dan timeout lainnya 0 (unlimited).

---

## Q1-Q5: Setup dan Batas Transaksi

**Q1. Kondisi Awal**
Kami mulai dengan ngecek isi tabel `rekening`. Hasilnya, Ani dan Budi masing-masing punya saldo 1.000.000. Jadi total saldo keseluruhan ada 2.000.000. Ini jadi baseline buat semua eksperimen kami selanjutnya.

**Q2. Visibilitas Antar Sesi**
Di SESI_A, kami jalankan `BEGIN`, lalu update saldo Ani jadi 900.000. Tapi kami belum COMMIT. Terus di SESI_B, kami coba SELECT saldo Ani. Hasilnya, SESI_B masih liat saldo lama (1.000.000). Nah, setelah SESI_A ngetik COMMIT, baru deh SESI_B liat saldonya berubah jadi 900.000. Ini membuktikan isolasi transaksi jalan dengan baik.

**Q3. COMMIT vs ROLLBACK**
Kami coba update saldo Ani lagi di SESI_A, lalu kami ROLLBACK. Pas kami cek lagi, saldonya balik lagi ke nilai sebelum update. Jadi, ROLLBACK itu bener-bener ngebatalin semua perubahan yang terjadi di dalam transaksi tersebut.

**Q4. SAVEPOINT**
Kami bikin transaksi dengan dua update, dan di tengahnya kami taruh `SAVEPOINT sp1`. Update pertama ngurangin 10.000, update kedua ngurangin 20.000. Terus kami jalankan `ROLLBACK TO SAVEPOINT sp1`. Hasilnya, update kedua dibatalin, tapi update pertama tetap tersimpan pas kami COMMIT. Ini berguna banget buat ngebatalin sebagian transaksi aja.

**Q5. Atomicity dan Consistency**
Kami coba update saldo Ani dengan ngurangin 2.000.000 (padahal saldonya cuma 900.000). PostgreSQL langsung nolak dengan error `violates check constraint "rekening_saldo_check"`. Transaksinya otomatis gagal karena aturan `saldo >= 0` dilanggar. Ini bukti kalau constraint CHECK itu ngejaga consistency data di level database.

---

