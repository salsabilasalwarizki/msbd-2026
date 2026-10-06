-- Diminta: menjelaskan kapan penghematan ukuran BRIN sepadan dengan selisih waktu.
-- Dipilih: analisis trade-off ukuran vs performa.
-- Alternatif: tidak ada; ini pertanyaan konseptual.

-- BRIN cocok untuk:
-- 1. Data time-series yang terurut (correlation tinggi)
-- 2. Query range scan pada kolom waktu
-- 3. Tabel sangat besar di mana ukuran index B-Tree jadi masalah
-- 4. Write-heavy workload (BRIN murah untuk di-maintain)

-- BRIN tidak cocok untuk:
-- 1. Data acak (correlation rendah)
-- 2. Query point lookup (WHERE terjadi_pada = exact_value)
-- 3. Tabel kecil (overhead tidak sepadan)