use[QuanLyCongTy2020]
go
----------------------------- THỌ -------------------------------------------------
-- Chức năng của Admin
-- giao tac doc danh sach nhan vien con lam viec trong cong ty
create proc XemDanhSachNhanVien
as
	select * from [dbo].[NhanVien]
	where TinhTrang=1
go
 --giao tac them nhan vien
alter proc ThemNhanVien(@ten nvarchar(50),@diachi nvarchar(100), @gioitinh Nvarchar(1),@ngaysinh date, @sdt nvarchar(20),@chinhanh smallint)
as
	insert into [dbo].[NhanVien](Ten,DiaChi,GioiTinh,NgaySinh,TinhTrang,SDT,ChiNhanh)
	values (@ten,@diachi,@gioitinh,@ngaysinh,1,@sdt,@chinhanh)
	-- moi lan them nhan vien thif csdl tu them vao 1 tai khoan cho nhan vien do
	--insert into TaiKhoanNhanVien with(Rowlock) (MatKhau) values (@sdt)
go
--giao tac tim kiem nhan vien
create proc TimKiemNhanVien(@manhanvien int)
as
	set tran isolation level Read committed
	select* from [dbo].[NhanVien]
	where MaNhanVien=@manhanvien
go
--giao tac tang luong nhan vien
create proc TangLuong(@manhanvien int,@luongmoi money)
as
	insert into [dbo].[LichSuTraLuong](MaNhanVien,NgayThayDoi,Luong) values ( @manhanvien, GETDATE(),@luongmoi)
go
create function NgayTangLuongGanNhat(@manhanvien int, @ngay date)
returns date as
begin
set tran isolation level Read committed
 return (select ls1.NgayThayDoi from LichSuTraLuong ls1 where @ngay>=ls1.NgayThayDoi and MaNhanVien=@manhanvien -- ngay thay doi luong gan nhat voi ngay dua vao
							and ls1.NgayThayDoi>=all (select ls2.NgayThayDoi from LichSuTraLuong ls2 
							where @ngay>=ls2.NgayThayDoi and MaNhanVien=@manhanvien))
end
go
create function TinhLuong1Ngay(@manhanvien int,@ngay date)
returns float
as
begin
	declare @ngaytangluong date= dbo.NgayTangLuongGanNhat(@manhanvien,@ngay)
	if (@ngaytangluong is null) return 0-- nếu nhân viên đó chưa được thêm vào lich sử trả lương (chưa đi làm)
	declare @n datetime
	set @n=(select(DATEADD(d,-1, DATEADD(mm, DATEDIFF(mm, 0 ,@ngay)+1, 0))))-- lấy ngày cuối cùng của tháng đó
	return ((select Luong from LichSuTraLuong where MaNhanVien=@manhanvien and NgayThayDoi=@ngaytangluong)/(day(@n)))	
end
go
-- giao tac tinh luong nhan vien tu ngay bat dau den ngay ket thuc
create function TinhLuongNV(@manhanvien int,@ngaybatdau date, @ngayketthuc date)
returns float
as
begin
	declare @ngay1 date=@ngaybatdau
	declare @ngay2 date=@ngayketthuc
	declare @res float = 0
	while(@ngay1<=@ngay2)
	begin
		declare @n datetime
		set @n=(select(DATEADD(d,-1, DATEADD(mm, DATEDIFF(mm, 0 ,@ngay1)+1, 0))))
		set @res=@res+ dbo.TinhLuong1Ngay(@manhanvien,@ngay1)
		if(DAY(@ngay1)=DAY(@n))
		begin
			set @ngay1=DATEADD(DAY,-DAY(@ngay1)+1,@ngay1)
			if(MONTH(@ngay1) <12)
				set @ngay1=DATEADD(month,1,@ngay1)
			else
			begin
				set @ngay1=DATEADD(month,-11,@ngay1)
				set @ngay1=DATEADD(year,1,@ngay1)
			end
		end
		else
		set @ngay1=dateadd(day,1,@ngay1)
	end
	return @res	
end
go
-- giao tac tinh luong cua 1 chi nhanh tu ngay bat dau den ngay ket thuc
create function ThongKeLuong(@machinhanh smallint, @ngaybatdau date, @ngayketthuc date)
returns float
as
begin
	declare @res float=0
	declare @idmax int = (select MAX(MaNhanVien) from NhanVien where ChiNhanh=@machinhanh) 
	while(@idmax >44)
	begin
		if((select MaNhanVien from NhanVien where MaNhanVien=@idmax and ChiNhanh=@machinhanh) is not null)
			set @res=@res+dbo.TinhLuongNV(@idmax,@ngaybatdau,@ngayketthuc)
		set @idmax=@idmax-1;
	end
	return @res
end
go
--giao tac xem danh sach khach hang
create proc XemDanhSachKhachHang
as
	select* from KhachHang
go
-- giao tac tim kiem khach hang
create proc TimKiemKhachHang(@makhachhang int)
as
	select* from KhachHang where MaKhachHang=@makhachhang
go
--giao tac xem lich su thue
create proc XemLichSuthue(@makhachhang int)
as
	select kh.Ten, kh.SDT,qt.NhaThue,qt.NgayBatDau,qt.NgayKetThuc from KhachHang kh,QuaTrinhThue qt
	where qt.KhachHang=@makhachhang
go
--giao tac xem danh sach chu nha
create proc XemDanhSachChuNha
as
	select * from ChuNha
go
-- giao tac tim kiem chu nha
create proc TimKiemChuNha(@chunha int)
as
	select * from ChuNha where MaChuNha=@chunha
go
--giao tac xem lich su hoat dong cua chu nha
create proc XemLichSuHoatDongCuaChuNha(@chunha int)
as
	select n.MaNha,n.NgayDang,n.NgayHetHan from Nha n where n.ChuNha=@chunha and n.NgayDang is not null
go



-- cac chuc nang cua user
-- giao tac tim nha
create proc TimNha_SoPhong(@sophong smallint, @kieunha bit)
as
	if (@kieunha=1)
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nb.GiaBan from Nha n, NhaBan nb where SoPhong=@sophong and KieuNha=@kieunha
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nt.TienThue from Nha n, NhaThue nt where SoPhong=@sophong and KieuNha=@kieunha
go
--tim nha theo dia chi
create proc TimNha_DiaChi(@diachi nvarchar(100), @kieunha bit)
as
	if (@kieunha=1)
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nb.GiaBan from Nha n, NhaBan nb where DiaChi=@diachi and KieuNha=@kieunha
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nt.TienThue from Nha n, NhaThue nt where DiaChi=@diachi and KieuNha=@kieunha
go
-- tim nha theo du 3 tieu chi
create proc TimNha(@sophong smallint, @diachi nvarchar(100),@gia1 money,@gia2 money,@kieunha bit)
as

	if (@kieunha=1)
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nb.GiaBan from Nha n, NhaBan nb where DiaChi=@diachi and KieuNha=@kieunha
																									and SoPhong=@sophong and GiaBan>=@gia1 and GiaBan<=@gia2
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nt.TienThue from Nha n, NhaThue nt where DiaChi=@diachi and KieuNha=@kieunha
																									   and SoPhong=@sophong and TienThue>=@gia1 and TienThue <=@gia2
go
-- giao tac yeu cau nha
create proc YeuCauNha(@khachhang int, @loainha smallint)
as
	insert into YeuCauKH(KhachHang,LoaiNha) values (@khachhang,@loainha)
go
-- giao tac doi mat kau
create proc DoiMatKhau_KH(@khachhang int,@mkcu nvarchar(20), @mkmoi nvarchar(20))
as
	if (@mkcu=(select Password from AccountKhachHang where IDKhachHang=@khachhang))
	begin
		update IDKhachHang
		set Password = @mkmoi
	end
go
-----------------------------------------------TRÂM------------------------------------------------------------------
go
-- NHAN VIEN:

-- Xem danh sách nhà
create proc XemDanhSachNha
as
begin tran
	set tran isolation level Read Committed
	select * from [dbo].[Nha]
commit tran
go

-- Tìm nhà
create proc TimNha(@manha int)
as
begin tran
	set tran isolation level Read committed
	select* from [dbo].[Nha] with (readpast)
	where MaNha= @manha
commit
go

-- Sửa thông tin nhà

-- sửa lượt xem
create proc SuaTTN_LuotXem (@manha int, @luotxem tinyint)
as
begin tran
	update [dbo].[Nha] set LuotXem= @luotxem
	where MaNha= @manha
commit
go

-- sửa tình trạng
create proc SuaTTN_TinhTrang (@manha int, @tinhtrang int)
as
begin tran
	update [dbo].[Nha] set TinhTrang= @tinhtrang
	where MaNha= @manha
commit
go

-- sửa ngày đăng
create proc SuaTTN_NgayDang (@manha int, @ngaydang date)
as
begin tran
	update [dbo].[Nha] set NgayDang= @ngaydang
	where MaNha= @manha
commit
go

-- sửa ngày hết hạn
create proc SuaTTN_NgayHetHan (@manha int, @ngayhethan date)
as
begin tran
	update [dbo].[Nha] set NgayHetHan= @ngayhethan
	where MaNha= @manha
commit
go

-- sửa loại nhà
create proc SuaThongTinNha (@manha int, @loainha smallint)
as
begin tran
	update [dbo].[Nha] set LoaiNha= @loainha
	where MaNha= @manha
commit
go

-- Xóa thông tin nhà
create proc XoaThongTinNha(@manha int)
as
begin tran
	delete from [dbo].[Nha] where MaNha= @manha
commit
go

-- Thêm nhà
-- tình trạng: 0: có sẵn, 1: đã cho thuê/ bán
-- kiểu nhà: 0: nhà bán, 1: nhà thuê

-- nhà thuê
create proc ThemNhaThue (@sophong smallint, @diachi nvarchar(100), @luotxem tinyint, @ngaydang date, @ngayhethan date, @tienthue money, @nvquanly int, @chunha int, @loainha smallint)
as
begin tran
	insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
	values (@sophong, @diachi, @luotxem, 0, @ngaydang, @ngayhethan, 1, @NVquanly, @chunha, @loainha)
	insert into [dbo].[NhaThue](TienThue)
	values (@tienthue)
commit
go

-- nhà bán
create proc ThemNhaBan (@sophong smallint, @diachi nvarchar(100), @luotxem tinyint, @ngaydang date, @ngayhethan date, @giaban money, @nvquanly int, @chunha int, @loainha smallint)
as
begin tran
	insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
	values (@sophong, @diachi, @luotxem, 0, @ngaydang, @ngayhethan, 0, @NVquanly, @chunha, @loainha)
	insert into [dbo].[NhaBan](GiaBan)
	values (@giaban)
commit
go

-- Thống kê nhà
-- theo phòng
create proc TimNhaTheoPhong(@sophong smallint)
as
begin tran
	set tran isolation level Read committed
	select* from [dbo].[Nha] with (readpast)
	where SoPhong= @sophong
commit
go

--theo địa chỉ
create proc TimNhaTheoDiaChi(@diachi nvarchar(100))
as
begin tran
	set tran isolation level Read committed
	select* from [dbo].[Nha] with (readpast)
	where DiaChi= @diachi
commit
go

--theo giá từ X-> Y
-- nhà thuê
create proc TimNhaTheoGiaThue(@X money, @Y money)
as
begin tran
	set tran isolation level Read committed
	select* from [dbo].[Nha], [dbo].[NhaThue]  with (readpast)
	where Nha.MaNha= NhaThue.MaNha and @X<= TienThue and TienThue<= @Y
commit
go
-- nhà bán
create proc TimNhaTheoGiaBan(@X money, @Y money)
as
begin tran
	set tran isolation level Read committed
	select* from [dbo].[Nha], [dbo].[NhaBan]  with (readpast)
	where Nha.MaNha= NhaBan.MaNha and @X<= GiaBan and GiaBan<= @Y
commit
go

--theo cả 3
-- nhà thuê
create proc ThongKeNhaThue(@sophong smallint, @diachi nvarchar(100), @X money, @Y money)
as
begin tran
	set tran isolation level Read committed
	select* from [dbo].[Nha], [dbo].[NhaThue]  with (readpast)
	where SoPhong=@sophong and DiaChi= @diachi and Nha.MaNha= NhaThue.MaNha and @X<= TienThue and TienThue<= @Y
commit
go
-- nhà bán
create proc ThongKeNhaBan(@sophong smallint, @diachi nvarchar(100), @X money, @Y money)
as
begin tran
	set tran isolation level Read committed
	select* from [dbo].[Nha], [dbo].[NhaBan]  with (readpast)
	where SoPhong=@sophong and DiaChi= @diachi and Nha.MaNha= NhaBan.MaNha and @X<= GiaBan and GiaBan<= @Y
commit
go

-- Thêm đánh giá
create proc ThemDanhGia (@khachhang int, @nha int, @ngayxem date, @nhanxet text)
as
begin tran
	insert into [dbo].[XemNha](KhachHang, Nha, NgayXem, NhanXet)
	values (@khachhang, @nha, @ngayxem, @nhanxet)
commit
go

-- Nhà theo yêu cầu
create proc NhaTheoYeuCau (@khachhang int, @loainha smallint)
as
begin tran
	insert into [dbo].[YeuCauKH](KhachHang, LoaiNha)
	values (@khachhang, @loainha)
	select * from [dbo].[Nha]
	where Nha.LoaiNha= @loainha 
commit tran
go

-- Thông báo khách hàng
-- thông báo khách hàng: 1: đã thông báo
create proc ThongBaoKhachHang (@makhachhang int, @manha int)
as
begin tran
	insert into [dbo].[ThongBaoKhachHang](MaKhachHang, MaNha, ThongBao)
	values (@makhachhang, @manha, 1)
	select * from [dbo].[Nha]
	where Nha.MaNha= @manha
commit tran
go

-- Xem danh sách khách hàng
-- giống admin

-- Tìm khách hàng
-- giống admin

-- Sửa thông tin khách hàng
-- giống admin

-- Thêm yêu cầu của khách hàng
create proc ThemYeuCau (@khachhang int, @loainha smallint)
as
begin tran
	insert into [dbo].[YeuCauKH](KhachHang, LoaiNha)
	values (@khachhang, @loainha) 
commit tran
go

-- Thêm hợp đồng
create proc ThemHopDong (@khachhang int, @nhathue int, @ngaybatdau date )
as
begin tran
	insert into [dbo].[QuaTrinhThue](KhachHang, NhaThue, NgayBatDau)
	values (@khachhang, @nhathue, @ngaybatdau) 
commit tran
go

-- Kết thúc hợp đồng
create proc KetThucHopDong (@khachhang int, @nhathue int, @ngaybatdau date, @ngayketthuc date )
as
begin tran
	update [dbo].[QuaTrinhThue] set NgayKetThuc= @ngayketthuc
	where KhachHang= @khachhang and NhaThue= @nhathue and NgayBatDau= @ngaybatdau) 
commit tran
go

-- Thêm khách hàng
create proc ThemKhachHang (@ten nvarchar(50), @diachi nvarchar(100), @sdt nvarchar(20), @chinhanhquanly smallint )
as
begin tran
	insert into [dbo].[KhachHang](Ten, DiaChi, SDT, ChiNhanhQuanLy)
	values (@ten, @diachi, @sdt, @chinhanhquanly) 
commit tran
go

-- Xem danh sách chủ nhà
-- giống admin

-- Sửa thông tin chủ nhà
-- giống admin

-- Tìm kiếm chủ nhà
-- giống admin

-- Thêm chủ nhà
create proc ThemChuNha (@tenchunha nvarchar(50), @tinhtrang int, @diachi nvarchar(100), @loaichunha bit, @sdt nvarchar(20))
as
begin tran
	insert into [dbo].[ChuNha](TenChuNha, TinhTrang, DiaChi, LoaiChuNha, SDT)
	values (@tenchunha, @tinhtrang, @diachi, @loaichunha, @sdt)
commit
go

-- Cập nhật mật khẩu
create proc DoiMatKhau_NV(@manhanvien int,@matkhaucu nvarchar(20), @matkhaumoi nvarchar(20))
as
	if (@matkhaucu=(select Password from AccountNhanVien where IDNhanVien= @manhanvien))
	begin
		update IDNhanVien with(updlock)
		set Password = @matkhaumoi
	end
go
-----------------------------------------------VI--------------------------------------------------------------------
-- Sua thong tin nhan vien
create proc SuaTenNhanVien(@manv int, @ten nvarchar(50))
as
begin
	update [dbo].[NhanVien] set Ten = @ten
	where MaNhanVien= @manv
end
go

create proc SuaDiaChiNhanVien(@manv int, @diachi nvarchar(50))
as
begin
	update [dbo].[NhanVien] set DiaChi = @diachi
	where MaNhanVien= @manv
end
go

create proc SuaGioiTinhNhanVien(@manv int,  @gioitinh nchar(1))
as
begin
	update [dbo].[NhanVien] set GioiTinh = @gioitinh
	where MaNhanVien= @manv
end
go

create proc SuaNgaySinhNhanVien(@manv int, @ngaysinh date, @sdt nvarchar( 20))
as
begin
	update [dbo].[NhanVien] set NgaySinh = @ngaysinh
	where MaNhanVien= @manv
end
go

create proc SuaSDTNhanVien(@manv int, @sdt nvarchar( 20))
as
begin
	update [dbo].[NhanVien] set SDT = @sdt
	where MaNhanVien= @manv
end
go

-- Sua thong tin khach hang
create proc SuaTenKhachHang(@makh int, @ten nvarchar(50))
as
begin
	update [dbo].[KhachHang] set Ten = @ten
	where MaKhachHang = @makh
end
go

create proc SuaDiaChiKhachHang(@makh int, @diachi nvarchar(50))
as
begin
	update [dbo].[KhachHang] set DiaChi = @diachi
	where MaKhachHang = @makh
end
go

create proc SuaSDTKhachHang(@makh int@sdt nvarchar( 20))
as
begin
	update [dbo].[KhachHang] set SDT = @sdt
	where MaKhachHang = @makh
end
go

create proc SuaChiNhanhQLKhachHang(@makh int, @chinhanhql smallint)
as
begin
	update [dbo].[KhachHang] set ChiNhanhQuanLy = @chinhanhql
	where MaKhachHang = @makh
end
go

-----------------------------------------------THẮNG-----------------------------------------------------------------
go
--Giao tac them nha thue

create proc ThemNhaThue(@sophong smallint,@diachi nvarchar(100), @soluotxem tinyint,@ngaydang date, @ngayhethang date,@giathue money,@yeucau varchar(20),@machunha int)
as
begin tran
	insert into Nha with(Rowlock)(SoPhong,DiaChi,LuotXem,NgayDang,NgayHetHan,ChuNha)
	values (@sophong,@diachi,@soluotxem,@ngaydang,@ngayhethang,@machunha)
	insert into NhaThue with(Rowlock)(TienThue)
	values(@giathue)
commit tran
--giao tac them nha ban
create proc ThemNhaBan(@sophong smallint,@diachi nvarchar(100), @soluotxem tinyint,@ngaydang date, @ngayhethang date,@giathue money,@yeucau text,@machunha int)
as
begin tran
	insert into Nha with(Rowlock)(SoPhong,DiaChi,LuotXem,NgayDang,NgayHetHan,ChuNha)
	values (@sophong,@diachi,@soluotxem,@ngaydang,@ngayhethang,@machunha)
	insert into NhaBan with(Rowlock)(GiaBan,DieuKien)
	values(@giathue,@yeucau)
commit tran
--giao tac tim kiem nha cua chu nha
create proc TimNha(@manha int,@machunha int)
as
begin tran
	set tran isolation level Read committed
	select Nha.MaNha,Nha.DiaChi,QuaTrinhThue.KhachHang,QuaTrinhThue.NgayBatDau from Nha,QuaTrinhThue where Nha.ChuNha=@machunha and QuaTrinhThue.NhaThue=Nha.MaNha
commit
--giao tac xem danh sach nha
create proc XemDanhSachNha(@machunha int)
as
begin tran
set tran isolation level Read committed
	select * from Nha where Nha.ChuNha=@machunha
commit
go
--giao tac xem cap nhat mat khau 
create proc CapnhatMK_KH(@machunha int,@mkcu nvarchar(20), @mkmoi nvarchar(20))
as
	if (@mkcu=(select Password from AccountChuNha where IDChuNha=@machunha))
	begin
		update IDChuNha with(updlock)
		set Password = @mkmoi
	end
go

