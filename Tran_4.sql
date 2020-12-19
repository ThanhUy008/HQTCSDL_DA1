use[QuanLyCongTy2020]
go

--TODO: Thêm delay vào các proc này nữa nha
----------------------------- THỌ -------------------------------------------------
-- hàm hỗ trợ
-- tự phát sinh mã
--@str đưa vào là NV nếu là nhân viên và tương tự cho các đối tượng khác
--@num là STT max của nhân viên(tương tự các đối tượng khác) trong bảng
--TODO: mày xóa hết mấy cái STT rồi thì hàm này còn xài được không ?
--TODO: Nguyên cái proc tính lương nhân viên thống kê lương đ xài được. chán thật sự.
go
create function ThemMaSo(@str nvarchar(2), @num int)
returns nvarchar(20) as
begin
	declare @res nvarchar(20)=@str
	declare @temp nvarchar(4)
	if(@num<10)
	begin
		set @temp=N'1000'
		set @res=@res+@temp+(select CAST(@num as nvarchar))
	end
	else if (@num >=10 and @num <100)
	begin
		set @temp=N'100'
		set @res=@res+@temp+(select CAST(@num as nvarchar))
	end
	else if (@num >=100 and @num <1000)
	begin
		set @temp=N'10'
		set @res=@res+@temp+(select CAST(@num as nvarchar))
	end
	else if(@num >=1000 and @num <10000)
	begin
		set @temp=N'1'
		set @res=@res+@temp+(select CAST(@num as nvarchar))
	end
	else set @res=@res+@temp+(select CAST(@num as nvarchar))
	return @res	
end
go
declare @x nvarchar(20)= dbo.ThemMaSo('XX',12)
print @x
go
-- đoạn lệnh dùng để phát sinh mật khẩu: mật khẩu là cuỗi số gồm 6 số được rand
--declare @num int = (select RAND())*1000000
--	while(@num <100000)
--	begin
--		set @num=(select RAND())*1000000
--	end
--declare @res nvarchar(100)=(Select CAST(@num as nvarchar))
--print @res

--go
-- Chức năng của Admin
-- giao tac doc danh sach nhan vien con lam viec trong cong ty
create proc XemDanhSachNhanVien
as
begin tran
	waitfor delay '0:00:05'
	select * from [dbo].[NhanVien]
	where TinhTrang=1

commit tran
go

exec XemDanhSachNhanVien
 --giao tac them nhan vien
 --TODO: Thêm luôn vào cái LS trả lương (ngày thêm nhân viên thì có update lương mới của nó)
 --Bảng nhân viên vẫn có lương vì để khi admin cần vào coi xem ai nên update lương.
 go
create proc ThemNhanVien(@ten nvarchar(50),@diachi nvarchar(100), @gioitinh Nvarchar(1),@ngaysinh date,@luong money, @sdt nvarchar(20),@chinhanh Nvarchar(20))
as
begin tran
	declare @num int =(select count(*) from NhanVien)
	if (@num is null) set @num=0
	declare @manv nvarchar(20)= dbo.ThemMaSo('NV',@num)
	insert into [dbo].[NhanVien](MaNhanVien,Ten,DiaChi,GioiTinh,NgaySinh,TinhTrang,Luong,SDT,ChiNhanh)
	values (@manv,@ten,@diachi,@gioitinh,@ngaysinh,1,@luong,@sdt,@chinhanh)
	-- moi lan them nhan vien thif csdl tu them vao 1 tai khoan cho nhan vien do
	--TODO : password để auto là 123456789, nhân viên vô acc tự sửa
	declare @num1 int = (select RAND())*1000000
	while(@num1 <100000)
	begin
		set @num1=(select RAND())*1000000
	end
	declare @res nvarchar(100)=(Select CAST(@num1 as nvarchar))
	insert into AccountNhanVien (IDNhanVien,Password) values (@manv, '123456789')
	-- them vao lich su tra luong
	if(exists(select * from NhanVien where NhanVien.MaNhanVien = @manv))
	begin
		raiserror('Employee already exists',16,1) 
		rollback
	end
	else
	begin
	waitfor delay '0:00:05'
	insert into LichSuTraLuong (MaNhanVien,NgayThayDoi,Luong) values (@manv,GETDATE(),@luong)
	commit tran
	end
go

exec ThemNhanVien N'Nguyễn Tèo',N'Tp.HCM','M','2000-04-20',15.123,'01234567', 'CN10001'
go
select * from AccountNhanVien
go
--giao tac tim kiem nhan vien
create proc TimKiemNhanVien(@manhanvien nvarchar(20))
as
begin tran
	select* from [dbo].[NhanVien]
	where MaNhanVien=@manhanvien and TinhTrang = 1
commit tran
go
	exec TimKiemNhanVien 'NV10000'
go
--giao tac tang luong nhan vien
-- neu tang luong trong cung 1 ngay thif chi viec update lai luong
--NOTE: Ưng thì kiểm tra xem Mã NV có tồn tại không nữa.
create proc TangLuong(@manhanvien nvarchar(20),@luongmoi money)
as
begin tran
	declare @ngay1 date=getdate()
	declare @ngay2 date=(select max(NgayThayDoi) from LichSuTraLuong where MaNhanVien=@manhanvien)
	if(not exists (Select * from NhanVien where NhanVien.MaNhanVien = @manhanvien)) 
	begin
		raiserror('Not exist Employee',16,1) 
		rollback
	end
	
	else
	begin 
		if( @ngay1=@ngay2)
		begin
			 update LichSuTraLuong set Luong=@luongmoi where MaNhanVien=@manhanvien and NgayThayDoi=@ngay1
			 
		end
			else insert into [dbo].[LichSuTraLuong](MaNhanVien,NgayThayDoi,Luong) values ( @manhanvien, GETDATE(),@luongmoi)
		
		update NhanVien set Luong = @luongmoi where MaNhanVien = @manhanvien
	
	commit tran
	end
go

exec TangLuong 'NV10000',24.5234
go
select * from LichSuTraLuong

go


--giao tac xem danh sach khach hang
create proc XemDanhSachKhachHang
as
begin tran
	select* from KhachHang
commit tran
go
-- giao tac tim kiem khach hang
create proc TimKiemKhachHang(@makhachhang nvarchar(20))
as
begin tran
	select* from KhachHang where MaKhachHang=@makhachhang
commit tran
go
--giao tac xem lich su thue
create proc XemLichSuthue(@makhachhang nvarchar(20))
as
begin tran
	select kh.Ten, kh.SDT,qt.NhaThue,qt.NgayBatDau,qt.NgayKetThuc from KhachHang kh,QuaTrinhThue qt
	where qt.KhachHang=@makhachhang and qt.KhachHang=kh.MaKhachHang
commit tran
go
--giao tac xem danh sach chu nha
create proc XemDanhSachChuNha
as
begin tran
	select * from ChuNha
commit tran
go
-- giao tac tim kiem chu nha
create proc TimKiemChuNha(@chunha nvarchar(20))
as
begin tran
	select * from ChuNha where MaChuNha=@chunha
commit tran
go
--giao tac xem lich su hoat dong cua chu nha
create proc XemLichSuHoatDongCuaChuNha(@chunha nvarchar(20))
as
begin tran
	select n.MaNha,n.NgayDang,n.NgayHetHan from Nha n where n.ChuNha=@chunha and n.NgayDang is not null
commit tran
go



-- cac chuc nang cua user
-- giao tac tim nha
create proc TimNha_SoPhong(@sophong smallint, @kieunha bit)
as
begin tran
	if (@kieunha=1)
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nb.GiaBan from Nha n, NhaBan nb where SoPhong=@sophong and KieuNha=@kieunha
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nt.TienThue from Nha n, NhaThue nt where SoPhong=@sophong and KieuNha=@kieunha
commit tran
go
--tim nha theo dia chi
create proc TimNha_DiaChi(@diachi nvarchar(100), @kieunha bit)
as
begin tran
	if (@kieunha=1)
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nb.GiaBan from Nha n, NhaBan nb where DiaChi=@diachi and KieuNha=@kieunha
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nt.TienThue from Nha n, NhaThue nt where DiaChi=@diachi and KieuNha=@kieunha
commit tran
go
-- tim nha theo du 3 tieu chi
create proc TimNha(@sophong smallint, @diachi nvarchar(100),@gia1 money,@gia2 money,@kieunha bit)
as
begin tran
	if (@kieunha=1)
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nb.GiaBan from Nha n, NhaBan nb where DiaChi=@diachi and KieuNha=@kieunha
																									and SoPhong=@sophong and GiaBan>=@gia1 and GiaBan<=@gia2
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nt.TienThue from Nha n, NhaThue nt where DiaChi=@diachi and KieuNha=@kieunha
																									   and SoPhong=@sophong and TienThue>=@gia1 and TienThue <=@gia2
commit tran
go
-- giao tac yeu cau nha
create proc YeuCauNha(@khachhang nvarchar(20), @loainha smallint)
as
begin tran
	insert into YeuCauKH(KhachHang,LoaiNha) values (@khachhang,@loainha)
commit tran
go
-- giao tac doi mat kau
create proc DoiMatKhau_KH(@khachhang nvarchar(20),@mkcu nvarchar(100), @mkmoi nvarchar(100))
as
begin tran
	if (@mkcu=(select Password from AccountKhachHang where IDKhachHang=@khachhang))
	begin
		update AccountKhachHang
		set Password = @mkmoi
	end
commit tran
go
-----------------------------------------------TRÂM------------------------------------------------------------------
go
-- NHAN VIEN:

-- Xem danh sách nhà
create proc XemDanhSachNha
as
begin tran
	select * from [dbo].[Nha]
commit tran
go
-- Tìm nhà
create proc NV_TimNha(@manha int)
as
begin tran
	select* from [dbo].[Nha]
	where MaNha= @manha
commit tran
go
-- Sửa thông tin nhà

-- sửa lượt xem
create proc SuaTTN_LuotXem (@manha int, @luotxem int)
as
begin tran
	update [dbo].[Nha] set LuotXem= @luotxem
	where MaNha= @manha
commit tran
go
-- sửa tình trạng
create proc SuaTTN_TinhTrang (@manha int, @tinhtrang int)
as
begin tran
	update [dbo].[Nha] set TinhTrang= @tinhtrang
	where MaNha= @manha
commit tran
go
-- sửa ngày đăng
create proc SuaTTN_NgayDang (@manha int, @ngaydang date)
as
begin
	update [dbo].[Nha] set NgayDang= @ngaydang
	where MaNha= @manha
end
go
-- sửa ngày hết hạn
create proc SuaTTN_NgayHetHan (@manha int, @ngayhethan date)
as
begin tran
	update [dbo].[Nha] set NgayHetHan= @ngayhethan
	where MaNha= @manha
commit tran
go
-- sửa loại nhà
create proc SuaThongTinNha (@manha int, @loainha smallint)
as
begin tran
	update [dbo].[Nha] set LoaiNha= @loainha
	where MaNha= @manha
commit tran
go
-- Xóa thông tin nhà
--TODO: xài k được
create proc XoaThongTinNha(@manha int)
as
begin tran
	delete from [dbo].[Nha] where MaNha= @manha
commit tran
go
-- Thêm nhà
-- tình trạng: 0: có sẵn, 1: đã cho thuê/ bán
-- kiểu nhà: 0: nhà bán, 1: nhà thuê

-- nhà thuê
create proc ThemNhaThue (@sophong smallint, @diachi nvarchar(100), @luotxem int, @ngaydang date, @ngayhethan date, @tienthue money, @nvquanly nvarchar(20), @chunha nvarchar(20), @loainha smallint)
as
begin tran
	insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
	values (@sophong, @diachi, @luotxem, 0, @ngaydang, @ngayhethan, 1, @NVquanly, @chunha, @loainha)
	insert into [dbo].[NhaThue](TienThue)
	values (@tienthue)
commit tran
go
-- nhà bán
create proc ThemNhaBan (@sophong smallint, @diachi nvarchar(100), @luotxem int, @ngaydang date, @ngayhethan date, @giaban money, @nvquanly nvarchar(20), @chunha nvarchar(20), @loainha smallint)
as
begin tran
	insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
	values (@sophong, @diachi, @luotxem, 0, @ngaydang, @ngayhethan, 0, @NVquanly, @chunha, @loainha)
	insert into [dbo].[NhaBan](GiaBan)
	values (@giaban)
commit tran
go
-- Thống kê nhà
-- theo phòng
create proc TimNhaTheoPhong(@sophong smallint)
as
begin tran
	select* from [dbo].[Nha]
	where SoPhong= @sophong
commit tran
go
--theo địa chỉ
create proc TimNhaTheoDiaChi(@diachi nvarchar(100))
as
begin tran
	select* from [dbo].[Nha]
	where DiaChi= @diachi
commit tran
go
--theo giá từ X-> Y
-- nhà thuê
create proc TimNhaTheoGiaThue(@X money, @Y money)
as
begin tran
	select* from [dbo].[Nha], [dbo].[NhaThue]
	where Nha.MaNha= NhaThue.MaNha and @X<= TienThue and TienThue<= @Y
commit tran
go
-- nhà bán
create proc TimNhaTheoGiaBan(@X money, @Y money)
as
begin tran
	select* from [dbo].[Nha], [dbo].[NhaBan]
	where Nha.MaNha= NhaBan.MaNha and @X<= GiaBan and GiaBan<= @Y
commit tran
go
--theo cả 3
-- nhà thuê
create proc ThongKeNhaThue(@sophong smallint, @diachi nvarchar(100), @X money, @Y money)
as 
begin tran
	select* from [dbo].[Nha], [dbo].[NhaThue]
	where SoPhong=@sophong and DiaChi= @diachi and Nha.MaNha= NhaThue.MaNha and @X<= TienThue and TienThue<= @Y
commit tran
go
-- nhà bán
create proc ThongKeNhaBan(@sophong smallint, @diachi nvarchar(100), @X money, @Y money)
as
begin tran
	select* from [dbo].[Nha], [dbo].[NhaBan]
	where SoPhong=@sophong and DiaChi= @diachi and Nha.MaNha= NhaBan.MaNha and @X<= GiaBan and GiaBan<= @Y
commit tran
go
-- Thêm đánh giá
create proc ThemDanhGia (@khachhang nvarchar(20), @nha int, @ngayxem date, @nhanxet text)
as
begin tran
	insert into [dbo].[XemNha](KhachHang, Nha, NgayXem, NhanXet)
	values (@khachhang, @nha, @ngayxem, @nhanxet)
commit tran
go
-- Nhà theo yêu cầu: nhận yêu cầu từ bảng YeuCauKH và thông báo tới khách hàng nhà theo yêu cầu
-- thông báo khách hàng: 1: đã thông báo
-- Thọ bảo bảng này bỏ ròi hông cần làm

-- Xem danh sách khách hàng
-- giống admin

-- Tìm khách hàng
-- giống admin

-- Sửa thông tin khách hàng
-- giống admin

-- Thêm yêu cầu của khách hàng
create proc ThemYeuCau (@khachhang nvarchar(20), @loainha smallint)
as
begin tran
	insert into [dbo].[YeuCauKH](KhachHang, LoaiNha)
	values (@khachhang, @loainha) 
commit tran
go
-- Thêm hợp đồng
create proc ThemHopDong (@khachhang nvarchar(20), @nhathue int, @ngaybatdau date )
as
begin tran
	insert into [dbo].[QuaTrinhThue](KhachHang, NhaThue, NgayBatDau)
	values (@khachhang, @nhathue, @ngaybatdau) 
commit tran
go
-- Kết thúc hợp đồng
create proc KetThucHopDong (@khachhang nvarchar(20), @nhathue int, @ngaybatdau date, @ngayketthuc date)
as
begin tran
	update [dbo].[QuaTrinhThue] set NgayKetThuc= @ngayketthuc
	where KhachHang= @khachhang and NhaThue= @nhathue and NgayBatDau= @ngaybatdau
commit tran
go
-- Thêm khách hàng
create proc ThemKhachHang (@ten nvarchar(100), @diachi nvarchar(100), @sdt nvarchar(10), @chinhanhquanly nvarchar(20))
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
create proc ThemChuNha (@tenchunha nvarchar(100), @tinhtrang bit, @diachi nvarchar(100), @loaichunha bit, @sdt nvarchar(10))
as
begin tran
	insert into [dbo].[ChuNha](TenChuNha, TinhTrang, DiaChi, LoaiChuNha, SDT)
	values (@tenchunha, @tinhtrang, @diachi, @loaichunha, @sdt)
commit tran
go
-- Cập nhật mật khẩu
create proc DoiMatKhau_NV(@idnhanvien nvarchar(20), @matkhaucu nvarchar(100), @matkhaumoi nvarchar(100))
as
begin tran
	if (@matkhaucu=(select Password from AccountNhanVien where IDNhanVien= @idnhanvien))
	begin
		update AccountNhanVien with(updlock)
		set Password = @matkhaumoi
	end
commit tran
go
-----------------------------------------------VI--------------------------------------------------------------------
-- Sua thong tin nhan vien
create proc SuaTenNhanVien(@manv int, @ten nvarchar(50))
as
begin tran
	update [dbo].[NhanVien] set Ten = @ten
	where MaNhanVien= @manv
commit tran
go

create proc SuaDiaChiNhanVien(@manv int, @diachi nvarchar(50))
as
begin tran
	update [dbo].[NhanVien] set DiaChi = @diachi
	where MaNhanVien= @manv
commit tran
go

create proc SuaGioiTinhNhanVien(@manv int,  @gioitinh nchar(1))
as
begin tran
	update [dbo].[NhanVien] set GioiTinh = @gioitinh
	where MaNhanVien= @manv
commit tran
go

create proc SuaNgaySinhNhanVien(@manv int, @ngaysinh date, @sdt nvarchar( 20))
as
begin tran
	update [dbo].[NhanVien] set NgaySinh = @ngaysinh
	where MaNhanVien= @manv
commit tran
go

create proc SuaSDTNhanVien(@manv int, @sdt nvarchar( 20))
as
begin tran
	update [dbo].[NhanVien] set SDT = @sdt
	where MaNhanVien= @manv
commit tran
go

-- Sua thong tin khach hang
create proc SuaTenKhachHang(@makh int, @ten nvarchar(50))
as
begin tran
	update [dbo].[KhachHang] set Ten = @ten
	where MaKhachHang = @makh
commit tran
go

create proc SuaDiaChiKhachHang(@makh int, @diachi nvarchar(50))
as
begin tran
	update [dbo].[KhachHang] set DiaChi = @diachi
	where MaKhachHang = @makh
commit tran
go

create proc SuaSDTKhachHang(@makh int,@sdt nvarchar(20))
as
begin tran
	update [dbo].[KhachHang] set SDT = @sdt
	where MaKhachHang = @makh
commit tran
go

create proc SuaChiNhanhQLKhachHang(@makh int, @chinhanhql smallint)
as
begin tran
	update [dbo].[KhachHang] set ChiNhanhQuanLy = @chinhanhql
	where MaKhachHang = @makh
commit tran
go

-----------------------------------------------THẮNG-----------------------------------------------------------------

--------------------------
-----------------Chức năng chủ nhà-------

--Hàm hỗ trợ thêm nhà thuê/bán
--@sophong số phòng của nhà,
--@diachi địa chỉ nhà,
--@soluotxem số lượt xem nhà,
--@ngaydang ngày đăng nhà,
--@ngayhethang ngày hết hạng đăng nhà,
--@kieunha 0/1 là nhà thuê/bán,
--@loainha loại nhà,
--@nvql mã nhân viên quản lý nhà,
--@machunha mã chủ nhà .
--TODO Thêm nhà vào bảng nhà.
create proc Them_nha (@sophong smallint,@diachi nvarchar(100), @soluotxem tinyint,@ngaydang date, @ngayhethang date,@kieunha bit,@loainha int,@nvql nvarchar(20),@machunha nvarchar(20))
as
begin tran 
	insert into Nha with(Rowlock)(SoPhong,DiaChi,LuotXem,TinhTrang,NgayDang,NgayHetHan,KieuNha,LoaiNha,NVQuanLy,ChuNha)
	values (@sophong,@diachi,@soluotxem,1,@ngaydang,@ngayhethang,@kieunha,@loainha,@nvql,@machunha)
commit tran
go
exec them_nha 1,'thang hung',3,'2020-11-11','2020-12-12',0,1,NV10000,LL10000
go
--Hàm hỗ trợ thêm nhà thuê
--@sophong số phòng của nhà,
--@diachi địa chỉ nhà,
--@soluotxem số lượt xem nhà,
--@ngaydang ngày đăng nhà,
--@ngayhethang ngày hết hạng đăng nhà,
--@giathue giá tiền thuê nhà
--@loainha loại nhà,
--@nvql mã nhân viên quản lý nhà,
--@machunha mã chủ nhà .
--TODO Thêm nhà thuê vào data.
create proc Them_nhathue(@sophong smallint,@diachi nvarchar(100), @soluotxem tinyint,@ngaydang date, @ngayhethang date,@giathue money,@loainha int,@nvql varchar(20),@machunha varchar(20))
as
begin tran
	exec Them_nha @sophong,@diachi,@soluotxem,@ngaydang,@ngayhethang,0,@loainha,@nvql,@machunha
	declare @manha int
	select @manha=Max(Nha.MaNha) from Nha
	insert into NhaThue with(Rowlock)(MaNha,TienThue)
	values(@manha,@giathue)
commit tran
go
exec Them_nhathue 1,'thang hung',3,'2020-11-11','2020-12-12',6666,4,NV10000,LL10000
go
--Hàm hỗ trợ thêm nhà Bán
--@sophong số phòng của nhà,
--@diachi địa chỉ nhà,
--@soluotxem số lượt xem nhà,
--@ngaydang ngày đăng nhà,
--@ngayhethang ngày hết hạng đăng nhà,
--@giaban giá tiền bán nhà,
--@yeucau điều kiện bán nhà,
--@loainha loại nhà,
--@nvql mã nhân viên quản lý nhà,
--@machunha mã chủ nhà .
--TODO Thêm nhà bán vào data.
create proc Them_nhaban(@sophong smallint,@diachi nvarchar(100), @soluotxem tinyint,@ngaydang date, @ngayhethang date,@giaban money,@yeucau text,@loainha int,@nvql varchar(20),@machunha varchar(20))
as
begin tran
	exec Them_nha @sophong,@diachi,@soluotxem,@ngaydang,@ngayhethang,1,@loainha,@nvql,@machunha
	declare @manha int
	select @manha=Max(Nha.MaNha) from Nha
	insert into NhaBan with(Rowlock)(MaNha,GiaBan,DieuKien)
	values(@manha,@giaban,@yeucau)
commit tran
go
exec Them_nhaban 1,'thang hung',3,'2020-11-11','2020-12-12',6666,'chu nha phai dep trai',4,NV10000,LL10000
go
--Hàm tìm nhà của chủ nhà
--@manha mã nhà cần tìm,
--@machunha mã chủ nhà của nhà cần tìm
--TODO Tìm nhà cho chủ nhà.
create proc CN_TimNha(@manha int,@machunha nvarchar(20))
as
begin tran
	set tran isolation level Read committed
	select Nha.MaNha,Nha.DiaChi,QuaTrinhThue.KhachHang,QuaTrinhThue.NgayBatDau,QuaTrinhThue.NgayKetThuc from Nha,QuaTrinhThue where Nha.ChuNha=@machunha and QuaTrinhThue.NhaThue=Nha.MaNha and nha.MaNha=@manha
commit
go
exec CN_TimNha 2,LL10021
go
--Hàm xem danh sách nhà của chủ nhà
--@machunha mã chủ nhà
--TODO: Xem danh sách tất cả nhà của chủ nhà
alter proc XemDanhSachNha(@machunha nvarchar(20))
as
begin tran
	set tran isolation level Read committed 
	select * from Nha where nha.ChuNha=@machunha
commit
go
exec XemDanhSachNha LL10021
GO
--------------------------------------FIX FUNCTION--------------------------
--Tinh Luong NV

CREATE FUNCTION f_changInPeriod(@first DATE,@last DATE,@id nvarchar(20))
RETURNS TABLE
AS
return 		SELECT *
			FROM (
				  SELECT * , ROW_NUMBER() OVER (
				  PARTITION BY LichSuTraLuong.MaNhanVien
				  ORDER BY LichSuTraLuong.NgayThayDoi DESC) row_num
  				  FROM LichSuTraLuong 
				  WHERE LichSuTraLuong.MaNhanVien = @id AND LichSuTraLuong.NgayThayDoi <= @last AND LichSuTraLuong.NgayThayDoi >= @first) temp
			--WHERE temp.row_num = 1

GO

CREATE FUNCTION f_OldRate(@first DATE,@last DATE, @id nvarchar(20))
RETURNS TABLE
AS
return		SELECT *
			FROM (
				  SELECT * , ROW_NUMBER() OVER (
				  PARTITION BY LichSuTraLuong.MaNhanVien
				  ORDER BY LichSuTraLuong.NgayThayDoi DESC) row_num
  				  FROM LichSuTraLuong 
				  WHERE LichSuTraLuong.MaNhanVien = @id AND LichSuTraLuong.NgayThayDoi <= @last) temp
			WHERE temp.row_num = 1
GO






CREATE PROC admin_TinhLuongNhanVien(@id nvarchar(20),@firstDay DATE,@lastDay DATE)

AS
BEGIN TRAN
DECLARE @temptable TABLE
(
	id nvarchar(20),
	TotalPayment money,
	firstday DATETIME,
	lastday DATETIME,
	currentRate money

)
DECLARE @oldday DATETIME
DECLARE @newday DATETIME
--SET @newday = @firstDayOfYear
DECLARE @tempmoney int
SET @tempmoney =0;
DECLARE @i int;
DECLARE @oldsalary money
DECLARE @maxrownum int
DECLARE @hasChange bit
DECLARE @hasOldRate bit
DECLARE @currRate money
			
IF(NOT EXISTS (SELECT * FROM dbo.NhanVien WHERE dbo.NhanVien.MaNhanVien = @id and NhanVien.TinhTrang = 1))
	BEGIN 
			raiserror('Not exist Employee',16,1) 
			rollback tran
			return
	END
ELSE
	BEGIN 

		SET @currRate = (SELECT NhanVien.Luong FROM NhanVien WHERE NhanVien.MaNhanVien = @id)

		
		IF(EXISTS (SELECT * FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id)))
			SET @hasChange = 1
		ELSE 
			SET @hasChange = 0

		IF(EXISTS (SELECT * FROM dbo.f_OldRate(@firstDay,@lastDay,@id)))
			SET @hasOldRate = 1
		ELSE 
			SET @hasOldRate = 0

		WAITFOR DELAY '0:00:05'

		SET @maxrownum =  (SELECT MAX(temp.row_num) FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as temp)
		
				--Change salary rate in period
				IF(@hasChange >= 1 AND @hasOldRate >= 1)
					BEGIN 
						IF(@maxrownum < 2)
			
							BEGIN
								 SET @tempmoney = (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,@firstDay,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,@firstDay,newrate.NgayThayDoi)%7)))*8 + newrate.Luong*(((DATEDIFF(day,newrate.NgayThayDoi,@lastDay)/7)*5 + DATEDIFF(day,newrate.NgayThayDoi,@lastDay)%7)) *8)
								 FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_OldRate(@firstDay,@lastDay,@id) as oldrate)
							END
						ELSE
							BEGIN

								--salary from last year
					

								SET @tempmoney = @tempmoney + 
									(SELECT SUM(oldrate.Luong*(((DATEDIFF(day,@firstDay,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,@firstDay,newrate.NgayThayDoi)%7)))*8) 
									FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_OldRate(@firstDay,@lastDay,@id) as oldrate
									WHERE newrate.row_num = @maxrownum);

								SET @oldday = (SELECT temp.NgayThayDoi FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) temp WHERE temp.row_num = @maxrownum);
						

								--change in year
								SET @i = @maxrownum
								WHILE(@i > 1)
								BEGIN
									SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*((DATEDIFF(day,@oldday,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,@oldday,newrate.NgayThayDoi)%7))*8)
									FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
									WHERE newrate.row_num = @i - 1 AND oldrate.row_num = @i) 
						
									SET @oldday = (SELECT newrate.NgayThayDoi FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) newrate WHERE newrate.row_num = @i - 1) 
						
									SET @i = @i - 1
								END

								SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,@oldday,@lastDay)/7)*5 + (DATEDIFF(day,@oldday,@lastDay)%7)))*8)
								FROM  dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
								WHERE oldrate.row_num = @i) 

						END
					END
				--case just work this year			
				ELSE IF(@hasChange >= 1 AND @hasOldRate <= 0)
					BEGIN
						IF(@maxrownum < 2)	
						BEGIN
								 SET @tempmoney = (SELECT SUM(newrate.Luong*(((DATEDIFF(day,newrate.NgayThayDoi,@lastDay)/7)*5 + DATEDIFF(day,newrate.NgayThayDoi,@lastDay)%7)*8)) as TotalPay
								 FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate)
						END
						ELSE
						BEGIN
							 SET @i = @maxrownum
							 SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,oldrate.NgayThayDoi,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,oldrate.NgayThayDoi,newrate.NgayThayDoi)%7)))*8)
							 FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
							 WHERE	newrate.row_num = @i - 1 AND oldrate.row_num = @i				)
							 SET @i = @i - 1
							 WHILE(@i > 1)
								 BEGIN
										 SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,oldrate.NgayThayDoi,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,oldrate.NgayThayDoi,newrate.NgayThayDoi)%7)))*8)
										 FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
										 WHERE	newrate.row_num = @i - 1 AND oldrate.row_num = @i				)
										SET @i = @i - 1
								 END
							 --@i = 1	
							SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,oldrate.NgayThayDoi,@lastDay)/7)*5 + (DATEDIFF(day,oldrate.NgayThayDoi,@lastDay)%7)))*8)
							FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
							WHERE oldrate.row_num = @i)

						END
					END
					--case dont change rate
				ELSE IF(@hasChange <= 0 AND @hasOldRate >= 1)
					BEGIN
					SET @tempmoney = (SELECT SUM(oldrate.Luong*((DATEDIFF(day,@firstDay,@lastDay)/7)*5 + DATEDIFF(day,@firstDay,@lastDay)%7)*8) as TotalPay
						 FROM dbo.f_OldRate(@firstDay,@lastDay,@id) as oldrate)
					END




				
				INSERT INTO @temptable VALUES (@id,@tempmoney,@firstDay,@lastDay,@currRate)
			
				SELECT * FROM @temptable 

		COMMIT TRAN
	END
GO


---THONG KE CHI NHANH

CREATE PROC admin_ThongKeLuongChiNhanh(@firstDay DATE,@lastDay DATE,@chinhanh nvarchar(20))
AS
BEGIN TRAN
DECLARE @temptable TABLE
(
	id nvarchar(20),
	TotalPayment money,
	firstday DATETIME,
	lastday DATETIME,
	currentRate money

)
DECLARE @oldday DATETIME
DECLARE @newday DATETIME
--SET @newday = @firstDayOfYear
DECLARE @tempmoney int
SET @tempmoney = 0;
DECLARE @i int;
DECLARE @oldsalary money
DECLARE @maxrownum int
DECLARE @maxNhanVien int
DECLARE @currRate money
DECLARE @id nvarchar(20)
DECLARE @hasChange bit
DECLARE @hasOldRate bit

IF(NOT EXISTS(SELECT * FROM ChiNhanh WHERE ChiNhanh.MaChiNhanh = @chinhanh))
	begin
			raiserror('Not exist chi nhanh',16,1) 
			rollback tran
			return
	end
else
	BEGIN

		SET @maxNhanVien = (SELECT COUNT(*) FROM NhanVien WHERE NhanVien.ChiNhanh = @chinhanh and NhanVien.TinhTrang = 1)
		
			WHILE(@maxNhanVien >= 1)
			BEGIN
				SET @id =   (SELECT T.MaNhanVien
							FROM (
							SELECT ROW_NUMBER() OVER (ORDER BY MaNhanVien) AS RowNum,
							NhanVien.MaNhanVien
							FROM NhanVien
							WHERE NhanVien.ChiNhanh = @chinhanh and NhanVien.TinhTrang = 1
							) T
							WHERE RowNum IN (@maxNhanVien))
			WAITFOR DELAY '0:00:02'
		
				IF(EXISTS (SELECT * FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id)))
					SET @hasChange = 1
				ELSE 
					SET @hasChange = 0

				IF(EXISTS (SELECT * FROM dbo.f_OldRate(@firstDay,@lastDay,@id)))
					SET @hasOldRate = 1
				ELSE 
					SET @hasOldRate = 0			
		
		
				SET @maxrownum =  (SELECT MAX(temp.row_num) FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as temp)
		
					--Change salary rate in period
					IF(@hasChange >= 1 AND @hasOldRate >= 1)
						BEGIN 
						IF(@maxrownum < 2)
			
							BEGIN
							 SET @tempmoney = (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,@firstDay,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,@firstDay,newrate.NgayThayDoi)%7)))*8 + newrate.Luong*(((DATEDIFF(day,newrate.NgayThayDoi,@lastDay)/7)*5 + DATEDIFF(day,newrate.NgayThayDoi,@lastDay)%7)) *8)
							 FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_OldRate(@firstDay,@lastDay,@id) as oldrate)
							END
						ELSE
							BEGIN

								--salary from last year
					

								SET @tempmoney = @tempmoney + 
								(SELECT SUM(oldrate.Luong*(((DATEDIFF(day,@firstDay,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,@firstDay,newrate.NgayThayDoi)%7)))*8) 
								FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_OldRate(@firstDay,@lastDay,@id) as oldrate
								WHERE newrate.row_num = @maxrownum);

								SET @oldday = (SELECT temp.NgayThayDoi FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) temp WHERE temp.row_num = @maxrownum);


								--change in year
								SET @i = @maxrownum
								WHILE(@i > 1)
								BEGIN
									SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*((DATEDIFF(day,@oldday,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,@oldday,newrate.NgayThayDoi)%7))*8)
									FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
									WHERE newrate.row_num = @i - 1 AND oldrate.row_num = @i) 
						
									SET @oldday = (SELECT newrate.NgayThayDoi FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) newrate WHERE newrate.row_num = @i - 1) 
						
									SET @i = @i - 1
								END

								SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,@oldday,@lastDay)/7)*5 + (DATEDIFF(day,@oldday,@lastDay)%7)))*8)
								FROM  dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
								WHERE oldrate.row_num = @i) 

							END
						END
					--case just work this year			
					ELSE IF(@hasChange >= 1 AND @hasOldRate <= 0)
						BEGIN
							IF(@maxrownum < 2)	
							BEGIN
									 SET @tempmoney = (SELECT SUM(newrate.Luong*(((DATEDIFF(day,newrate.NgayThayDoi,@lastDay)/7)*5 + DATEDIFF(day,newrate.NgayThayDoi,@lastDay)%7)*8)) as TotalPay
									 FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate)
							END
							ELSE
							BEGIN
								 SET @i = @maxrownum
								 SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,oldrate.NgayThayDoi,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,oldrate.NgayThayDoi,newrate.NgayThayDoi)%7)))*8)
								 FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
								 WHERE	newrate.row_num = @i - 1 AND oldrate.row_num = @i				)
								 SET @i = @i - 1
								 WHILE(@i > 1)
									 BEGIN
											 SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,oldrate.NgayThayDoi,newrate.NgayThayDoi)/7)*5 + (DATEDIFF(day,oldrate.NgayThayDoi,newrate.NgayThayDoi)%7)))*8)
											 FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as newrate, dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
											 WHERE	newrate.row_num = @i - 1 AND oldrate.row_num = @i				)
											SET @i = @i - 1
									 END
								 --@i = 1	
								SET @tempmoney = @tempmoney + (SELECT SUM(oldrate.Luong*(((DATEDIFF(day,oldrate.NgayThayDoi,@lastDay)/7)*5 + (DATEDIFF(day,oldrate.NgayThayDoi,@lastDay)%7)))*8)
								FROM dbo.f_changInPeriod(@firstDay,@lastDay,@id) as oldrate
								WHERE oldrate.row_num = @i)

							END
						END
						--case dont change rate
					ELSE IF(@hasChange <= 0 AND @hasOldRate >= 1)
						BEGIN
						SET @tempmoney = (SELECT SUM(oldrate.Luong*((DATEDIFF(day,@firstDay,@lastDay)/7)*5 + DATEDIFF(day,@firstDay,@lastDay)%7)*8) as TotalPay
							 FROM dbo.f_OldRate(@firstDay,@lastDay,@id) as oldrate)
						END





		
					SET @currRate = (SELECT NhanVien.Luong FROM NhanVien WHERE NhanVien.MaNhanVien = @id)
					INSERT INTO @temptable VALUES (@id,@tempmoney,@firstDay,@lastDay,@currRate)
					SET @tempmoney = 0
					SET @maxNhanVien = @maxNhanVien - 1
				END
		
				SELECT * FROM @temptable
		commit tran
	END
GO





--------------------------PROC Mẫu----------------------
create proc ThemNhaThue (@sophong smallint, @diachi nvarchar(100), @luotxem int, @ngaydang date, @ngayhethan date, @tienthue money, @nvquanly nvarchar(20), @chunha nvarchar(20), @loainha smallint)
as
begin tran
	begin try
		SET TRAN ISOLATION LEVEL READ UNCOMMITTED
		insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
		values (@sophong, @diachi, @luotxem, 1, @ngaydang, @ngayhethan, 0, @NVquanly, @chunha, @loainha)
		
		waitfor delay '0:00:05'
		declare @manha int
		SET @manha = (SELECT MAX(MaNha) FROM Nha)
		insert into [dbo].[NhaThue](MaNha,TienThue) values (@manha,@tienthue)
	end try
	begin catch
		DECLARE @ErrMsg VARCHAR(2000)
		SELECT @ErrMsg = N'Lỗi: ' + ERROR_MESSAGE()
		raiserror(@ErrMsg,16,1)
		rollback tran
		return
	end catch
commit tran
go