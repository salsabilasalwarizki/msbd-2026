-- Diminta: menyusun rekomendasi final index.
-- Dipilih: analisis berdasarkan Q1-Q29.
-- Alternatif: rekomendasi generik; tidak dipilih karena harus berbasis data.

-- Lihat semua index lab6
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'lab6'
ORDER BY indexname;

-- Rekomendasi:
-- 1. Dipertahankan: index dengan idx_scan > 0 dan ukuran wajar
-- 2. Dihapus: index dengan idx_scan = 0 (kecuali constraint)
-- 3. Digabung: index dengan kolom overlap (misal: ev_benar_idx dan ev_cover_idx)

-- Contoh: jika ev_benar_idx (customer_id, terjadi_pada) dan ev_cover_idx (customer_id INCLUDE terjadi_pada, jumlah)
-- bisa digabung menjadi: (customer_id, terjadi_pada) INCLUDE (jumlah)