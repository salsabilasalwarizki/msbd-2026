CREATE TABLE anggota (
    id_anggota bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nomor_anggota varchar(16) NOT NULL UNIQUE,
    nama varchar(120) NOT NULL,
    status varchar(16) NOT NULL DEFAULT 'aktif'
        CHECK (status IN ('aktif','ditangguhkan','keluar')),
    tgl_bergabung date NOT NULL DEFAULT current_date
);

CREATE TABLE peminjaman (
    id_peminjaman bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_anggota bigint NOT NULL REFERENCES anggota(id_anggota),
    tgl_pinjam date NOT NULL DEFAULT current_date,
    jatuh_tempo date NOT NULL,
    tgl_kembali date,
    CONSTRAINT ck_pinjam_tempo
        CHECK (jatuh_tempo >= tgl_pinjam)
);