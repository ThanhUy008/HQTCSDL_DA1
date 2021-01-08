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


--go
-- Chức năng của Admin
-- giao tac doc danh sach nhan vien con lam viec trong cong ty
create proc XemDanhSachNhanVien(@chinhanh nvarchar(20))
as
begin tran
	begin try
	if(not exists (select * from ChiNhanh where MaChiNhanh=@chinhanh))
	begin
		raiserror('error: not exit ChiNhanh',16,1)
		rollback
	end
	else
	begin
		waitfor delay '0:00:05'
		select * from [dbo].[NhanVien]
		where TinhTrang=1 and ChiNhanh=@chinhanh
	end
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


 --giao tac them nhan vien
 --TODO: Thêm luôn vào cái LS trả lương (ngày thêm nhân viên thì có update lương mới của nó)
 --Bảng nhân viên vẫn có lương vì để khi admin cần vào coi xem ai nên update lương.
 go

 -- them nhan vien
create proc ThemNhanVien(@ten nvarchar(50),@diachi nvarchar(100), @gioitinh Nvarchar(1),@ngaysinh date,@luong money, @sdt nvarchar(20),@chinhanh Nvarchar(20))
as
begin tran
	begin try
	declare @num int =(select count(*) from NhanVien)
	if (@num is null) set @num=0
	declare @manv nvarchar(20)= dbo.ThemMaSo('NV',@num)
	if(exists(select * from NhanVien where NhanVien.MaNhanVien = @manv))
	begin
		raiserror('Employee already exists',16,1) 
		rollback
	end
	else
	begin
	insert into [dbo].[NhanVien](MaNhanVien,Ten,DiaChi,GioiTinh,NgaySinh,TinhTrang,Luong,SDT,ChiNhanh)
	values (@manv,@ten,@diachi,@gioitinh,@ngaysinh,1,@luong,@sdt,@chinhanh)
	-- moi lan them nhan vien thif csdl tu them vao 1 tai khoan cho nhan vien do
	--TODO : password để auto là 123456789, nhân viên vô acc tự sửa
	insert into AccountNhanVien (IDNhanVien,Password) values (@manv, '123456789')
	-- them vao lich su tra luong
	waitfor delay '0:00:05'
	insert into LichSuTraLuong (MaNhanVien,NgayThayDoi,Luong) values (@manv,GETDATE(),@luong)
	end
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



--giao tac tim kiem nhan vien
create proc TimKiemNhanVien(@manhanvien nvarchar(20),@chinhanh nvarchar(20))
as
begin tran
	begin try
	if (not exists(select * from NhanVien where MaNhanVien=@manhanvien and ChiNhanh=@chinhanh))
	begin
		raiserror('not exists Employee',16,1) 
		rollback
	end
	else
	begin
		select* from [dbo].[NhanVien]
		where MaNhanVien=@manhanvien and TinhTrang = 1
	end
	end try
	
	begin catch
		DECLARE @ErrMsg VARCHAR(2000)
		SELECT @ErrMsg = N'Error: ' + ERROR_MESSAGE()
		raiserror(@ErrMsg,16,1)
		rollback tran
		return
	end catch
commit tran
go


-- giao tac tang luong nhan vien
-- neu tang luong trong cung 1 ngay thif chi viec update lai luong
--NOTE: Ưng thì kiểm tra xem Mã NV có tồn tại không nữa.
create proc TangLuong(@manhanvien nvarchar(20),@luongmoi money,@chinhanh nvarchar(20))
as
begin tran
	begin try
	declare @ngay1 date=getdate()
	declare @ngay2 date=(select max(NgayThayDoi) from LichSuTraLuong where MaNhanVien=@manhanvien)
	if(not exists (Select * from NhanVien where NhanVien.MaNhanVien = @manhanvien and ChiNhanh=@chinhanh)) 
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
	end
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

-- sua luong nhan vien
create proc SuaLuong(@manv nvarchar(20),@chinhanh nvarchar(20),@luong money)
as
begin tran
	begin try
	if(not exists (select * from NhanVien where MaNhanVien=@manv and ChiNhanh=@chinhanh))
	begin
		raiserror('not exists Employee',16,1)
		rollback
	end
	else
	begin
		update LichSuTraLuong
		set Luong=@luong
		where MaNhanVien=@manv and NgayThayDoi =(select max(NgayThayDoi)from LichSuTraLuong where MaNhanVien=@manv)
		
		update NhanVien
		set Luong=@luong
		where MaNhanVien=@manv and ChiNhanh=@chinhanh
	end
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

--Xem lich su tra luong nhan vien
create proc XemLichSuTraLuongNhanVien(@chinhanh nvarchar(20),@manv nvarchar(20))
as
begin tran
	begin try
	if (not exists (select * from NhanVien where MaNhanVien=@manv and ChiNhanh=@chinhanh))
	begin
		raiserror('not exists employee',16,1)
		rollback
	end
	else
	begin
		select * from LichSuTraLuong where MaNhanVien=@manv
	end
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


--giao tac xem danh sach khach hang
alter proc XemDanhSachKhachHang(@chinhanh nvarchar(20))
as
begin tran
	begin try
	if(not exists(select* from ChiNhanh where MaChiNhanh=@chinhanh))
	begin
		raiserror('not exists ChiNhanh',16,1)
		rollback
	end
	else
		select* from KhachHang
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
-- giao tac tim kiem khach hang
alter proc TimKiemKhachHang(@chinhanh nvarchar(20),@makhachhang nvarchar(20))
as
begin tran
	begin try
	if(not exists(select * from ChiNhanh where MaChiNhanh=@chinhanh))
	begin
		raiserror('not exists ChiNhanh',16,1)
		rollback
	end
	else
		select* from KhachHang where MaKhachHang=@makhachhang
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

--giao tac xem lich su thue
alter proc XemLichSuthue(@makhachhang nvarchar(20), @chinhanh nvarchar(20))
as
begin tran
	begin try
	if( not exists (select * from KhachHang where MaKhachHang=@makhachhang and ChiNhanhQuanLy=@chinhanh))
	begin
		raiserror('not exists customer',16,1)
		rollback
	end
	else
	begin
		select kh.Ten, kh.SDT,qt.NhaThue,qt.NgayBatDau,qt.NgayKetThuc from KhachHang kh,QuaTrinhThue qt
		where qt.KhachHang=@makhachhang and qt.KhachHang=kh.MaKhachHang
	end
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
select cn.MaChuNha,cn.TenChuNha,cn.TinhTrang,cn.DiaChi,cn.LoaiChuNha,cn.SDT from ((ChuNha as cn left join Nha as n on cn.MaChuNha=n.ChuNha) left join NhanVien as nv on nv.MaNhanVien=n.NVQuanLy)
				left join ChiNhanh as chi on chi.MaChiNhanh=nv.ChiNhanh where chi.MaChiNhanh='CN10001'
go
--giao tac xem danh sach chu nha
create proc XemDanhSachChuNha
as
begin tran
	begin try
	if(not exists (select * from ChuNha))
	begin
		raiserror('not exists ChuNha',16,1)
		rollback
	end
	else
	begin
		select * from ChuNha
	end
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


-- giao tac tim kiem chu nha
create proc TimKiemChuNha(@chunha nvarchar(20))
as
begin tran
	begin try
	if( not exists (select * from ChuNha where MaChuNha=@chunha))
	begin
		raiserror('not exists ChuNha',16,1)
		rollback
	end
	else
	begin
		select * from ChuNha where MaChuNha=@chunha
	end
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


--giao tac xem lich su hoat dong cua chu nha
create proc XemLichSuHoatDongCuaChuNha(@chunha nvarchar(20))
as
begin tran
	begin try
	if(not exists( select * from ChuNha where MaChuNha=@chunha))
	begin
		raiserror('not exists ChuNha',16,1)
		rollback
	end
	else
	begin
		select n.MaNha,n.NgayDang,n.NgayHetHan from Nha n where n.ChuNha=@chunha and n.NgayDang is not null
	end
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



-- cac chuc nang cua user
-- giao tac tim nha
create proc TimNha_SoPhong(@sophong smallint, @kieunha bit)
as
begin tran
	begin try
	if ( not exists (select * from Nha where SoPhong=@sophong and KieuNha=@kieunha))
	begin
		raiserror('not exists Nha',16,1)
		rollback
	end
	else
	begin
	if (@kieunha=1)
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nb.GiaBan from Nha n, NhaBan nb where SoPhong=@sophong and KieuNha=@kieunha
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nt.TienThue from Nha n, NhaThue nt where SoPhong=@sophong and KieuNha=@kieunha
	end
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

--tim nha theo dia chic
create proc TimNha_DiaChi(@diachi nvarchar(100), @kieunha bit)
as
begin tran
	begin try
	if (not exists (select * from Nha where CHARINDEX(upper(@diachi),UPPER(DiaChi))>0 and KieuNha=@kieunha))
	begin
		raiserror('not exists Nha',16,1)
		rollback
	end
	else
	begin
	if (@kieunha=1)
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nb.GiaBan from Nha n, NhaBan nb where CHARINDEX(upper(@diachi),UPPER(DiaChi))>0 and KieuNha=@kieunha
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nt.TienThue from Nha n, NhaThue nt where CHARINDEX(upper(@diachi),UPPER(DiaChi))>0 and KieuNha=@kieunha
	end
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
-- tim nha theo du 3 tieu chi
create proc TimNha(@sophong smallint, @diachi nvarchar(100),@gia1 money,@gia2 money,@kieunha bit)
as
begin tran
	begin try
	if (@kieunha=1)
	if (not exists(select * from Nha n left join NhaBan nb on n.MaNha=nb.MaNha where CHARINDEX(upper(@diachi),UPPER(DiaChi))>0 and KieuNha=@kieunha
																									and SoPhong=@sophong and GiaBan>=@gia1 and GiaBan<=@gia2))
	begin
		raiserror('not exists NhaBan',16,1)
		rollback
	end
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nb.GiaBan from Nha n left join NhaBan nb on n.MaNha=nb.MaNha where CHARINDEX(upper(@diachi),UPPER(DiaChi))>0 and KieuNha=@kieunha
																									and SoPhong=@sophong and GiaBan>=@gia1 and GiaBan<=@gia2
	else
	if(not exists(select * from Nha n left join NhaThue nt on n.MaNha=nt.MaNha where CHARINDEX(upper(@diachi),UPPER(DiaChi))>0 and KieuNha=@kieunha
																									   and SoPhong=@sophong and TienThue>=@gia1 and TienThue <=@gia2))
	begin
		raiserror('not exists NhaThue',16,1)
		rollback
	end
	else
		select n.MaNha,n.ChuNha,n.LoaiNha,n.SoPhong,n.DiaChi, nt.TienThue from Nha n left join NhaThue nt on n.MaNha=nt.MaNha where CHARINDEX(upper(@diachi),UPPER(DiaChi))>0 and KieuNha=@kieunha
																									   and SoPhong=@sophong and TienThue>=@gia1 and TienThue <=@gia2
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

-- giao tac yeu cau nha
alter proc YeuCauNha(@khachhang nvarchar(20), @loainha smallint)
as
begin tran
	begin try
	if (not exists(select * from KhachHang where MaKhachHang=@khachhang))
	begin
		raiserror('not exists customer',16,1)
		rollback
	end
	else
	insert into YeuCauKH(KhachHang,LoaiNha) values (@khachhang,@loainha)
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
-- giao tac doi mat kau
alter proc DoiMatKhau_KH(@khachhang nvarchar(20), @mkmoi nvarchar(100))
as
begin tran
	begin try
	if(not exists(select* from KhachHang where MaKhachHang=@khachhang)) 
	begin
		raiserror('not exists customer',16,1)
		rollback
	end
	else
	begin
		update AccountKhachHang
		set Password = @mkmoi
		where IDKhachHang=@khachhang
	end
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

-----------------------------------------------TRÂM-------------------------------------------------------------------------------------------------
go
-- NHAN VIEN:

-- Xem danh sách nhà
create proc XemDanhSachNha
as
begin tran
	begin try
	if(not exists (select * from Nha))
	begin
		raiserror('Not exists house',16,1)
		rollback
	end
	else
	begin
		select * from [dbo].[Nha]
	end
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

-- Tìm nhà
create proc NV_TimNha(@manha int)
as
begin tran
	begin try
	if(not exists (select * from Nha where MaNha=@manha))
	begin
		raiserror('not exists house',16,1)
		rollback
	end
	else
	begin
	select* from [dbo].[Nha]
	where MaNha= @manha
	end
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

-- Sửa thông tin nhà

-- sửa lượt xem
create proc SuaTTN_LuotXem (@manha int, @luotxem int)
as
begin tran
	begin try
	if (not exists( select * from Nha where MaNha=@manha))
	begin
		raiserror('not exists housse',16,1)
		rollback
	end
	else
	begin
		update [dbo].[Nha] set LuotXem= @luotxem
		where MaNha= @manha
	end
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
-- sửa tình trạng
create proc SuaTTN_TinhTrang (@manha int, @tinhtrang int)
as
begin tran
	begin try
	if (not exists( select * from Nha where MaNha=@manha ))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		
		update [dbo].[Nha] set TinhTrang= @tinhtrang
		where MaNha= @manha
	end
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
-- sửa ngày đăng
create proc SuaTTN_NgayDang (@manha int, @ngaydang date)
as
begin tran
	begin try
	if (not exists( select * from Nha where MaNha=@manha))
	begin
			raiserror('not exists',16,1)
			rollback
	end
	else
	begin

		update [dbo].[Nha] set NgayDang= @ngaydang
		where MaNha= @manha
	end
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

-- sửa ngày hết hạn
create proc SuaTTN_NgayHetHan (@manha int, @ngayhethan date)
as
begin tran
	begin try
	if (not exists( select * from Nha where MaNha=@manha))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		update [dbo].[Nha] set NgayHetHan= @ngayhethan
		where MaNha= @manha
	end
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

-- sửa loại nhà
create proc SuaThongTinNha (@manha int, @loainha smallint)
as
begin tran
	begin try
	if (not exists( select * from Nha where MaNha=@manha))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		update [dbo].[Nha] set LoaiNha= @loainha
		where MaNha= @manha
	end
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

-- Xóa thông tin nhà
-- không xóa được vì có tham chiếu khóa ngoại từ các bảng khác đến bảng Nhà

-- Thêm nhà
-- tình trạng: 0: có sẵn, 1: đã cho thuê/ bán
-- kiểu nhà: 0: nhà bán, 1: nhà thuê
-- nhà thuê
create proc ThemNhaThue (@sophong smallint, @diachi nvarchar(100), @luotxem int, @ngaydang date, @ngayhethan date, @tienthue money, @nvquanly nvarchar(20), @chunha nvarchar(20), @loainha smallint)
as
begin tran
	begin try
	insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
	values (@sophong, @diachi, @luotxem, 0, @ngaydang, @ngayhethan, 1, @NVquanly, @chunha, @loainha)
	insert into [dbo].[NhaThue](TienThue)
	values (@tienthue)
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


-- nhà bán
create proc ThemNhaBan (@sophong smallint, @diachi nvarchar(100), @luotxem int, @ngaydang date, @ngayhethan date, @giaban money, @nvquanly nvarchar(20), @chunha nvarchar(20), @loainha smallint)
as
begin tran
	begin try
	insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
	values (@sophong, @diachi, @luotxem, 0, @ngaydang, @ngayhethan, 0, @NVquanly, @chunha, @loainha)
	insert into [dbo].[NhaBan](GiaBan)
	values (@giaban)
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

-- Thống kê nhà

-- theo phòng
create proc TimNhaTheoPhong(@sophong smallint)
as
begin tran
	begin try
	if (not exists(select * from Nha where SoPhong=@sophong))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		select* from [dbo].[Nha]
		where SoPhong= @sophong
	end
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
--theo địa chỉ
create proc TimNhaTheoDiaChi(@diachi nvarchar(100))
as
begin tran
	begin try
	if(not exists ( select * from Nha where CHARINDEX(upper(@diachi),UPPER(DiaChi))>0))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		select* from [dbo].[Nha]
		where CHARINDEX(UPPER(@diachi),upper(DiaChi))>0
	end
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
--theo giá từ X-> Y
-- nhà thuê
create proc TimNhaTheoGiaThue(@X money, @Y money)
as
begin tran
	begin try
	if(not exists ( select * from NhaThue where TienThue >= @X and TienThue<=@Y))
	begin
		raiserror('not exists',16,1)
		rollback
	end 
	else
	begin
	select* from [dbo].[Nha], [dbo].[NhaThue]
	where Nha.MaNha= NhaThue.MaNha and @X<= TienThue and TienThue<= @Y
	end
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
-- nhà bán
create proc TimNhaTheoGiaBan(@X money, @Y money)
as
begin tran
	begin try
	if ( not exists( select * from NhaBan where GiaBan>=@X and GiaBan<=@Y))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
	select* from [dbo].[Nha], [dbo].[NhaBan]
	where Nha.MaNha= NhaBan.MaNha and @X<= GiaBan and GiaBan<= @Y
	end
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
--theo cả 3
-- nhà thuê
create proc ThongKeNhaThue(@sophong smallint, @diachi nvarchar(100), @X money, @Y money)
as 
begin tran
	begin try
	if( not exists( select * from NhaThue as nt join Nha as n on nt.MaNha=n.MaNha where n.SoPhong=@sophong and CHARINDEX(UPPER(@diachi),upper(DiaChi))>0
					and TienThue>=@X and TienThue<=@Y))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
	select* from [dbo].[Nha], [dbo].[NhaThue]
	where SoPhong=@sophong and CHARINDEX(UPPER(@diachi),upper(DiaChi))>0 and Nha.MaNha= NhaThue.MaNha and @X<= TienThue and TienThue<= @Y
	end
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
-- nhà bán
create proc ThongKeNhaBan(@sophong smallint, @diachi nvarchar(100), @X money, @Y money)
as
begin tran
	begin try
	if( not exists ( select * from NhaBan as nb join Nha n on nb.MaNha=n.MaNha where n.SoPhong=@sophong
					and CHARINDEX(UPPER(@diachi),upper(DiaChi))>0 and GiaBan>=@X and GiaBan<=@Y))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
	select* from [dbo].[Nha], [dbo].[NhaBan]
	where SoPhong=@sophong and CHARINDEX(upper(@diachi),upper(DiaChi))>0 and Nha.MaNha= NhaBan.MaNha and @X<= GiaBan and GiaBan<= @Y
	end
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

-- Thêm đánh giá
create proc ThemDanhGia (@khachhang nvarchar(20), @nha int, @ngayxem date, @nhanxet text)
as
begin tran
	begin try
	if (not exists( select * from Nha where MaNha=@nha) or not exists( select * from KhachHang where MaKhachHang=@khachhang))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		insert into [dbo].[XemNha](KhachHang, Nha, NgayXem, NhanXet)
		values (@khachhang, @nha, @ngayxem, @nhanxet)
	end
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
	begin try
	if (not exists( select * from KhachHang where MaKhachHang=@khachhang))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		insert into [dbo].[YeuCauKH](KhachHang, LoaiNha)
		values (@khachhang, @loainha) 
	end
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

-- Thêm hợp đồng
create proc ThemHopDong (@khachhang nvarchar(20), @nhathue int, @ngaybatdau date )
as
begin tran
	begin try
	if (not exists( select * from KhachHang where MaKhachHang=@khachhang))
	begin
		raiserror('not exists',16,1)
		rollback
	
	end
	else
	begin
		insert into [dbo].[QuaTrinhThue](KhachHang, NhaThue, NgayBatDau)
		values (@khachhang, @nhathue, @ngaybatdau) 
	end
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

-- Kết thúc hợp đồng
create proc KetThucHopDong (@khachhang nvarchar(20), @nhathue int, @ngaybatdau date, @ngayketthuc date)
as
begin tran
	begin try
	if (not exists( select * from KhachHang where MaKhachHang=@khachhang))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		update [dbo].[QuaTrinhThue] set NgayKetThuc= @ngayketthuc
		where KhachHang= @khachhang and NhaThue= @nhathue and NgayBatDau= @ngaybatdau
	end
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
-- Thêm khách hàng
create proc ThemKhachHang (@ten nvarchar(100), @diachi nvarchar(100), @sdt nvarchar(10), @chinhanhquanly nvarchar(20))
as
begin tran
	begin try
	declare @num int=(select COUNT(*) from KhachHang)
	if(@num is null) set @num=0
	declare @makh nvarchar(20)=dbo.ThemMaSo('KH',@num)
	if( not exists ( select * from KhachHang where MaKhachHang=@makh))
	begin
	raiserror('not exists',16,1)
	rollback
	end
	else
	begin
	insert into [dbo].[KhachHang](MaKhachHang, Ten,DiaChi, SDT, ChiNhanhQuanLy)
	values (@makh,@ten, @diachi, @sdt, @chinhanhquanly)
	end
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

-- Xem danh sách chủ nhà
-- giống admin

-- Sửa thông tin chủ nhà
-- sửa tên
create proc SuaTenChuNha(@machunha nvarchar(20), @ten nvarchar(100))
as
begin tran
	begin try
	if(not exists(select* from ChuNha where MaChuNha=@machunha))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		update [dbo].[ChuNha] set TenChuNha = @ten
		where MaChuNha = @machunha
	end
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
-- sửa địa chỉ
create proc SuaDiaChiChuNha(@machunha nvarchar(20), @diachi nvarchar(100))
as
begin tran
	begin try
	if(not exists(select* from ChuNha where MaChuNha=@machunha))
	begin
		raiserror('not exists',16,1)
		rollback
	end
	else
	begin
		update [dbo].[ChuNha] set DiaChi = @diachi
		where MaChuNha = @machunha
	end
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
-- sửa SDT
create proc SuaSDTChuNha(@machunha nvarchar(20), @sdt nvarchar(10))
as
begin tran
	begin try
	if(not exists(select* from ChuNha where MaChuNha=@machunha))
	begin
	raiserror('not exists',16,1)
	rollback
	end
	else
	begin
	update [dbo].[ChuNha] set SDT= @sdt
	where MaChuNha = @machunha
	end
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

-- Tìm kiếm chủ nhà
-- giống admin

-- Thêm chủ nhà
create proc ThemChuNha (@tenchunha nvarchar(100), @tinhtrang bit, @diachi nvarchar(100), @loaichunha bit, @sdt nvarchar(10))
as
begin tran
	begin try
	declare @num int=(select COUNT(*) from KhachHang)
	if(@num is null) set @num=0
	declare @macn nvarchar(20)=dbo.ThemMaSo('LL',@num)
	if (exists(select * from ChuNha where MaChuNha=@macn))
	begin
		raiserror ('exists employee',16,1)
		rollback
	end
	else
	begin
	insert into [dbo].[ChuNha](MaChuNha,TenChuNha, TinhTrang, DiaChi, LoaiChuNha, SDT)
	values (@tenchunha, @tinhtrang, @diachi, @loaichunha, @sdt)
	end
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

-- Cập nhật mật khẩu
create proc DoiMatKhau_NV(@idnhanvien nvarchar(20), @matkhaucu nvarchar(100), @matkhaumoi nvarchar(100))
as
begin tran
	begin try
	if(exists(select* from NhanVien where MaNhanVien=@idnhanvien)) 
	begin
	if (@matkhaucu=(select Password from AccountNhanVien where IDNhanVien= @idnhanvien))
	begin
		update AccountNhanVien with(updlock)
		set Password = @matkhaumoi
	end
	end
	else
	begin
	raiserror('not exists employee',16,1)
	rollback
	end
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


go
-----------------------------------------------VI---------------------------------------------------------------------------------------------------------
-- Sua thong tin nhan vien
-- sua ten nhan vien
create proc SuaTenNhanVien(@manv nvarchar(20), @ten nvarchar(50))
as
begin tran
	begin try
	if(not exists(select * from NhanVien where MaNhanVien=@manv))
	begin
		raiserror('not exists Employee',16,1)
		rollback

	end
	else
	begin
		update [dbo].[NhanVien] set Ten = @ten
		where MaNhanVien= @manv
	end
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

-- sua dia chi nhan vien
create proc SuaDiaChiNhanVien(@manv nvarchar(20), @diachi nvarchar(50))
as
begin tran
	begin try
	if(not exists(select * from NhanVien where MaNhanVien=@manv))
	begin
		raiserror('not exists Employee',16,1)
		rollback
	end
	else
	begin
		update [dbo].[NhanVien] set DiaChi = @diachi
		where MaNhanVien= @manv
	end
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

--sua gioi tinh nhan vien
create proc SuaGioiTinhNhanVien(@manv nvarchar(20),  @gioitinh nchar(1))
as
begin tran
	begin try
	if(not exists(select * from NhanVien where MaNhanVien=@manv))
	begin
	raiserror('not exists Employee',16,1)
	rollback
	end
	else
	begin
		update [dbo].[NhanVien] set GioiTinh = @gioitinh
		where MaNhanVien= @manv
	end
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

-- sua ngay sinh nhan vien
create proc SuaNgaySinhNhanVien(@manv nvarchar(20), @ngaysinh date)
as
begin tran
	begin try
	if(not exists(select * from NhanVien where MaNhanVien=@manv))
	begin
		raiserror('not exists Employee',16,1)
		rollback
	end
	else
	begin
		update [dbo].[NhanVien] set NgaySinh = @ngaysinh
		where MaNhanVien= @manv
	end
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

select * from NhanVien
-- sua tinh trang nhan vien
create proc SuaTinhTrangNhanVien(@manv nvarchar(20), @tinhtrang bit)
as
begin tran
	begin try
	if(not exists(select * from NhanVien where MaNhanVien=@manv))
	begin
		raiserror('not exists Employee',16,1)
		rollback
	end
	else
	begin
		update [dbo].[NhanVien] set TinhTrang=@tinhtrang
		where MaNhanVien= @manv
	end
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

-- sua so dien thoai nhan vien
create proc SuaSDTNhanVien(@manv nvarchar(20), @sdt nvarchar( 20))
as
begin tran
	begin try
	if(not exists(select * from NhanVien where MaNhanVien=@manv))
	begin
		raiserror('not exists Employee',16,1)
		rollback
	end
	else
	begin
		update [dbo].[NhanVien] set SDT = @sdt
		where MaNhanVien= @manv
	end
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

-- Sua thong tin khach hang
--sua ten khach hang
alter proc SuaTenKhachHang(@makh nvarchar(20), @ten nvarchar(50))
as
begin tran
	begin try
	if(not exists(select* from KhachHang where MaKhachHang=@makh))
	begin
		raiserror('not exists customer',16,1)
		rollback
	end
	else
	begin
		update [dbo].[KhachHang] set Ten = @ten
		where MaKhachHang = @makh
	end
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

--sua dia chi khach hang
create proc SuaDiaChiKhachHang(@makh nvarchar(20), @diachi nvarchar(50))
as
begin tran
	begin try
	if(not exists(select* from KhachHang where MaKhachHang=@makh))
	begin
		raiserror('not exists customer',16,1)
		rollback
	end
	else
	begin
		update [dbo].[KhachHang] set DiaChi = @diachi
		where MaKhachHang = @makh
	end
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

--sua so dien thoai khach hang
create proc SuaSDTKhachHang(@makh nvarchar(20),@sdt nvarchar(20))
as
	begin tran
	begin try
	if(not exists(select* from KhachHang where MaKhachHang=@makh))
	begin
	raiserror('not exists customer',16,1)
	rollback
	end
	else
	begin
	update [dbo].[KhachHang] set SDT = @sdt
	where MaKhachHang = @makh
	end
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

--sua chi nhanh quan ly khach hang
create proc SuaChiNhanhQLKhachHang(@makh nvarchar(20), @chinhanhql smallint)
as
begin tran
	begin tran
	begin try
	if(not exists(select* from KhachHang where MaKhachHang=@makh))
	begin
	raiserror('not exists customer',16,1)
	rollback
	end
	else
	begin
	update [dbo].[KhachHang] set ChiNhanhQuanLy = @chinhanhql
	where MaKhachHang = @makh
	end
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

-----------------------------------------------THẮNG-----------------------------------------------------------------

GO
--Hàm hỗ trợ thêm nhà thuê
--@sophong số phòng của nhà,
--@diachi địa chỉ nhà,
--@soluotxem số lượt xem nhà,
--@ngaydang ngày đăng nhà,
--@ngayhethang ngày hết hạng đăng nhà,
--@tienthue giá tiền thuê nhà,
--@nvquanly mã nhân viên quản lý nhà,
--@chunha mã chủ nhà
--@loainha loại nhà.
--TODO Thêm nhà thuê vào data.
GO
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
           -- smallint
go
--Hàm hỗ trợ thêm nhà Bán
--@sophong số phòng của nhà,
--@diachi địa chỉ nhà,
--@soluotxem số lượt xem nhà,
--@ngaydang ngày đăng nhà,
--@ngayhethang ngày hết hạng đăng nhà,
--@giaban giá tiền bán nhà,
--@nvqquanly mã nhân viên quản lý nhà,
--@yeucau điều kiện bán nhà,
--@loainha loại nhà,
--@chunha mã chủ nhà .
--TODO Thêm nhà bán vào data.
go
create proc ThemNhaBan (@sophong smallint, @diachi nvarchar(100), @luotxem int, @ngaydang date, @ngayhethan date, @giaban money, @nvquanly nvarchar(20),@yeucau TEXT ,@chunha nvarchar(20), @loainha smallint)
as
begin tran
	begin try
		SET TRAN ISOLATION LEVEL READ UNCOMMITTED
		insert into [dbo].[Nha](SoPhong, DiaChi, LuotXem, TinhTrang, NgayDang, NgayHetHan, KieuNha, NVQuanLy, ChuNha, LoaiNha)
		values (@sophong, @diachi, @luotxem, 1, @ngaydang, @ngayhethan, 0, @NVquanly, @chunha, @loainha)
		
		waitfor delay '0:00:05'
		declare @manha int
		SET @manha = (SELECT MAX(MaNha) FROM Nha)
		insert into [dbo].[NhaBan]
		(
		    [MaNha],
		    [GiaBan],
		    [DieuKien]
		)
		VALUES
		(   @manha,    -- MaNha - int
		    @giaban, -- GiaBan - money
		    @yeucau    -- DieuKien - text
			)

	end try
	begin catch
		DECLARE @ErrMsg VARCHAR(2000)
		SELECT @ErrMsg = N'Lỗi: ' + ERROR_MESSAGE()
		raiserror(@ErrMsg,16,1)
		rollback tran
		return
	end catch
commit TRAN
GO
EXEC dbo.ThemNhaBan @sophong = 1,               -- smallint
                    @diachi = N'Thon 2 thang hung chu prong gia lai',              -- nvarchar(100)
                    @luotxem = 1,               -- int
                    @ngaydang = '2020-12-31',   -- date
                    @ngayhethan = '2021-12-31', -- date
                    @giaban = 10000,             -- money
                    @nvquanly = N'NV10000',            -- nvarchar(20)
                    @yeucau = '',               -- text
                    @chunha = N'LL10000',              -- nvarchar(20)
                    @loainha = 4                -- smallint
--
GO
--Hàm tìm nhà của chủ nhà
--@manha mã nhà cần tìm,
--@machunha mã chủ nhà của nhà cần tìm
--TODO Tìm nhà cho chủ nhà.
DROP PROC ChuNhaTimNha
go
create proc ChuNhaTimNha(@manha int,@machunha nvarchar(20))
as
begin TRAN
	SET tran isolation level Read committed
	IF(NOT EXISTS(SELECT*FROM dbo.Nha WHERE MaNha=@manha))
		BEGIN
			RAISERROR('Not exits Nha',16,1)
			ROLLBACK TRAN
			RETURN
			END
    ELSE
		BEGIN	
		waitfor delay '0:00:05'
			select Nha.MaNha,Nha.DiaChi,QuaTrinhThue.KhachHang,QuaTrinhThue.NgayBatDau,QuaTrinhThue.NgayKetThuc from Nha,QuaTrinhThue where (Nha.ChuNha=@machunha and Nha.MaNha=@manha) and QuaTrinhThue.NhaThue=Nha.MaNha
		END
commit
go

--Hàm xem danh sách nhà của chủ nhà
--@machunha mã chủ nhà
--TODO: Xem danh sách tất cả nhà của chủ nhà

go
create proc XemDanhSachNha(@machunha nvarchar(20))
as
begin tran
	set tran isolation level Read committed 
	SET TRAN ISOLATION LEVEL READ COMMITTED
	IF(NOT EXISTS(SELECT*FROM dbo.Nha WHERE dbo.Nha.ChuNha=@machunha))
		BEGIN
			RAISERROR('Not exit Nha',16,1)
			ROLLBACK TRAN
			RETURN
		END
	ELSE
	waitfor delay '0:00:05'
		SELECT * FROM  dbo.Nha WHERE nha.ChuNha=@machunha
commit
go
-- nvarchar(20)
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

exec admin_TinhLuongNhanVien 'NV10001', '2020-01-19', '2020-02-19'
go
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



select * from ChiNhanh
select * from LichSuTraLuong