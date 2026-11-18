-- Diminta: membuat tabel pencatatan permintaan penghapusan subjek data dengan tenggat 72 jam.
-- Dipilih: menggunakan kolom tenggat dengan DEFAULT now() + interval '72 hours'.
-- Alternatif: kolom GENERATED ALWAYS AS ... STORED; tidak dipilih karena PostgreSQL menolak ekspresi timestamptz + interval yang tidak immutable.

CREATE TABLE IF NOT EXISTS lab11.permintaan_hapus (
  id bigserial PRIMARY KEY,
  pelanggan_id int NOT NULL,
  diterima_pada timestamptz NOT NULL DEFAULT now(),
  tenggat timestamptz NOT NULL DEFAULT now() + interval '72 hours',
  status text NOT NULL DEFAULT 'DIPROSES'
);
