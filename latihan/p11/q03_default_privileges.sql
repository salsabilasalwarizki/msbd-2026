-- Diminta: mengamati hak akses bawaan pada tabel baru yang dibuat oleh peran berbeda.
-- Dipilih: membuat tabel sebagai postgres (dan sebagai skema_owner), lalu memeriksa hak SELECT app_laporan via has_table_privilege.
-- Alternatif: GRANT manual setiap kali membuat tabel baru; tidak dipilih karena rawan terlupa.
-- Dijalankan sebagai: postgres, dengan satu bagian SET ROLE skema_owner.

-- (a) Dibuat oleh postgres. Harapkan: via_postgres = f
CREATE TABLE lab11.catatan_postgres (id int);
SELECT has_table_privilege('app_laporan','lab11.catatan_postgres','SELECT') AS via_postgres;
DROP TABLE lab11.catatan_postgres;

-- (b) Dibuat oleh skema_owner. Setup memasang ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner. Harapkan: via_owner = t
SET ROLE skema_owner;
CREATE TABLE lab11.catatan_owner (id int);
RESET ROLE;
SELECT has_table_privilege('app_laporan','lab11.catatan_owner','SELECT') AS via_owner;
DROP TABLE lab11.catatan_owner;

-- Perintah yang seharusnya dijalankan untuk peran pembuat objek (postgres), agar (a) juga bernilai t:
-- ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11 GRANT SELECT ON TABLES TO app_read;
