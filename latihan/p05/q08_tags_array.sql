-- Diminta: isi tags dengan array dan cari dengan operator ANY.
-- Dipilih: ARRAY constructor dan operator = ANY untuk pencarian.
-- Alternatif: @> operator; tidak dipilih karena ANY lebih umum.

-- Update tags
UPDATE lab5.rental_tx SET tags = ARRAY['promo','akhir-pekan','anggota'] WHERE rental_id = 1;

-- Cari baris dengan tag 'promo'
SELECT rental_id, tags FROM lab5.rental_tx WHERE 'promo' = ANY(tags);

-- Cari baris dengan tag 'vip' (harus kosong)
SELECT rental_id, tags FROM lab5.rental_tx WHERE 'vip' = ANY(tags);