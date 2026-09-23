-- Diminta: memanggil procedure dengan amount negatif, buktikan rollback.
-- Dipilih: CALL dengan nilai -4.99 untuk memicu domain violation.
-- Alternatif: INSERT langsung; tidak dipilih karena tidak menguji procedure.

-- Hitung sebelum
SELECT count(*) AS rental_sebelum FROM lab5.rental_tx;

-- Panggil dengan amount negatif (harus GAGAL)
CALL lab5.process_rental(3, 3, 1, -4.99);

-- Hitung sesudah (harus SAMA, tidak bertambah)
SELECT count(*) AS rental_sesudah FROM lab5.rental_tx;