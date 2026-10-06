-- Diminta: menguji rentang 7 hari dengan BRIN dan B-Tree.
-- Dipilih: query range scan dengan kedua index.
-- Alternatif: rentang lebih besar/kecil; tidak dipilih karena diminta 7 hari.

\timing on
SET max_parallel_workers_per_gather = 0;

-- Dengan B-Tree (default, karena lebih selektif)
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, terjadi_pada
FROM lab6.event_log
WHERE terjadi_pada BETWEEN timestamptz '2024-06-01 00:00+07'
                        AND timestamptz '2024-06-08 00:00+07';

-- Paksa pakai BRIN (disable B-Tree)
SET enable_indexscan = off;
SET enable_bitmapscan = off;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, terjadi_pada
FROM lab6.event_log
WHERE terjadi_pada BETWEEN timestamptz '2024-06-01 00:00+07'
                        AND timestamptz '2024-06-08 00:00+07';

RESET enable_indexscan;
RESET enable_bitmapscan;

\timing off