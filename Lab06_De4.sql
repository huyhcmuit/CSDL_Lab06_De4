CREATE DATABASE DE4 
--1. 
CREATE TABLE KHACHHANG (
    MaKH CHAR(5) PRIMARY KEY,
    HoTen VARCHAR(30),
    DiaChi VARCHAR(30),
    SoDT VARCHAR(15),
    LoaiKH VARCHAR(10)
);

CREATE TABLE BANG_DIA (
    MaBD CHAR(5) PRIMARY KEY,
    TenBD VARCHAR(25),
    TheLoai VARCHAR(25)
);

CREATE TABLE PHIEUTHUE (
    MaPT CHAR(5) PRIMARY KEY,
    MaKH CHAR(5),
    NgayThue SMALLDATETIME,
    NgayTra SMALLDATETIME,
    SoLuongThue INT,
    FOREIGN KEY (MaKH) REFERENCES KHACHHANG(MaKH)
);

CREATE TABLE CHITIET_PM (
    MaPT CHAR(5),
    MaBD CHAR(5),
    PRIMARY KEY (MaPT, MaBD),
    FOREIGN KEY (MaPT) REFERENCES PHIEUTHUE(MaPT),
    FOREIGN KEY (MaBD) REFERENCES BANG_DIA(MaBD)
);

-- 2.
-- 2.1. 
ALTER TABLE BANG_DIA
ADD CONSTRAINT CK_TheLoai CHECK (TheLoai IN ('ca nhac', 'phim hanh dong', 'phim tinh cam', 'phim hoat hinh'));
-- 2.2. 
GO
CREATE TRIGGER TR_KiemTraLoaiKH
ON PHIEUTHUE
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN KHACHHANG K ON I.MaKH = K.MaKH
        WHERE I.SoLuongThue > 5 AND K.LoaiKH <> 'VIP'
    )
    BEGIN
        ROLLBACK;
        THROW 50001, 'Chi khach hang loai VIP moi duoc thue voi so luong bang dia tren 5.', 1;
    END
END;
GO
-- 3. 
-- 3.1. 
SELECT DISTINCT KH.MaKH, KH.HoTen
FROM KHACHHANG KH
JOIN PHIEUTHUE PT ON KH.MaKH = PT.MaKH
JOIN CHITIET_PM CT ON PT.MaPT = CT.MaPT
JOIN BANG_DIA BD ON CT.MaBD = BD.MaBD
WHERE BD.TheLoai = 'phim tinh cam' AND PT.SoLuongThue > 3;

-- 3.2.
WITH SoLuongThue AS (
    SELECT KH.MaKH, KH.HoTen, SUM(PT.SoLuongThue) AS TongSoLuong
    FROM KHACHHANG KH
    JOIN PHIEUTHUE PT ON KH.MaKH = PT.MaKH
    WHERE KH.LoaiKH = 'VIP'
    GROUP BY KH.MaKH, KH.HoTen
),
MaxThue AS (
    SELECT MAX(TongSoLuong) AS MaxSoLuong
    FROM SoLuongThue
)
SELECT SL.MaKH, SL.HoTen
FROM SoLuongThue SL
JOIN MaxThue MT ON SL.TongSoLuong = MT.MaxSoLuong;

-- 3.3. 
WITH SoLuongThue_TheLoai AS (
    SELECT BD.TheLoai, KH.MaKH, KH.HoTen, COUNT(CT.MaBD) AS SoLuong
    FROM KHACHHANG KH
    JOIN PHIEUTHUE PT ON KH.MaKH = PT.MaKH
    JOIN CHITIET_PM CT ON PT.MaPT = CT.MaPT
    JOIN BANG_DIA BD ON CT.MaBD = BD.MaBD
    GROUP BY BD.TheLoai, KH.MaKH, KH.HoTen
),
MaxThue_TheLoai AS (
    SELECT TheLoai, MAX(SoLuong) AS MaxSoLuong
    FROM SoLuongThue_TheLoai
    GROUP BY TheLoai
)
SELECT SL.TheLoai, SL.HoTen
FROM SoLuongThue_TheLoai SL
JOIN MaxThue_TheLoai MT ON SL.TheLoai = MT.TheLoai AND SL.SoLuong = MT.MaxSoLuong
