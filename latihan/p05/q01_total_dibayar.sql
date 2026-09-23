-- Diminta: function lab5.total_dibayar(p_rental_id bigint) yang mengembalikan total pembayaran.
-- Dipilih: LANGUAGE sql STABLE karena hanya SELECT, tidak ada side effect.
-- Alternatif: LANGUAGE plpgsql; tidak dipilih karena terlalu kompleks untuk query sederhana.

CREATE OR REPLACE FUNCTION lab5.total_dibayar(p_rental_id bigint)
RETURNS numeric LANGUAGE sql STABLE AS $$
  SELECT coalesce(sum(amount), 0) FROM lab5.payment_tx WHERE rental_id = p_rental_id;
$$;

-- Uji dengan rental_id yang belum ada (harus 0)
SELECT lab5.total_dibayar(999) AS total_belum_ada;

-- Insert data uji dulu
INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id) VALUES (1, 1, 1);
INSERT INTO lab5.payment_tx (rental_id, amount) VALUES (1, 4.99);
INSERT INTO lab5.payment_tx (rental_id, amount) VALUES (1, 2.50);

-- Uji lagi
SELECT lab5.total_dibayar(1) AS total_ada;