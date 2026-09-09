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
