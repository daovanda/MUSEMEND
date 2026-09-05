# Profile overview client

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-05

## Mục tiêu và phạm vi

Xác nhận bootstrap sau Auth bằng cách đọc profile/settings của session hiện tại và
hiển thị tên user, email session, tên Mây cùng trạng thái notification. Chỉnh sửa
settings và xóa tài khoản nằm ở P0.7.

## Thiết kế và contract

`ProfileRepository` trả `AccountOverview`. Adapter Supabase đọc song song một row
`profiles` và một row `user_settings`; RLS xác định owner nên client không gửi
`user_id`. DTO tách tên cột DB khỏi presentation. `accountOverviewProvider` quản lý
loading/error/retry và màn Profile vẫn cho đăng xuất khi tải hồ sơ lỗi.

## Quy tắc, lỗi và bảo mật

Thiếu một trong hai row bootstrap được coi là lỗi dữ liệu và hiện retry, không tạo
row từ client. Email lấy từ Auth session, không từ bảng public. UI không hiển thị
account status nội bộ, token hay ID. Client hiện không có hành động sửa nên không
mở rộng quyền cột.

## Kiểm thử và nghiệm thu

Unit test kiểm tra mapping profile/settings. Cần integration test sign-up mới tạo
đủ `profiles`, `user_settings`, `travel_progress`; session restore và hai tài khoản
không đọc chéo. QA kiểm tra Profile loading/error và sign-out xóa UI authenticated.

## Tương thích, rollback và việc còn lại

Không đổi schema. Khi bổ sung edit, chỉ dùng các cột được cấp trong tài liệu DB và
phải xử lý cập nhật từng miền rõ ràng. Còn thiếu form chỉnh sửa, theme runtime,
notification permission, biometric lock và request account deletion.

## Liên quan

- [DB profiles/settings](../db/profiles-settings.md)
- [Authentication](./authentication.md)
- [Roadmap MVP](../other/mvp-roadmap.md)
