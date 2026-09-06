# Profile overview client

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-05

## Mục tiêu và phạm vi

Xác nhận bootstrap sau Auth bằng cách đọc profile/settings của session hiện tại,
hiển thị và chỉnh sửa tên user, tên Mây, theme, âm thanh và notification. Profile
cũng chứa inbox, thông tin privacy/giới hạn, sign-out và request account deletion.

## Thiết kế và contract

`ProfileRepository` trả `AccountOverview`. Adapter Supabase đọc song song một row
`profiles` và một row `user_settings`; RLS xác định owner nên client không gửi
`user_id`. DTO tách tên cột DB khỏi presentation. `accountOverviewProvider` quản lý
loading/error/retry và mutation. Theme controller tải lại mode theo authenticated
session để áp dụng `system`/`light`/`dark` sau restart.

Update dùng hai statement chỉ chứa các cột client được grant. Settings được lưu
trước profile; nếu request thứ hai lỗi, provider reload để không giả định cả hai
đã thành công. Xóa tài khoản chỉ gọi `request_account_deletion()`; client không có
service role và không gọi Admin Auth API.

## Quy tắc, lỗi và bảo mật

Thiếu một trong hai row bootstrap được coi là lỗi dữ liệu và hiện retry, không tạo
row từ client. Email lấy từ Auth session, không từ bảng public. UI không hiển thị
account status nội bộ, token hay ID. Form giới hạn tên hiển thị 80, tên Mây 40 ký
tự. Tắt notification hủy local schedules; bật lại chỉ xin quyền khi user lưu thư.

Xóa tài khoản là thao tác không thể khôi phục trong contract hiện tại, vì vậy dialog
yêu cầu nhập chính xác `XÓA`. Sau khi RPC chấp nhận, app hủy reminder cục bộ và
sign-out; worker xử lý Storage/Auth idempotently ở backend.

## Kiểm thử và nghiệm thu

Unit test kiểm tra mapping profile/settings. DB integration test xác nhận các cột
được cấp có thể sửa, `account_status` bị chặn, deletion request được tạo và profile
bị vô hiệu hóa trong transaction rollback. Android E2E đã xác nhận update tên Mây,
theme dark áp dụng tức thời và khôi phục sau restart; dialog xóa bị khóa trước khi
nhập xác nhận. Không gọi xóa thật trên tài khoản QA từ client.

## Tương thích, rollback và việc còn lại

Không đổi schema. Privacy/terms trong app hiện là bản tóm tắt MVP, chưa thay cho văn
bản pháp lý được review và URL công khai cần cho store. Biometric lock và avatar
vẫn ngoài lát cắt hiện tại. iOS theme/notification/account UI cần nghiệm thu trên
thiết bị thật.

## Liên quan

- [DB profiles/settings](../db/profiles-settings.md)
- [Authentication](./authentication.md)
- [Roadmap MVP](../other/mvp-roadmap.md)
- [Privacy và safety](../other/privacy-safety.md)
