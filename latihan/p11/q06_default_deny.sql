-- Diminta: membuktikan perilaku default-deny saat Row-Level Security diaktifkan tanpa kebijakan.
-- Dipilih: ALTER TABLE ... ENABLE ROW LEVEL SECURITY lalu SELECT sebagai app_laporan.
-- Alternatif: mengandalkan filter aplikasi sebelum kebijakan dibuat; tidak dipilih karena berisiko membocorkan data.

ALTER TABLE lab11.pelanggan ENABLE ROW LEVEL SECURITY;
BEGIN; SET LOCAL ROLE app_laporan;
  SELECT count(*) AS sebelum_ada_kebijakan FROM lab11.pelanggan; -- harapkan 0
COMMIT;
