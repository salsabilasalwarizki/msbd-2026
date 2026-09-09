-- Diminta: nama pelanggan yang pernah melakukan pembayaran > 9.99 dalam satu transaksi.
-- Dipilih: EXISTS berkorelasi karena efisien dan menghindari duplikasi tanpa DISTINCT.
-- Alternatif: JOIN + DISTINCT; tidak dipilih karena diminta tidak menggunakan DISTINCT.

SELECT c.first_name || ' ' || c.last_name AS nama_pelanggan
FROM customer c
WHERE EXISTS (
    SELECT 1
    FROM payment p
    WHERE p.customer_id = c.customer_id
    AND p.amount > 9.99
);