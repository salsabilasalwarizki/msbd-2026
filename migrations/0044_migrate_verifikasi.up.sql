-- Migration 0044 UP: Verifikasi backfill
-- Fase: MIGRATE - memastikan semua film punya harga

DO $$
DECLARE
    v_missing integer;
BEGIN
    SELECT count(*) INTO v_missing
    FROM lab4.film f
    WHERE NOT EXISTS (
        SELECT 1 FROM lab4.harga_film h
        WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
    );
    
    IF v_missing > 0 THEN
        RAISE EXCEPTION 'Masih ada % film tanpa harga di wilayah ID', v_missing;
    ELSE
        RAISE NOTICE 'Verifikasi berhasil: semua film sudah punya harga';
    END IF;
END $$;