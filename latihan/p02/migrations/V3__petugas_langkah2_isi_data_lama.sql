UPDATE distribusi_bantuan
SET petugas_verifikasi = 'tidak tercatat'
WHERE petugas_verifikasi IS NULL;