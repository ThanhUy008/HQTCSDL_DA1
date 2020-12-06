use[QuanLyCongTy2020_3]
go
-- NHAN VIEN:

-- Xem danh sách nhà
create proc XemDanhSachNha
as
begin
	select * from [dbo].[Nha]
end

-- Tìm nhà
create proc TimNha(@manha int)
as
begin
	select* from [dbo].[Nha]
	where MaNha= @manha
end

-- Sửa thông tin nhà

-- sửa lượt xem
create proc SuaTTN_LuotXem (@manha int, @luotxem tinyint)
as
begin
	update [dbo].[Nha] set LuotXem= @luotxem
	where MaNha= @manha
end
-- sửa tình trạng
create proc SuaTTN_TinhTrang (@manha int, @tinhtrang int)
as
begin
	update [dbo].[Nha] set TinhTrang= @tinhtrang
	where MaNha= @manha
end

-- sửa ngày đăng
create proc SuaTTN_NgayDang (@manha int, @ngaydang date)
as
begin
	update [dbo].[Nha] set NgayDang= @ngaydang
	where MaNha= @manha
end

-- sửa ngày hết hạn
create proc SuaTTN_NgayHetHan (@manha int, @ngayhethan date)
as
begin
	update [dbo].[Nha] set NgayHetHan= @ngayhethan
	where MaNha= @manha
end

-- sửa loại nhà
create proc SuaThongTinNha (@manha int, @loainha smallint)
as
begin
	update [dbo].[Nha] set LoaiNha= @loainha
	where MaNha= @manha
end

-- Xóa thông tin nhà
create proc XoaThongTinNha(@manha int)
as
begin
	delete from [dbo].[Nha] where MaNha= @manha
end

-- Thêm nhà
-- tình trạng: 0: có sẵn, 1: đã cho thuê/ bán
-- kiểu nhà: 0: nhà bán, 1: nhà thuê

-- nhà thuê
create proc ThemNhaThue (@sophong smallint, @diachi nvarchar(100), @luotxem tinyint, @ngaydang date, @ngayhethan date, @tienthue money, @nvquanly int, @chunha int, @loainha smallint)
as
begin
	insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
	values (@sophong, @diachi, @luotxem, 0, @ngaydang, @ngayhethan, 1, @NVquanly, @chunha, @loainha)
	insert into [dbo].[NhaThue](TienThue)
	values (@tienthue)
end

-- nhà bán
create proc ThemNhaBan (@sophong smallint, @diachi nvarchar(100), @luotxem tinyint, @ngaydang date, @ngayhethan date, @giaban money, @nvquanly int, @chunha int, @loainha smallint)
as
begin
	insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
	values (@sophong, @diachi, @luotxem, 0, @ngaydang, @ngayhethan, 0, @NVquanly, @chunha, @loainha)
	insert into [dbo].[NhaBan](GiaBan)
	values (@giaban)
end

-- Thống kê nhà
-- theo phòng
create proc TimNhaTheoPhong(@sophong smallint)
as
begin
	select* from [dbo].[Nha]
	where SoPhong= @sophong
end

--theo địa chỉ
create proc TimNhaTheoDiaChi(@diachi nvarchar(100))
as
begin
	select* from [dbo].[Nha]
	where DiaChi= @diachi
end

--theo giá từ X-> Y
-- nhà thuê
create proc TimNhaTheoGiaThue(@X money, @Y money)
as
begin
	select* from [dbo].[Nha], [dbo].[NhaThue]
	where Nha.MaNha= NhaThue.MaNha and @X<= TienThue and TienThue<= @Y
end
-- nhà bán
create proc TimNhaTheoGiaBan(@X money, @Y money)
as
begin
	select* from [dbo].[Nha], [dbo].[NhaBan]
	where Nha.MaNha= NhaBan.MaNha and @X<= GiaBan and GiaBan<= @Y
end

--theo cả 3
-- nhà thuê
create proc ThongKeNhaThue(@sophong smallint, @diachi nvarchar(100), @X money, @Y money)
as
begin
	select* from [dbo].[Nha], [dbo].[NhaThue]
	where SoPhong=@sophong and DiaChi= @diachi and Nha.MaNha= NhaThue.MaNha and @X<= TienThue and TienThue<= @Y
end
-- nhà bán
create proc ThongKeNhaBan(@sophong smallint, @diachi nvarchar(100), @X money, @Y money)
as
begin
	select* from [dbo].[Nha], [dbo].[NhaBan]
	where SoPhong=@sophong and DiaChi= @diachi and Nha.MaNha= NhaBan.MaNha and @X<= GiaBan and GiaBan<= @Y
end
-- Thêm đánh giá
create proc ThemDanhGia (@khachhang int, @nha int, @ngayxem date, @nhanxet text)
as
begin
	insert into [dbo].[XemNha](KhachHang, Nha, NgayXem, NhanXet)
	values (@khachhang, @nha, @ngayxem, @nhanxet)
end

-- Nhà theo yêu cầu
create proc NhaTheoYeuCau (@khachhang int, @loainha smallint)
as
begin
	insert into [dbo].[YeuCauKH](KhachHang, LoaiNha)
	values (@khachhang, @loainha)
	select * from [dbo].[Nha]
	where Nha.LoaiNha= @loainha 
end

-- Thông báo khách hàng
-- thông báo khách hàng: 1: đã thông báo
create proc ThongBaoKH (@makhachhang int, @manha int)
as
begin
	insert into [dbo].[ThongBaoKhachHang](MaKhachHang, MaNha, ThongBao)
	values (@makhachhang, @manha, 1)
	select * from [dbo].[Nha]
	where Nha.MaNha= @manha
end

-- Xem danh sách khách hàng
-- giống admin

-- Tìm khách hàng
-- giống admin

-- Sửa thông tin khách hàng
-- giống admin

-- Thêm yêu cầu của khách hàng
create proc ThemYeuCau (@khachhang int, @loainha smallint)
as
begin
	insert into [dbo].[YeuCauKH](KhachHang, LoaiNha)
	values (@khachhang, @loainha) 
end

-- Thêm hợp đồng
create proc ThemHopDong (@khachhang int, @nhathue int, @ngaybatdau date )
as
begin
	insert into [dbo].[QuaTrinhThue](KhachHang, NhaThue, NgayBatDau)
	values (@khachhang, @nhathue, @ngaybatdau) 
end

-- Kết thúc hợp đồng
create proc KetThucHopDong (@khachhang int, @nhathue int, @ngaybatdau date, @ngayketthuc date)
as
begin
	update [dbo].[QuaTrinhThue] set NgayKetThuc= @ngayketthuc
	where KhachHang= @khachhang and NhaThue= @nhathue and NgayBatDau= @ngaybatdau
end

-- Thêm khách hàng
create proc ThemKhachHang (@ten nvarchar(50), @diachi nvarchar(100), @sdt nvarchar(20), @chinhanhquanly smallint)
as
begin
	insert into [dbo].[KhachHang](Ten, DiaChi, SDT, ChiNhanhQuanLy)
	values (@ten, @diachi, @sdt, @chinhanhquanly) 
end
-- Xem danh sách chủ nhà
-- giống admin

-- Sửa thông tin chủ nhà
-- giống admin

-- Tìm kiếm chủ nhà
-- giống admin

-- Thêm chủ nhà
create proc ThemChuNha (@tenchunha nvarchar(50), @tinhtrang int, @diachi nvarchar(100), @loaichunha bit, @sdt nvarchar(20))
as
begin
	insert into [dbo].[ChuNha](TenChuNha, TinhTrang, DiaChi, LoaiChuNha, SDT)
	values (@tenchunha, @tinhtrang, @diachi, @loaichunha, @sdt)
end

-- Cập nhật mật khẩu
create proc DoiMatKhau_NV(@manhanvien int,@matkhaucu nvarchar(20), @matkhaumoi nvarchar(20))
as
	if (@matkhaucu=(select MatKhau from TaiKhoanNhanVien where MaNhanVien= @manhanvien))
	begin
		update TaiKhoanNhanVien with(updlock)
		set MatKhau = @matkhaumoi
	end
go
