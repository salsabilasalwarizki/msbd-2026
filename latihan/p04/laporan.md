# Laporan Latihan Kelompok Pertemuan 4

## Identitas Kelompok

| Nama | NIM | Kontribusi |
|------|-----|------------|
| Salsabila Salwa Rizki | 251402123 | Q1-Q4, Refleksi A, setup q00 |
| Nadia Stevany Br Situmorang | 251402073 | Q5-Q8, Refleksi B |
| Sina Mahdi Sitanggang | 251402008 | Q9-Q13, Refleksi C |
| Jesqueen Maria Purba | 251402099 | Q14-Q21, Refleksi D-E |

---

## Refleksi A-E

### Refleksi A: View sebagai Fasad

**A1: Dua Keuntungan View sebagai Fasad**

1. **Keamanan**: Aplikasi hanya melihat kolom yang diperlukan, kolom sensitif bisa disembunyikan.
2. **Kestabilan API**: Struktur tabel dasar bisa berubah tanpa mengganggu aplikasi, asalkan view tetap sama.

**A2: Dua Kerugian View sebagai Fasad**

1. **Performa**: View kompleks (terutama dengan JOIN dan agregasi) bisa lambat kalau tidak dioptimasi.
2. **Kompleksitas debugging**: Error di view lebih sulit dilacak karena ada lapisan abstraksi tambahan.

**A3: Keadaan yang Mempersulit Tim**

Berdasarkan Q2, ketika view punya WHERE clause tapi tanpa CHECK OPTION, INSERT lewat view bisa sukses tapi datanya "menghilang" dari view. Ini bikin tim bingung karena data seolah-olah hilang padahal sebenarnya ada di tabel dasar. Maka dari itu, view yang dipakai untuk write operation harus pakai WITH CHECK OPTION.

---