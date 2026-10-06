-- Diminta: membuat index status dan membandingkan rencana untuk SUKSES vs GAGAL.
-- Dipilih: B-Tree index pada status.
-- Alternatif: partial index; tidak dipilih karena diminta perbandingan semua status.

CREATE INDEX ev_status_idx ON lab6.event_log (status);

\timing on
SET max_parallel_workers_per_gather = 0;

-- Query untuk status SUKSES (selektivitas rendah, banyak baris)
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, status
FROM lab6.event_log
WHERE status = 'SUKSES';

-- Query untuk status GAGAL (selektivitas tinggi, sedikit baris)
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, status
FROM lab6.event_log
WHERE status = 'GAGAL';

\timing off