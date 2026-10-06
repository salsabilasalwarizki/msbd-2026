-- Diminta: memilih satu status untuk index dan satu untuk seq scan.
-- Dipilih: GAGAL untuk index (selektif), SUKSES untuk seq scan (tidak selektif).
-- Alternatif: kombinasi lain; tidak dipilih karena paling jelas.

-- Titik peralihan bukan angka tetap karena:
-- 1. Bergantung pada random_page_cost (SSD vs HDD)
-- 2. Bergantung pada ukuran tabel (cache hit ratio)
-- 3. Bergantung pada selektivitas aktual (bukan hanya persentase)
-- 4. Bergantung pada work_mem (bisa sort di memory atau disk)
-- 5. Bergantung pada parallelism (parallel seq scan lebih cepat)