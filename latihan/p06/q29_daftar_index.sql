-- Diminta: mendaftar seluruh index lab6 dengan idx_scan dan ukuran.
-- Dipilih: pg_stat_user_indexes join pg_class untuk ukuran.
-- Alternatif: hanya pg_indexes; tidak dipilih karena tidak ada statistik penggunaan.

SELECT
  s.schemaname,
  s.relname AS tabel,
  s.indexrelname AS index,
  pg_size_pretty(pg_relation_size(s.indexrelid)) AS ukuran,
  s.idx_scan AS jumlah_scan,
  s.idx_tup_read AS baris_dibaca,
  s.idx_tup_fetch AS baris_diambil
FROM pg_stat_user_indexes s
WHERE s.schemaname = 'lab6'
ORDER BY s.idx_scan ASC;

-- Index dengan idx_scan = 0 adalah kandidat untuk dihapus
-- Kecuali: index untuk constraint (PRIMARY KEY, UNIQUE, FOREIGN KEY)
-- Kecuali: index yang baru dibuat dan belum dipakai