-- Setup index untuk Q12-Q16

-- Partial index (hanya untuk status = 'GAGAL')
CREATE INDEX ev_gagal_idx ON lab6.event_log (terjadi_pada DESC) WHERE status = 'GAGAL';

-- Expression index (lower email)
CREATE INDEX ev_email_lower_idx ON lab6.event_log (lower(email));

-- Covering index (INCLUDE kolom tambahan)
CREATE INDEX ev_cover_idx ON lab6.event_log (customer_id) INCLUDE (terjadi_pada, jumlah);

-- Index polos pada terjadi_pada untuk perbandingan
CREATE INDEX ev_terjadi_pada_idx ON lab6.event_log (terjadi_pada DESC);