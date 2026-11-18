-- Diminta: menguji pencatatan audit dari aksi app_portal dan membuktikan app_portal tidak dapat membaca atau memalsukan jejak audit.
-- Dipilih: app_portal login langsung (bukan SET ROLE) melakukan UPDATE dan DELETE pada baris uji miliknya sendiri; hak diuji lewat has_table_privilege (hanya SELECT).
-- Alternatif: memberi app_portal hak baca jejak audit; tidak dipilih karena pelanggar dapat menghapus jejaknya sendiri.

-- Langkah 0 (postgres): buat baris uji milik penyewa 1 yang tidak punya transaksi
INSERT INTO lab11.pelanggan (id, tenant_id, nama, nik, surel, lahir, kota, saldo)
VALUES (99001, 1, 'Uji Audit', '1234567890123456', 'audit@test.local', '2000-01-01', 'Medan', 0);

-- Langkah 1: login sebagai app_portal (terminal terpisah, kontainer lab11-db sendiri)
--   psql -U app_portal -d msbd
--   SET app.tenant = '1';
--   UPDATE lab11.pelanggan SET kota = kota WHERE id = 3;     -- harapkan UPDATE 1
--   DELETE FROM lab11.pelanggan WHERE id = 99001;            -- harapkan DELETE 1
-- Jika DELETE 0: app_portal tidak punya kebijakan DELETE pada tenant 1. Itu temuan; catat dan jelaskan.

-- Langkah 2 (postgres): lihat isi jejak
SELECT id, waktu, pelaku, aksi, tabel, kunci FROM lab11.jejak_audit ORDER BY id DESC LIMIT 5;
-- Harapkan: pelaku = app_portal, aksi UPDATE dan DELETE, kunci 3 dan 99001.

-- Langkah 3: bukti hak tanpa menulis apa pun (SELECT katalog saja). Harapkan: baca = f, tulis = f, ubah = f, hapus = f
SELECT has_table_privilege('app_portal','lab11.jejak_audit','SELECT') AS baca,
       has_table_privilege('app_portal','lab11.jejak_audit','INSERT') AS tulis,
       has_table_privilege('app_portal','lab11.jejak_audit','UPDATE') AS ubah,
       has_table_privilege('app_portal','lab11.jejak_audit','DELETE') AS hapus;

-- Opsional, jika dosen mengizinkan uji tulis yang ditolak (login sebagai app_portal):
--   SELECT * FROM lab11.jejak_audit;                                             -- harapkan permission denied
--   INSERT INTO lab11.jejak_audit(pelaku, aksi, tabel) VALUES ('palsu','DELETE','pelanggan');  -- harapkan permission denied
