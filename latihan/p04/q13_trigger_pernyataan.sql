-- Diminta: membuat trigger level pernyataan dengan transition table.
-- Dipilih: REFERENCING OLD TABLE AS lama NEW TABLE AS baru untuk audit massal.
-- Alternatif: trigger per baris; tidak dipilih karena diminta per pernyataan.

-- Bersihkan dulu jika sudah ada dari percobaan sebelumnya
DROP TRIGGER IF EXISTS film_audit_harga_massal ON lab4.film;
DROP FUNCTION IF EXISTS lab4.catat_audit_massal();
DROP TABLE IF EXISTS lab4.audit_harga_massal CASCADE;

-- Buat tabel audit massal
CREATE TABLE lab4.audit_harga_massal (
    audit_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    harga_lama numeric(5,2),
    harga_baru numeric(5,2),
    diubah_oleh text NOT NULL DEFAULT current_user,
    diubah_pada timestamptz NOT NULL DEFAULT now()
);

-- Buat fungsi dengan nama alias yang BENAR: lama dan baru (BUKAN OLD/NEW)
CREATE OR REPLACE FUNCTION lab4.catat_audit_massal()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO lab4.audit_harga_massal (film_id, harga_lama, harga_baru)
    SELECT lama.film_id, lama.rental_rate, baru.rental_rate
    FROM lama
    JOIN baru ON lama.film_id = baru.film_id
    WHERE lama.rental_rate IS DISTINCT FROM baru.rental_rate;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Buat trigger dengan transition table
CREATE TRIGGER film_audit_harga_massal
AFTER UPDATE ON lab4.film
REFERENCING OLD TABLE AS lama NEW TABLE AS baru
FOR EACH STATEMENT
EXECUTE FUNCTION lab4.catat_audit_massal();

-- Uji dengan timing
\timing on
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;
\timing off

-- Cek hasilnya
SELECT count(*) AS jumlah_audit FROM lab4.audit_harga_massal;