-- Diminta: membangun tabel jejak_audit dan trigger SECURITY DEFINER yang merekam pelaku berdasarkan session_user.
-- Dipilih: semua hak langsung pada jejak_audit dicabut dari peran aplikasi dan PUBLIC; hanya trigger yang menulis.
-- Alternatif: current_user; tidak dipilih karena di dalam fungsi SECURITY DEFINER nilainya selalu pemilik fungsi.
-- Dijalankan sebagai: postgres.
-- Urutan: jalankan Q21 SEBELUM file ini. Jika trigger sudah ada saat Q21 (UPDATE 1000 baris), audit ikut mencatat id 12 dan 13 dan angka Q29 berubah.

CREATE TABLE IF NOT EXISTS lab11.jejak_audit (
  id         bigserial PRIMARY KEY,
  waktu      timestamptz NOT NULL DEFAULT now(),
  pelaku     name NOT NULL,
  aksi       text NOT NULL,
  tabel      text NOT NULL,
  kunci      text,
  nilai_lama jsonb,
  nilai_baru jsonb
);

-- search_path dikunci agar fungsi SECURITY DEFINER tidak bisa dibajak lewat objek di skema lain
CREATE OR REPLACE FUNCTION lab11.rekam_audit()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = lab11, pg_temp AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    INSERT INTO lab11.jejak_audit(pelaku, aksi, tabel, kunci, nilai_lama, nilai_baru)
    VALUES (session_user, TG_OP, TG_TABLE_NAME, OLD.id::text, to_jsonb(OLD), to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO lab11.jejak_audit(pelaku, aksi, tabel, kunci, nilai_lama)
    VALUES (session_user, TG_OP, TG_TABLE_NAME, OLD.id::text, to_jsonb(OLD));
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_pelanggan ON lab11.pelanggan;
CREATE TRIGGER trg_audit_pelanggan
  AFTER UPDATE OR DELETE ON lab11.pelanggan
  FOR EACH ROW EXECUTE FUNCTION lab11.rekam_audit();

REVOKE ALL ON lab11.jejak_audit FROM PUBLIC, app_read, app_write, app_laporan, app_portal, app_analitik;
-- Catatan: session_user adalah peran LOGIN. Jika sesi memakai SET ROLE dari postgres, session_user tetap postgres.
-- Karena itu Q26 dijalankan dengan login langsung sebagai app_portal.
