-- Diminta: memeriksa attstorage pada pg_attribute untuk identifikasi kolom TOAST.
-- Dipilih: query ke pg_attribute dengan join pg_class.
-- Alternatif: pg_column_size per kolom; tidak dipilih karena kurang efisien.

SELECT
  a.attname AS kolom,
  t.typname AS tipe,
  a.attstorage AS storage,
  CASE a.attstorage
    WHEN 'p' THEN 'plain (tidak di-TOAST)'
    WHEN 'e' THEN 'external (selalu di-TOAST)'
    WHEN 'm' THEN 'main (bisa di-TOAST)'
    WHEN 'x' THEN 'extended (bisa di-TOAST, kompresi)'
  END AS keterangan
FROM pg_attribute a
JOIN pg_class c ON a.attrelid = c.oid
JOIN pg_type t ON a.atttypid = t.oid
WHERE c.relname = 'event_log'
  AND c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'lab6')
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY a.attnum;

-- Kolom dengan storage 'x' atau 'e' akan di-TOAST jika nilai > 2KB
-- Akibatnya pada SELECT *: PostgreSQL harus fetch dari TOAST table, memperlambat query