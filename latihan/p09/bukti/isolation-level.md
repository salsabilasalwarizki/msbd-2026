# Bukti Eksperimen Isolation Level

## Pendahuluan
Kelompok kami melakukan serangkaian eksperimen untuk menguji berbagai isolation level di PostgreSQL. Kami pakai dua terminal terpisah (SESI_A dan SESI_B) yang terhubung ke database `latihan` dengan skema `lab9`. Tujuannya adalah buat membuktikan secara langsung anomali konkurensi seperti non-repeatable read, phantom read, dirty read, dan lost update.

## Eksperimen 1: Non-Repeatable Read (Q6)

### Skenario
Kami mulai dengan isolation level default PostgreSQL yaitu READ COMMITTED. SESI_A buka transaksi dan baca saldo rekening 1, lalu SESI_B update saldo rekening tersebut dan commit. Terus SESI_A baca saldo yang sama lagi.

### Hasil yang Kami Amati
- **SESI_A (SELECT pertama):** Saldo = 890.000
- **SESI_B:** Update saldo jadi 840.000, lalu COMMIT
- **SESI_A (SELECT kedua):** Saldo = 840.000

### Analisis
Nilai saldo berubah dari 890.000 jadi 840.000 dalam satu transaksi yang sama. Ini yang disebut non-repeatable read. Maka, READ COMMITTED tidak bisa menjamin konsistensi pembacaan dalam satu transaksi karena setiap statement ambil snapshot baru.

## Eksperimen 2: Perbandingan dengan REPEATABLE READ (Q7)

### Skenario
Kami ulang skenario Q6 tapi pakai REPEATABLE READ di SESI_A. SESI_A baca saldo, SESI_B update dan commit, terus SESI_A baca lagi.

### Hasil yang Kami Amati
- **SESI_A (SELECT pertama):** Saldo = 840.000
- **SESI_B:** Update saldo jadi 810.000, lalu COMMIT
- **SESI_A (SELECT kedua):** Saldo = 840.000 (TIDAK BERUBAH!)

### Analisis
Dengan REPEATABLE READ, nilai saldo tetap 840.000 meskipun SESI_B sudah commit perubahan. Ini karena REPEATABLE READ pakai snapshot yang sama untuk seluruh transaksi. Maka, REPEATABLE READ berhasil mencegah non-repeatable read.

## Eksperimen 3: Phantom Read (Q8)

### Skenario
Kami buat tabel `transaksi_log` dengan beberapa baris. SESI_A hitung jumlah transaksi untuk rekening 1, SESI_B insert baris baru dan commit, terus SESI_A hitung lagi.

### Hasil READ COMMITTED
- **SESI_A (COUNT pertama):** 2 baris
- **SESI_B:** Insert 1 baris baru, COMMIT
- **SESI_A (COUNT kedua):** 3 baris (BERUBAH!)

### Hasil REPEATABLE READ
- **SESI_A (COUNT pertama):** 3 baris
- **SESI_B:** Insert 1 baris baru, COMMIT
- **SESI_A (COUNT kedua):** 3 baris (TIDAK BERUBAH!)

### Analisis
Phantom read terjadi di READ COMMITTED karena baris baru yang di-insert SESI_B langsung kelihatan di SESI_A. Tapi di REPEATABLE READ, snapshot diambil di awal transaksi jadi baris baru tidak kelihatan. Lalu, kami simpulkan REPEATABLE READ juga mencegah phantom read.

## Eksperimen 4: Dirty Read (Q9)

### Skenario
Kami coba buktikan apakah PostgreSQL mengizinkan dirty read. SESI_A update saldo tanpa commit, terus SESI_B coba baca dengan isolation level READ UNCOMMITTED.

### Hasil yang Kami Amati
- **SESI_A:** Update saldo jadi 900.000 (BELUM COMMIT)
- **SESI_B (READ UNCOMMITTED):** Baca saldo = 1.000.000 (nilai LAMA!)

### Analisis
Meskipun SESI_B pakai READ UNCOMMITTED, PostgreSQL tetap tampilkan nilai lama (1.000.000), bukan nilai yang belum di-commit (900.000). Maka, PostgreSQL tidak mengizinkan dirty read sama sekali karena selalu pakai MVCC. Ini berbeda sama database lain kayak Oracle yang benar-benar izinkan dirty read di level ini.

## Eksperimen 5: Lost Update (Q10)

### Skenario
Kedua sesi baca saldo yang sama (840.000), masing-masing hitung nilai baru di aplikasi, terus tulis balik nilai tetap tersebut.

### Hasil yang Kami Amati
- **SESI_A:** Baca 840.000, hitung 840.000 - 50.000 = 790.000, UPDATE saldo = 790.000, COMMIT
- **SESI_B:** Baca 840.000, hitung 840.000 - 30.000 = 810.000, UPDATE saldo = 810.000, COMMIT
- **Hasil akhir:** Saldo = 810.000

### Analisis
Update dari SESI_A (790.000) hilang tertimpa oleh SESI_B (810.000). Seharusnya saldo akhir = 840.000 - 50.000 - 30.000 = 760.000. Ini yang disebut lost update. Maka, kami belajar bahwa hitung nilai di aplikasi lalu tulis balik itu berbahaya. Solusinya adalah pakai UPDATE atomik (`saldo = saldo - 50000`) atau FOR UPDATE.

## Kesimpulan

Dari lima eksperimen di atas, kami dapat beberapa pelajaran penting:

1. **READ COMMITTED** cocok untuk pembacaan sederhana tapi rentan non-repeatable read dan phantom read.
2. **REPEATABLE READ** lebih aman karena pakai snapshot konsisten, tapi tetap bisa kena write skew (dibuktikan di Q26).
3. **Dirty read** tidak mungkin terjadi di PostgreSQL karena MVCC, meskipun isolation level di-set READ UNCOMMITTED.
4. **Lost update** bisa dicegah dengan UPDATE atomik atau FOR UPDATE, bukan dengan isolation level saja.

Maka, pilihan isolation level harus disesuaikan dengan kebutuhan aplikasi dan risiko anomali yang bisa diterima.