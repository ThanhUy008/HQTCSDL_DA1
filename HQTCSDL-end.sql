drop database[QuanLyCongTy2020]
go
create database[QuanLyCongTy2020]
go
use [QuanLyCongTy2020]


go
create type [dbo].[Flag] from [bit] not null
go
create type [dbo].[Name] from [nvarchar] (100) not null
go
create type [dbo].[Phone] from [nvarchar] (10) null
go
create type [dbo].[ID] from [nvarchar] (20) null
go
set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[ChiNhanh](
	[MaChiNhanh] [ID] not null, 
	[SDT] [dbo].[Phone] not null,
	[Fax] [nvarchar](20) not null,
	[Duong] [dbo].[Name] not null,
	[Quan] [dbo].[Name] not null,
	[KhuVuc] [dbo].[Name] not null,
	[TinhTrang] [dbo].[Flag] not null -- 1 là còn, 0 là ?ã xóa.
)
go
alter table [dbo].[ChiNhanh]
add constraint [ChiNhanh_PK] primary key([MaChiNhanh])
go
set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[ChuNha](
	[MaChuNha] [ID] not null,
	[TenChuNha] [dbo].[Name] not null,
	[TinhTrang] [dbo].[Flag] not null, --1 là còn, 0 là ?ã xóa
	[DiaChi] [nvarchar] (100) null,
	[LoaiChuNha] [bit] not null,
	[SDT] [dbo].[Phone] not null
)
go
alter table [dbo].[ChuNha]
add constraint [ChuNha_PK] primary key([MaChuNha]);
go
set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[NhanVien](
	[MaNhanVien] [ID] not null,
	[Ten] [dbo].[Name] not null,
	[DiaChi] [nvarchar](100) null,
	[GioiTinh] [nchar](1) not null,
	[NgaySinh] [date] not null,
	[TinhTrang] [dbo].[Flag] not null, -- 1 là còn, 0 là ?ã xóa
	[Luong] [money] not null,
	[SDT] [dbo].[Phone] null,
	[ChiNhanh] [ID] not null,
)
go
alter table [dbo].[NhanVien]
add constraint [NhanVien_PK] primary key ([MaNhanVien]);
go
alter table [dbo].[NhanVien]
add constraint [FK_ChiNhanh_NhanVien] foreign key ([ChiNhanh])references [dbo].[ChiNhanh]([MaChiNhanh]) ON DELETE CASCADE  ON UPDATE CASCADE
go
set ansi_nulls on
go
set quoted_identifier on
go


create table [dbo].[KhachHang](
	[MaKhachHang] [ID] not null,
	[Ten] [dbo].[Name] not null,
	[DiaChi] [nvarchar] (100) null,
	[SDT] [dbo].[Phone] not null,
	[ChiNhanhQuanLy] [ID] not null
)
go
alter table [dbo].[KhachHang]
add constraint [KhachHang_PK] primary key ([MaKhachHang]);
go
alter table [dbo].[KhachHang]
add constraint [FK_ChiNhanh_KhachHang] foreign key ([ChiNhanhQuanLy]) references [dbo].[ChiNhanh]([MaChiNhanh]) ON DELETE CASCADE  ON UPDATE CASCADE
go
set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[LoaiNha](
	[MaLoaiNha] [smallint] identity(1,1) not null,
	[Ten] [dbo].[Name] not null
)
go
alter table [dbo].[LoaiNha] 
add constraint [LoaiNha_PK] primary key ([MaLoaiNha]);
go

alter table [dbo].[LoaiNha] 
add constraint [LoaiNha_UC] UNIQUE ([Ten]);
go


set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[Nha](
	[MaNha] [int] identity(1,1) not null,
	[SoPhong] [smallint] null,
	[DiaChi] [nvarchar](100) not null,
	[LuotXem] [int] not null,
	[TinhTrang] [int] not null, --1 là còn có th? cho thuê, 0 là ?ã thuê, 2 là ?ã bán không còn tìm th?y ???c.
	[NgayDang] [date] not null,
	[NgayHetHan] [date] not null,
	[KieuNha] [dbo].[Flag] not null,
	[NVQuanLy] [ID] not null,
	[ChuNha] [ID] not null,
	[LoaiNha] [smallint] not null

)
go
alter table [dbo].[Nha]
add constraint [Nha_PK] primary key ([MaNha]);
go
alter table [dbo].[Nha]
add constraint [FK_NV_Nha] foreign key ([NVQuanLy]) references [dbo].[NhanVien]([MaNhanvien]) ON DELETE CASCADE  ON UPDATE CASCADE
go
alter table [dbo].[Nha]
add constraint [FK_ChuNha_Nha] foreign key ([ChuNha]) references [dbo].[ChuNha]([MaChuNha]) ON DELETE CASCADE  ON UPDATE CASCADE
go
alter table [dbo].[Nha]
add constraint [FK_LoaiNha_Nha] foreign key ([LoaiNha]) references [dbo].[LoaiNha]([MaLoaiNha]) ON DELETE CASCADE  ON UPDATE CASCADE
go
set ansi_nulls on
go
set quoted_identifier on
go


create table [dbo].[ThongBaoKhachHang](
	[MaNha] [int]  not null,
	[MaKhachHang] [ID] not null,
	[ThongBao] [Flag] not null,
)
go
alter table [dbo].[ThongBaoKhachHang]
add constraint [TBKhachHang_PK] primary key ([MaNha],[MaKhachHang]);
go

alter table [dbo].[ThongBaoKhachHang]
add constraint [FK_Nha_ThongBaoKhachHang] foreign key ([MaNha]) references [dbo].[Nha]([MaNha]) 
go
alter table [dbo].[ThongBaoKhachHang]
add constraint [FK_KhachHang_TBKhachHang] foreign key ([MaKhachHang]) references [dbo].[KhachHang]([MaKhachHang])
go
set ansi_nulls on
go
set quoted_identifier on
go





create table [dbo].[NhaThue](
	[MaNha] [int] not null,
	[TienThue] [money] not null
)
go

alter table [dbo].[NhaThue]
add constraint [NhaThue_PK] primary key ([MaNha]);
go

alter table [dbo].[NhaThue]
add constraint [FK_Nha_NhaThue] foreign key ([MaNha]) references [dbo].[Nha]([MaNha]) ON DELETE CASCADE  ON UPDATE CASCADE
go

set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[NhaBan](
	[MaNha] [int] not null,
	[GiaBan] [money] not null,
	[DieuKien] [text] null
)
go

alter table [dbo].[NhaBan]
add constraint [NhaBan_PK] primary key ([MaNha]);
go

alter table [dbo].[NhaBan]
add constraint [FK_Nha_NhaBan] foreign key ([MaNha]) references [dbo].[Nha]([MaNha]) ON DELETE CASCADE  ON UPDATE CASCADE
go

set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[YeuCauKH](
	[KhachHang] [ID] not null,
	[LoaiNha] [smallint] not null
)
go

alter table [dbo].[YeuCauKH]
add constraint [YeuCauKH_PK] primary key ([KhachHang],[LoaiNha]);
go

alter table [dbo].[YeuCauKH]
add constraint [FK_KhachHang_YeuCauKH] foreign key ([KhachHang]) references [dbo].[KhachHang]([MaKhachHang]) ON DELETE CASCADE  ON UPDATE CASCADE
go
alter table [dbo].[YeuCauKH]
add constraint [FK_LoaiNha_YeuCauKH] foreign key ([LoaiNha]) references [dbo].[LoaiNha]([MaLoaiNha]) ON DELETE CASCADE  ON UPDATE CASCADE
go

set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[XemNha](
	[KhachHang] [ID] not null,
	[Nha] [int] not null,
	[NgayXem] [date] not null,
	[NhanXet] [text] null
)

alter table [dbo].[XemNha]
add constraint [xemNha_PK] primary key ([KhachHang],[Nha],[NgayXem]);
go

alter table [dbo].[XemNha]
add constraint [FK_KhachHang_XemNha] foreign key ([KhachHang]) references [dbo].[KhachHang]([MaKhachHang]) ON DELETE CASCADE  ON UPDATE CASCADE
go
alter table [dbo].[XemNha]
add constraint [FK_Nha_XemNha] foreign key ([Nha]) references [dbo].[Nha]([MaNha]) 
go

set ansi_nulls on
go
set quoted_identifier on
go
create table [dbo].[QuaTrinhThue](
	[KhachHang] [ID] not null,
	[NhaThue] [int] not null,
	[NgayBatDau] [date] not null,
	[NgayKetThuc] [date] null
)
go

alter table [dbo].[QuaTrinhThue]
add constraint [QuaTrinhThue_PK] primary key ([KhachHang],[NhaThue],[NgayBatDau]);
go

alter table [dbo].[QuaTrinhThue]
add constraint [FK_KhachHang_QuaTrinhThue] foreign key ([KhachHang]) references [dbo].[KhachHang]([MaKhachHang]) ON DELETE CASCADE  ON UPDATE CASCADE
go
alter table [dbo].[QuaTrinhThue]
add constraint [FK_NhaThue_QuaTrinhThue] foreign key ([NhaThue]) references [dbo].[NhaThue]([MaNha]) 
go


create table [dbo].[AccountKhachHang](
	[IDKhachHang] [ID] not null,
	[Password] [nvarchar] (100) not null,
)
go
alter table [dbo].[AccountKhachHang]
add constraint [AccountKhachHang_PK] primary key ([IDKhachHang]);
go
alter table [dbo].[AccountKhachHang]
add constraint [FK_KhachHang_AccountKhachHang] foreign key ([IDKhachHang]) references [dbo].[KhachHang]([MaKhachHang]) ON DELETE CASCADE  ON UPDATE CASCADE
go
set ansi_nulls on
go
set quoted_identifier on
go


create table [dbo].[AccountNhanVien](
	[IDNhanVien] [ID] not null,
	[Password] [nvarchar] (100) not null,
)
go
alter table [dbo].[AccountNhanVien]
add constraint [AccountNhanVien_PK] primary key ([IDNhanVien]);
go
alter table [dbo].[AccountNhanVien]
add constraint [FK_NhanVien_AccountNhanVien] foreign key ([IDNhanVien]) references [dbo].[NhanVien]([MaNhanVien]) ON DELETE CASCADE  ON UPDATE CASCADE
go
set ansi_nulls on
go
set quoted_identifier on
go

create table [dbo].[AccountChuNha](
	[IDChuNha] [ID] not null,
	[Password] [nvarchar] (100) not null,
)
go
alter table [dbo].[AccountChuNha]
add constraint [AccountChuNha_PK] primary key ([IDChuNha]);
go
alter table [dbo].[AccountChuNha]
add constraint [FK_ChuNha_AccountChunha] foreign key ([IDChuNha]) references [dbo].[ChuNha]([MaChuNha]) ON DELETE CASCADE  ON UPDATE CASCADE
go
set ansi_nulls on
go
set quoted_identifier on
go

create table [dbo].[AccountAdmin](
	[IDAdmin] [ID] not null,
	[Password] [nvarchar] (100) not null,
)
go
alter table [dbo].[AccountAdmin]
add constraint [AccountAdmin_PK] primary key ([IDAdmin]);
go

set ansi_nulls on
go
set quoted_identifier on
go

create table [dbo].[LichSuTraLuong](
	[MaNhanVien] [dbo].[ID] not null,
	[NgayThayDoi] [date] not null,
	[Luong] [money] not null,
)
go
alter table [dbo].[LichSuTraLuong]
add constraint [FK_NhanVien_LichSuTraLuong] foreign key([MaNhanVien]) references [dbo].[NhanVien]([MaNhanVien]) ON DELETE CASCADE  ON UPDATE CASCADE
go
alter table [dbo].[LichSuTraLuong]
add constraint [PK_LichSuTraLuong] primary key ([MaNhanVien],[NgayThayDoi]);
go

--Trigger
CREATE TRIGGER trg_NgayDang
ON [dbo].[Nha]
FOR INSERT,UPDATE
AS
BEGIN
	
	IF(EXISTS (SELECT * FROM inserted WHERE inserted.NgayDang > inserted.NgayHetHan))
	BEGIN
	raiserror('Error: Ngay dang > Ngay het han',16,1)
	rollback
	END

END
GO
CREATE TRIGGER trg_XemNha_Nha
ON [dbo].[Nha]
FOR UPDATE
AS
BEGIN
	
	IF(EXISTS (
				SELECT * 
				FROM inserted join [dbo].[XemNha] on inserted.MaNha = [dbo].[XemNha].[Nha]
				WHERE inserted.MaNha = [dbo].[XemNha].[Nha] AND inserted.NgayDang > [dbo].[XemNha].[NgayXem]))
	BEGIN
	raiserror('Error: Ngay Ngay dang > Ngay xem nha',16,1)
	rollback
	END

END
GO


CREATE TRIGGER trg_XemNha_XemNha
ON [dbo].[XemNha]
FOR INSERT,UPDATE
AS
BEGIN
	
	IF(EXISTS (
				SELECT * 
				FROM inserted join [dbo].[Nha] on inserted.Nha = [dbo].[Nha].[MaNha] 
				WHERE inserted.Nha = [dbo].[Nha].[MaNha] AND inserted.NgayXem < [dbo].[Nha].[NgayDang]))
	BEGIN
	raiserror('Error: Ngay dang > Ngay xem nha',16,1)
	rollback
	END

END
GO

CREATE TRIGGER trg_QuaTrinhThue_Nha
ON [dbo].[Nha]
FOR UPDATE
AS
BEGIN
	
	IF(EXISTS (
				SELECT * 
				FROM inserted join [dbo].[QuaTrinhThue] on inserted.MaNha = [dbo].[QuaTrinhThue].[NhaThue]
				WHERE inserted.MaNha = [dbo].[QuaTrinhThue].[NhaThue] AND inserted.NgayDang > [dbo].[QuaTrinhThue].[NgayBatDau]))
	BEGIN
	raiserror('Error: Ngay Ngay dang > Ngay thue',16,1)
	rollback
	END

END
GO

CREATE TRIGGER trg_QuaTrinhThue_QuaTrinhThue
ON [dbo].[QuaTrinhThue]
FOR INSERT,UPDATE
AS
BEGIN
	
	IF(EXISTS (
				SELECT * 
				FROM inserted join [dbo].[Nha] on inserted.NhaThue = [dbo].[Nha].[MaNha] 
				WHERE inserted.NhaThue = [dbo].[Nha].[MaNha] AND inserted.NgayBatDau < [dbo].[Nha].[NgayDang]))
	BEGIN
	raiserror('Error: Ngay thue < Ngay thue',16,1)
	rollback
	END

END
GO

CREATE TRIGGER trg_QuaTrinhThue_NgayThue
ON [dbo].[QuaTrinhThue]
FOR INSERT,UPDATE
AS
BEGIN
	
	IF(EXISTS (SELECT * FROM inserted WHERE inserted.NgayKetThuc is not null AND inserted.NgayBatDau > inserted.NgayKetThuc))
	BEGIN
	raiserror('Error: Ngay bat dau thue > Ngay dung thue nha',16,1)
	rollback
	END

END
GO

CREATE TRIGGER trg_NhanVien_Gender
ON [dbo].[NhanVien]
FOR INSERT,UPDATE
AS
BEGIN
	
	IF(EXISTS (SELECT * FROM inserted WHERE inserted.GioiTinh != 'M' AND inserted.GioiTinh != 'F'))
	BEGIN
	print('Loi tai day')
	rollback
	END

END
GO
CREATE TRIGGER trg_LuotXem_Nha
ON [dbo].[Nha]
FOR UPDATE, INSERT
AS
BEGIN
	
	IF(EXISTS (
				SELECT * 
				FROM inserted 
				WHERE inserted.LuotXem <=  0))
	BEGIN
	raiserror('Error: Luot xem < 0',16,1)
	rollback
	END

END
GO

CREATE TRIGGER trg_SDT_NhanVien
ON [dbo].[NhanVien]
FOR UPDATE, INSERT
AS
BEGIN
	
	IF(EXISTS (
				SELECT inserted.SDT 
				FROM inserted 
				WHERE inserted.SDT like '%[^0-9]%'))
	BEGIN
	raiserror('Error: SDT sai format',16,1)
	rollback
	END

END
GO
CREATE TRIGGER trg_GiaThue_NhaThue
ON [dbo].[NhaThue]
FOR UPDATE, INSERT
AS
BEGIN
	
	IF(EXISTS (
				SELECT * 
				FROM inserted 
				WHERE inserted.TienThue < 0 ))
	BEGIN
	raiserror('Error: Tien Thue sai format',16,1)
	rollback
	END

END
GO
CREATE TRIGGER trg_GiaBan_NhaBan
ON [dbo].[NhaBan]
FOR UPDATE, INSERT
AS
BEGIN
	
	IF(EXISTS (
				SELECT * 
				FROM inserted 
				WHERE inserted.GiaBan < 0 ))
	BEGIN
	raiserror('Error: Tien Thue sai format',16,1)
	rollback
	END

END
GO
