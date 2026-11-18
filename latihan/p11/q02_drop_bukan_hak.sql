-- Diminta: membuktikan bahwa DROP bukan hak akses biasa yang dapat dicabut dengan REVOKE.
-- Dipilih: REVOKE DROP ON lab11.akun FROM skema_owner untuk mengamati galat PostgreSQL.
-- Alternatif: REVOKE ALL; tidak dipilih karena tidak menunjukkan secara spesifik bahwa DROP melekat pada kepemilikan.
-- Dijalankan sebagai: postgres.

REVOKE DROP ON lab11.akun FROM skema_owner;  -- harapkan: ERROR unrecognized privilege type "drop"

-- Penjelasan: SELECT, INSERT, UPDATE, DELETE adalah hak diskresioner (bisa di-GRANT dan REVOKE).
-- DROP dan ALTER tidak punya bentuk GRANT/REVOKE: keduanya melekat pada kepemilikan objek, sehingga
-- pemilik selalu bisa menghapus atau mengubah tabelnya selama ia masih pemilik.
