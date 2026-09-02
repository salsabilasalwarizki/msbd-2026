INSERT INTO jenis_bantuan (nama_bantuan, kategori) VALUES
('Paracetamol 500mg', 'Obat'),
('Beras Premium 5kg', 'Makanan'),
('Masker Medis 1 Box', 'Alat Kesehatan')
ON CONFLICT (nama_bantuan)
DO UPDATE SET kategori = EXCLUDED.kategori;