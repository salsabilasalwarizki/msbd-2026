-- Diminta: menguji pendelegasian hak dengan WITH GRANT OPTION dan pencabutannya dengan dan tanpa CASCADE.
-- Dipilih: REVOKE GRANT OPTION tanpa CASCADE (amati galat), lalu dengan CASCADE, lalu buktikan app_write tetap bisa membaca.
-- Alternatif: REVOKE SELECT ... CASCADE; tidak dipilih karena mencabut SELECT app_write seluruhnya.
-- Dijalankan sebagai: postgres kecuali disebut. Baris galat dijalankan satu per satu agar galatnya tercatat.

GRANT SELECT ON lab11.transaksi TO app_write WITH GRANT OPTION;
SET ROLE app_write;
GRANT SELECT ON lab11.transaksi TO app_analitik;   -- didelegasikan oleh app_write
RESET ROLE;

-- Langkah 1 (jalankan sendiri, salin galatnya): harapkan ERROR dependent privileges exist
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write;

-- Langkah 2 (dengan CASCADE): mencabut juga hak app_analitik yang diturunkan dari app_write
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write CASCADE;

-- Verifikasi: harapkan analitik = f, app_write = t
SELECT has_table_privilege('app_analitik','lab11.transaksi','SELECT') AS analitik,
       has_table_privilege('app_write','lab11.transaksi','SELECT')    AS app_write;

-- Bukti app_write masih bisa membaca (harapkan count = 120000)
SET ROLE app_write;
SELECT count(*) AS dibaca_app_write FROM lab11.transaksi;
RESET ROLE;
