use[QuanLyCongTy2020]
go

--TODO: Thêm delay vào các proc này nữa nha
----------------------------- THỌ -------------------------------------------------
-- hàm hỗ trợ
-- tự phát sinh mã
--@str đưa vào là NV nếu là nhân viên và tương tự cho các đối tượng khác
--@num là STT max của nhân viên(tương tự các đối tượng khác) trong bảng
--TODO: mày xóa hết mấy cái STT rồi thì hàm này còn xài được không ?
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
	select * from [dbo].[NhanVien]
	where TinhTrang=1
go

exec XemDanhSachNhanVien
 --giao tac them nhan vien
 --TODO: Thêm luôn vào cái LS trả lương (ngày thêm nhân viên thì có update lương mới của nó)
 --Bảng nhân viên vẫn có lương vì để khi admin cần vào coi xem ai nên update lương.
 go
create proc ThemNhanVien(@ten nvarchar(50),@diachi nvarchar(100), @gioitinh Nvarchar(1),@ngaysinh date,@luong money, @sdt nvarchar(20),@chinhanh Nvarchar(20))
as
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
	insert into AccountNhanVien (IDNhanVien,Password) values (@manv, @res)
	-- them vao lich su tra luong
	insert into LichSuTraLuong (MaNhanVien,NgayThayDoi,Luong) values (@manv,GETDATE(),@luong)
go

exec ThemNhanVien N'Nguyễn Tèo',N'Tp.HCM','M','2000-04-20',15.123,'01234567', 'CN10001'
go
select * from AccountNhanVien
go
--giao tac tim kiem nhan vien
create proc TimKiemNhanVien(@manhanvien nvarchar(20))
as
	select* from [dbo].[NhanVien]
	where MaNhanVien=@manhanvien
go
	exec TimKiemNhanVien 'NV10000'
go
--giao tac tang luong nhan vien
-- neu tang luong trong cung 1 ngay thif chi viec update lai luong
--NOTE: Ưng thì kiểm tra xem Mã NV có tồn tại không nữa.
create proc TangLuong(@manhanvien nvarchar(20),@luongmoi money)
as
	declare @ngay1 date=getdate()
	declare @ngay2 date=(select max(NgayThayDoi) from LichSuTraLuong where MaNhanVien=@manhanvien)
	if( @ngay1=@ngay2)
	begin
		 update LichSuTraLuong set Luong=@luongmoi where MaNhanVien=@manhanvien and NgayThayDoi=@ngay1
	end

		else insert into [dbo].[LichSuTraLuong](MaNhanVien,NgayThayDoi,Luong) values ( @manhanvien, GETDATE(),@luongmoi)
go

exec TangLuong 'NV10000',24.5234
select * from LichSuTraLuong

go

-- ngay tang luong gan nhat voi ngay nhap vao
create function NgayTangLuongGanNhat(@manhanvien nvarchar(20), @ngay date)
returns date as
begin
 return (select ls1.NgayThayDoi from LichSuTraLuong ls1 where @ngay>=ls1.NgayThayDoi and MaNhanVien=@manhanvien -- ngay thay doi luong gan nhat voi ngay dua vao
							and ls1.NgayThayDoi>=all (select ls2.NgayThayDoi from LichSuTraLuong ls2 
							where @ngay>=ls2.NgayThayDoi and MaNhanVien=@manhanvien))
end

go
-- tinh luong 1 ngay cua 1 nhan vien
--TODO: Nhân viên mới thêm vô cũng cần có lương chứ ?
create function TinhLuongMotNgay(@manhanvien nvarchar(20),@ngay date)
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
create function TinhLuongNhanVien(@manhanvien nvarchar(20),@ngaybatdau date, @ngayketthuc date)
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
		set @res=@res+ dbo.TinhLuongMotNgay(@manhanvien,@ngay1)
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
-- giao tac tinh luong cua 1 chi nhanh tu ngay bat dau den ngay ket thuc (cai nay bo k lam nua)
create function ThongKeLuong(@machinhanh nvarchar(20), @ngaybatdau date, @ngayketthuc date)
returns float
as
begin
	declare @res float=0
	declare @idmax int = (select MAX(MaNhanVien) from NhanVien where ChiNhanh=@machinhanh) 
	while(@idmax >=0)
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
create proc TimKiemKhachHang(@makhachhang nvarchar(20))
as
	select* from KhachHang where MaKhachHang=@makhachhang
go
--giao tac xem lich su thue
create proc XemLichSuthue(@makhachhang nvarchar(20))
as
	select kh.Ten, kh.SDT,qt.NhaThue,qt.NgayBatDau,qt.NgayKetThuc from KhachHang kh,QuaTrinhThue qt
	where qt.KhachHang=@makhachhang and qt.KhachHang=kh.MaKhachHang
go
--giao tac xem danh sach chu nha
create proc XemDanhSachChuNha
as
	select * from ChuNha
go
-- giao tac tim kiem chu nha
create proc TimKiemChuNha(@chunha nvarchar(20))
as
	select * from ChuNha where MaChuNha=@chunha
go
--giao tac xem lich su hoat dong cua chu nha
create proc XemLichSuHoatDongCuaChuNha(@chunha nvarchar(20))
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
create proc YeuCauNha(@khachhang nvarchar(20), @loainha smallint)
as
	insert into YeuCauKH(KhachHang,LoaiNha) values (@khachhang,@loainha)
go
-- giao tac doi mat kau
create proc DoiMatKhau_KH(@khachhang nvarchar(20),@mkcu nvarchar(100), @mkmoi nvarchar(100))
as
	if (@mkcu=(select Password from AccountKhachHang where IDKhachHang=@khachhang))
	begin
		update AccountKhachHang
		set Password = @mkmoi
	end
go
-----------------------------------------------TRÂM------------------------------------------------------------------
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
create proc SuaTTN_LuotXem (@manha int, @luotxem int)
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
create proc ThemNhaThue (@sophong smallint, @diachi nvarchar(100), @luotxem int, @ngaydang date, @ngayhethan date, @tienthue money, @nvquanly nvarchar(20), @chunha nvarchar(20), @loainha smallint)
as
begin
	insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
	values (@sophong, @diachi, @luotxem, 0, @ngaydang, @ngayhethan, 1, @NVquanly, @chunha, @loainha)
	insert into [dbo].[NhaThue](TienThue)
	values (@tienthue)
end

-- nhà bán
create proc ThemNhaBan (@sophong smallint, @diachi nvarchar(100), @luotxem int, @ngaydang date, @ngayhethan date, @giaban money, @nvquanly nvarchar(20), @chunha nvarchar(20), @loainha smallint)
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
create proc ThemDanhGia (@khachhang nvarchar(20), @nha int, @ngayxem date, @nhanxet text)
as
begin
	insert into [dbo].[XemNha](KhachHang, Nha, NgayXem, NhanXet)
	values (@khachhang, @nha, @ngayxem, @nhanxet)
end

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
begin
	insert into [dbo].[YeuCauKH](KhachHang, LoaiNha)
	values (@khachhang, @loainha) 
end

-- Thêm hợp đồng
create proc ThemHopDong (@khachhang nvarchar(20), @nhathue int, @ngaybatdau date )
as
begin
	insert into [dbo].[QuaTrinhThue](KhachHang, NhaThue, NgayBatDau)
	values (@khachhang, @nhathue, @ngaybatdau) 
end

-- Kết thúc hợp đồng
create proc KetThucHopDong (@khachhang nvarchar(20), @nhathue int, @ngaybatdau date, @ngayketthuc date)
as
begin
	update [dbo].[QuaTrinhThue] set NgayKetThuc= @ngayketthuc
	where KhachHang= @khachhang and NhaThue= @nhathue and NgayBatDau= @ngaybatdau
end

-- Thêm khách hàng
create proc ThemKhachHang (@ten nvarchar(100), @diachi nvarchar(100), @sdt nvarchar(10), @chinhanhquanly nvarchar(20))
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
create proc ThemChuNha (@tenchunha nvarchar(100), @tinhtrang bit, @diachi nvarchar(100), @loaichunha bit, @sdt nvarchar(10))
as
begin
	insert into [dbo].[ChuNha](TenChuNha, TinhTrang, DiaChi, LoaiChuNha, SDT)
	values (@tenchunha, @tinhtrang, @diachi, @loaichunha, @sdt)
end

-- Cập nhật mật khẩu
create proc DoiMatKhau_NV(@idnhanvien nvarchar(20), @matkhaucu nvarchar(100), @matkhaumoi nvarchar(100))
as
	if (@matkhaucu=(select Password from AccountNhanVien where IDNhanVien= @idnhanvien))
	begin
		update AccountNhanVien with(updlock)
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
use QuanLyCongTy2020
go
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
alter proc Them_nha (@sophong smallint,@diachi nvarchar(100), @soluotxem tinyint,@ngaydang date, @ngayhethang date,@kieunha bit,@loainha int,@nvql nvarchar(20),@machunha nvarchar(20))
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
alter proc Them_nhathue(@sophong smallint,@diachi nvarchar(100), @soluotxem tinyint,@ngaydang date, @ngayhethang date,@giathue money,@loainha int,@nvql varchar(20),@machunha varchar(20))
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
alter proc Them_nhaban(@sophong smallint,@diachi nvarchar(100), @soluotxem tinyint,@ngaydang date, @ngayhethang date,@giaban money,@yeucau text,@loainha int,@nvql varchar(20),@machunha varchar(20))
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
alter proc TimNha(@manha int,@machunha nvarchar(20))
as
begin tran
	set tran isolation level Read committed
	select Nha.MaNha,Nha.DiaChi,QuaTrinhThue.KhachHang,QuaTrinhThue.NgayBatDau,QuaTrinhThue.NgayKetThuc from Nha,QuaTrinhThue where Nha.ChuNha=@machunha and QuaTrinhThue.NhaThue=Nha.MaNha and nha.MaNha=@manha
commit
go
exec TimNha 2,LL10021
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
