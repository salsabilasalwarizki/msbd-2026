-- Diminta: mengubah random_page_cost dan melihat pergeseran titik transisi.
-- Dipilih: SET random_page_cost = 1.1 (SSD-like), lalu ulangi Q23.
-- Alternatif: nilai lain; tidak dipilih karena 1.1 umum untuk SSD.

-- Default random_page_cost = 4.0 (HDD-like)
SHOW random_page_cost;

-- Ubah ke 1.1 (SSD)
SET random_page_cost = 1.1;

-- Ulangi query Q22
\timing on
SET max_parallel_workers_per_gather = 0;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, status
FROM lab6.event_log
WHERE status = 'SUKSES';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, status
FROM lab6.event_log
WHERE status = 'GAGAL';

\timing off

-- Reset ke default
RESET random_page_cost;

-- Dengan random_page_cost lebih rendah, index scan lebih disukai
-- Titik transisi bergeser ke persentase yang lebih tinggi