-- Diminta: membuktikan bahwa hak biasa (UPDATE) yang dicabut dari pemilik objek dapat diberikan kembali oleh pemilik itu sendiri.
-- Dipilih: REVOKE UPDATE dari skema_owner, uji (harapkan ditolak), lalu GRANT UPDATE kepada diri sendiri sebagai skema_owner, uji lagi (harapkan berhasil).
-- Alternatif: mengandalkan REVOKE untuk membatasi akun pemilik; tidak dipilih karena pemilik tetap dapat memberikan hak itu kembali.
-- Dijalankan sebagai: postgres (REVOKE); skema_owner (uji dan GRANT). Salin keluaran NYATA tiap perintah ke laporan.md.

REVOKE UPDATE ON lab11.pelanggan FROM skema_owner;
SET ROLE skema_owner;
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;  -- harapkan: ERROR permission denied
GRANT UPDATE ON lab11.pelanggan TO skema_owner;                      -- dijalankan oleh pemilik sendiri
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;  -- harapkan: UPDATE 1
RESET ROLE;
