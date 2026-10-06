-- Diminta: menyebutkan satu angka sebagai dasar keputusan untuk setiap index.
-- Dipilih: idx_scan, ukuran, atau persentase penghematan.
-- Alternatif: rekomendasi tanpa angka; tidak dipilih karena diminta berbasis data.

-- Contoh format rekomendasi:
-- 1. ev_benar_idx: DIPERTAHANKAN - idx_scan = 150, ukuran = 45 MB
-- 2. ev_salah_idx: DIHAPUS - idx_scan = 0, ukuran = 45 MB (tidak pernah dipakai)
-- 3. ev_gagal_idx: DIPERTAHANKAN - ukuran 80% lebih kecil dari index polos
-- 4. ev_cover_idx: DIGABUNG dengan ev_benar_idx - kolom overlap 100%

-- Setiap keputusan harus didukung satu angka pengukuran
