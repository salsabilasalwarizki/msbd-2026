-- Diminta: menguji isolasi penyewa 1 dengan uji positif (data sendiri) dan uji negatif (data penyewa 2).
-- Dipilih: menjalankan SELECT dalam transaksi dengan SET LOCAL app.tenant = '1'.
-- Alternatif: hanya melakukan uji positif; tidak dipilih karena tidak membuktikan kegagalan akses lintas penyewa.

BEGIN; SET LOCAL ROLE app_laporan; SET LOCAL app.tenant = '1';
  SELECT count(*) AS terlihat_tenant1 FROM lab11.pelanggan;              -- harapkan 10000
  SELECT count(*) AS harus_nol FROM lab11.pelanggan WHERE tenant_id = 2; -- harapkan 0
COMMIT;
