-- Diminta: membandingkan query email = ... dengan lower(email) = ...
-- Dipilih: dua query dengan EXPLAIN ANALYZE.
-- Alternatif: hanya satu query; tidak dipilih karena diminta perbandingan.

\timing on
SET max_parallel_workers_per_gather = 0;

-- Query tanpa expression (tidak pakai index)
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, email
FROM lab6.event_log
WHERE email = 'user4211@contoh.ac.id';

-- Query dengan expression (pakai index ev_email_lower_idx)
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, email
FROM lab6.event_log
WHERE lower(email) = 'user4211@contoh.ac.id';

\timing off