-- Diminta: membuat kebijakan isolasi multi-penyewa menggunakan current_setting yang aman terhadap string kosong.
-- Dipilih: menggunakan nullif(current_setting('app.tenant', true), '')::int pada USING dan WITH CHECK.
-- Alternatif: casting ::int langsung; tidak dipilih karena memicu galat invalid input syntax for type integer: "" saat koneksi dipakai ulang.

CREATE POLICY p_tenant_baca ON lab11.pelanggan
  FOR SELECT TO app_read, app_write
  USING (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

CREATE POLICY p_tenant_tulis ON lab11.pelanggan
  FOR ALL TO app_write
  USING      (tenant_id = nullif(current_setting('app.tenant', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant', true), '')::int);
