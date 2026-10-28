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

## Q6-Q11: Isolation Level dan Anomali

**Q6. Non-repeatable Read (READ COMMITTED)**
SESI_A buka transaksi READ COMMITTED dan baca saldo Ani (890.000). SESI_B update saldo Ani jadi 840.000 dan COMMIT. Pas SESI_A baca saldo Ani lagi, angkanya udah berubah jadi 840.000. Jadi, di READ COMMITTED, pembacaan yang sama dalam satu transaksi bisa ngasih hasil yang beda.

**Q7. Perbandingan dengan REPEATABLE READ**
Kami ulang skenario tadi tapi SESI_A pakai REPEATABLE READ. Pas SESI_B update dan COMMIT, SESI_A baca saldo Ani lagi, angkanya tetap 840.000 (tidak berubah). Maka, REPEATABLE READ itu ngejaga snapshot data tetap konsisten selama transaksi berjalan.

**Q8. Phantom Read**
Kami bikin tabel `transaksi_log`. SESI_A hitung jumlah transaksi (ada 2). SESI_B insert 1 baris baru dan COMMIT. Pas SESI_A (READ COMMITTED) hitung lagi, jumlahnya jadi 3 (phantom read terjadi). Tapi pas kami ulang pakai REPEATABLE READ, jumlahnya tetap 3 (tidak ada phantom read).

**Q9. Dirty Read**
SESI_A update saldo Budi tapi belum COMMIT. SESI_B kita set ke READ UNCOMMITTED dan coba baca saldo Budi. Hasilnya, SESI_B tetep liat nilai lama. Jadi, PostgreSQL itu gak ngizinin dirty read sama sekali, level serendah apapun isolation level-nya, karena dia selalu pakai MVCC.

**Q10. Lost Update**
SESI_A dan SESI_B sama-sama baca saldo Ani (840.000). SESI_A hitung manual 840.000 - 50.000 = 790.000, lalu di-UPDATE dan COMMIT. SESI_B hitung manual 840.000 - 30.000 = 810.000, lalu di-UPDATE dan COMMIT. Hasil akhirnya saldo jadi 810.000. Update dari SESI_A hilang tertimpa. Ini yang namanya lost update.

**Q11. Tabel Ringkasan Anomali**

| Anomali | Urutan Kejadian | Isolation Level | Hasil | Mitigasi |
|---------|-----------------|-----------------|-------|----------|
| Non-repeatable read | A:SELECT -> B:UPDATE -> A:SELECT | READ COMMITTED | Nilai berubah | REPEATABLE READ |
| Phantom read | A:COUNT -> B:INSERT -> A:COUNT | READ COMMITTED | Jumlah berubah | REPEATABLE READ |
| Dirty read | A:UPDATE -> B:READ | READ UNCOMMITTED | Tidak terjadi di PG | MVCC bawaan PG |
| Lost update | A:READ -> B:READ -> A:WRITE -> B:WRITE | READ COMMITTED | Update A hilang | FOR UPDATE / Atomik |

---

## Q12-Q17: Mencegah Lost Update dan Memahami MVCC

**Q12. Pembaruan Atomik**
Kami perbaiki lost update di Q10 dengan pakai `UPDATE ... SET saldo = saldo - 10000`. Karena PostgreSQL ngunci baris pas di-UPDATE, SESI_B otomatis nunggu SESI_A selesai. Jadi perhitungannya berdasarkan nilai terbaru, dan lost update gak terjadi.

**Q13. SELECT ... FOR UPDATE**
SESI_A kunci baris pakai `FOR UPDATE`. Pas SESI_B coba update baris yang sama, terminal SESI_B nunggu (blocking) sampai SESI_A COMMIT. Ini cara aman buat nge-lock baris biar gak diubah sesi lain.

**Q14. Optimistic Locking**
Kami tambah kolom `version_no`. SESI_A dan SESI_B sama-sama baca `version_no = 1`. SESI_A update dan ubah `version_no` jadi 2. Pas SESI_B coba update dengan syarat `version_no = 1`, update-nya gagal (0 rows affected). Aplikasi jadi tau kalau datanya udah diubah orang lain.

**Q15. MVCC**
SESI_A baca saldo, lalu SESI_B update saldo tapi belum COMMIT. Pas SESI_A baca lagi, nilainya tetap yang lama. Ini bukti MVCC: pembaca liat snapshot data tanpa perlu nunggu penulis selesai.

**Q16. xmin dan xmax**
Kami cek kolom `xmin` dan `xmax`. `xmin` itu ID transaksi yang bikin baris itu, `xmax` itu ID transaksi yang ngapus baris itu (0 kalau belum diapus). Ini metadata internal buat MVCC, bukan data bisnis.

**Q17. Manfaat MVCC dan VACUUM**
MVCC bikin pembaca gak nge-blok penulis, dan sebaliknya. Tapi karena MVCC nyimpen versi lama dari baris yang di-update, tabel bisa jadi bengkak. Makanya butuh VACUUM buat bersihin versi lama yang udah gak kepake.

---

## Q18-Q23: Row Lock, Deadlock, dan Antrean Lock

**Q18. Perbandingan Lock Mode**
Kami coba `FOR UPDATE`, `FOR NO KEY UPDATE`, `FOR SHARE`, dan `FOR KEY SHARE`. `FOR UPDATE` itu yang paling ketat dan nge-blok semua lock lain. `FOR KEY SHARE` paling longgar, biasanya buat cek foreign key.

**Q19. Lock Waiting**
SESI_A lock baris, SESI_B coba lock baris yang sama. SESI_B cuma nunggu aja, gak error. Pas SESI_A COMMIT, SESI_B langsung dapet lock. Ini namanya antrean lock, bukan deadlock.

**Q20. Deadlock**
SESI_A lock rekening 1, SESI_B lock rekening 2. Terus SESI_A minta lock rekening 2, dan SESI_B minta lock rekening 1. PostgreSQL langsung deteksi ini deadlock dan nge-kill SESI_B dengan error `SQLSTATE 40P01`.

**Q21. Mencegah Deadlock**
Kami ulang skenario tadi, tapi kedua sesi sekarang lock dari ID terkecil ke terbesar (1 lalu 2). Hasilnya, gak ada deadlock. SESI_B cuma nunggu SESI_A selesai. Urutan lock yang konsisten itu kunci buat ngehindarin deadlock.

**Q22. Deadlock vs Antrean Lock Panjang**
Deadlock itu circular wait (saling nunggu) dan pasti ada yang di-kill. Antrean lock panjang itu linear wait (antri biasa), gak ada error, tapi bisa bikin aplikasi lemot kalau gak dikasih timeout.

**Q23. Macam-macam Timeout**
`lock_timeout` buat batasin nunggu lock. `statement_timeout` buat batasin lama query jalan. `idle_in_transaction_session_timeout` buat nge-kill sesi yang lupa COMMIT/ROLLBACK. `deadlock_timeout` itu settingan server buat nentuin kapan PostgreSQL mulai ngecek deadlock.

---

## Q24-Q29: SKIP LOCKED dan SERIALIZABLE

**Q24. SKIP LOCKED**
Kami bikin tabel antrean pekerjaan. SESI_A lock pekerjaan 1. SESI_B pakai `FOR UPDATE SKIP LOCKED` dan langsung dapet pekerjaan 2 tanpa nunggu. Ini fitur yang keren banget buat bikin sistem worker/queue paralel.

**Q25. NOWAIT**
SESI_A lock pekerjaan 2. SESI_B coba lock pekerjaan 2 pakai `FOR UPDATE NOWAIT`. Langsung error `SQLSTATE 55P03` tanpa nunggu sama sekali. Cocok buat aplikasi yang mau fail-fast.

**Q26. Write Skew**
Kami bikin tabel `dokter_jaga` (Ani dan Budi aktif). Aturan bisnisnya: minimal 1 dokter harus aktif. Di REPEATABLE READ, SESI_A nonaktifkan Ani, SESI_B nonaktifkan Budi. Keduanya COMMIT sukses. Tapi hasilnya, gak ada dokter yang aktif. Aturan bisnisnya dilanggar! Ini namanya write skew.

**Q27. SERIALIZABLE**
Kami ulang skenario Q26 pakai SERIALIZABLE. Pas SESI_B mau COMMIT, PostgreSQL nolak dengan error `SQLSTATE 40001` (serialization failure). Aturan bisnisnya aman karena salah satu transaksi dibatalin.

**Q28. SIReadLock**
SERIALIZABLE di PostgreSQL gak ngunci baris satu-satu kayak `FOR UPDATE`. Dia pakai predicate locking (ngunci kondisi WHERE-nya). Makanya dia bisa deteksi write skew tanpa harus nge-lock semua baris.

**Q29. Retry Logic**
Karena SERIALIZABLE bisa ngelempar error 40001, aplikasi wajib punya retry logic. Kami susun pseudocode pakai exponential backoff dan jitter. Dan yang paling penting, operasi eksternal kayak kirim email itu harus dilakukan SETELAH COMMIT sukses, biar gak terjadi side effect kalau transaksi di-rollback.

---

## Q30-Q32: Analisis dan Rekomendasi

**Q30. Matriks Anomali**
(Dilihat di tabel Q11 dan bukti eksperimen. Dirty read dicegah MVCC, Non-repeatable & Phantom dicegah REPEATABLE READ, Lost update dicegah FOR UPDATE/Atomik, Write skew dicegah SERIALIZABLE).

**Q31. Rekomendasi Isolation Level**
- Buat pembacaan sederhana (dashboard): **READ COMMITTED** aja udah cukup, performanya paling ngebut.
- Buat laporan yang butuh data konsisten: **REPEATABLE READ** biar angkanya gak berubah-ubah di tengah jalan.
- Buat transaksi kritis (transfer uang, booking): **SERIALIZABLE** aja, biar aman dari write skew, tapi jangan lupa siapin retry logic.

**Q32. Tiga Pelajaran Utama**
1. **Hitung di aplikasi itu bahaya.** (Bukti Q10: Lost update terjadi karena kami hitung manual di aplikasi lalu di-WRITE balik. Solusinya: pakai UPDATE atomik).
2. **REPEATABLE READ itu gak sempurna.** (Bukti Q26: Write skew tetap bisa terjadi dan nge-langgar aturan bisnis. Solusinya: pakai SERIALIZABLE).
3. **SERIALIZABLE itu butuh persiapan.** (Bukti Q27: Transaksi bisa gagal di COMMIT dengan error 40001. Solusinya: wajib implementasi retry logic dengan backoff).

---

## Penggunaan AI dan Verifikasi

Kelompok kami pakai bantuan AI buat nyusun struktur laporan, bikin pseudocode retry logic, dan ngejelasin konsep kayak MVCC sama predicate locking biar lebih gampang dipahami. Tapi semua skrip SQL dijalankan manual pakai dua terminal, dan hasil yang ada di laporan ini berdasarkan output yang kami dapat.

## Tautan Merge Request

