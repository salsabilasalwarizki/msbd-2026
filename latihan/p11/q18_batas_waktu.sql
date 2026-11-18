-- Diminta: memasang statement_timeout pada app_portal dan menjelaskan bagaimana batas waktu membuat percobaan berbasis pg_sleep berisik di log.
-- Dipilih: ALTER ROLE app_portal SET statement_timeout = '5s'.
-- Alternatif: membiarkan timeout tak terbatas; tidak dipilih karena query tertahan dan menghabiskan koneksi.
-- Catatan: ALTER ROLE ... SET hanya berlaku untuk sesi BARU. Uji dilakukan dengan LOGIN sebagai app_portal, bukan SET ROLE dari postgres.
-- Penundaan hanya dijalankan di kontainer lab11 sendiri.

-- 1) Dijalankan postgres:
ALTER ROLE app_portal SET statement_timeout = '5s';

-- 2) Uji (terminal terpisah, login langsung sebagai app_portal ke kontainer lab11-db sendiri):
--   psql -U app_portal -d msbd -c "SHOW statement_timeout;"    -- harapkan 5s
--   psql -U app_portal -d msbd -c "SELECT pg_sleep(10);"       -- harapkan galat: canceling statement due to statement timeout
--
-- 3) Di log server (docker logs lab11-db) setiap pembatalan tercatat sebagai ERROR dengan SQLSTATE 57014 (query_canceled).
--    Itulah sebabnya percobaan berbasis pg_sleep menjadi berisik: setiap percobaan yang melewati batas meninggalkan jejak.
