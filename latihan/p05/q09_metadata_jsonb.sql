-- Diminta: simpan JSONB dan ambil field dengan operator ->>.
-- Dipilih: operator ->> untuk extract sebagai text.
-- Alternatif: operator -> (menghasilkan jsonb); tidak dipilih karena perlu cast.

-- Update metadata
UPDATE lab5.rental_tx
SET metadata = '{"channel":"web","device":"android","browser":"chrome"}'::jsonb
WHERE rental_id = 1;

-- Ambil channel
SELECT rental_id, metadata ->> 'channel' AS kanal FROM lab5.rental_tx WHERE rental_id = 1;

-- Ambil device
SELECT rental_id, metadata ->> 'device' AS perangkat FROM lab5.rental_tx WHERE rental_id = 1;

-- Cek struktur JSONB
SELECT rental_id, jsonb_pretty(metadata) AS metadata_formatted FROM lab5.rental_tx WHERE rental_id = 1;