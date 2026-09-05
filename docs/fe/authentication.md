# Authentication client

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-05

## Mục tiêu và phạm vi

Lát cắt P0.1 hỗ trợ đăng ký, đăng nhập email/mật khẩu, khôi phục session qua SDK
và đăng xuất. Profile/settings bootstrap phía DB vẫn là nguồn sự thật.

## Luồng và trách nhiệm

`AuthRepository` là contract domain. `SupabaseAuthRepository` là adapter duy nhất
gọi Supabase Auth. `AuthController` điều phối thao tác và trạng thái async;
`SignInScreen` validate form. `authSessionProvider` điều khiển redirect
`/splash` → `/sign-in` hoặc `/reflect`.

Đăng ký gửi duy nhất metadata `display_name`; trigger DB tạo profile/settings và
travel progress. UI không gửi `user_id`, role hoặc quyền.

## Validation và lỗi

Email phải đúng định dạng, tên 2–60 ký tự, mật khẩu tối thiểu 8 ký tự. Lỗi Auth
được ánh xạ sang thông báo an toàn, không hiện stack trace/schema/token. Trạng thái
loading khóa submit lặp. Nếu project bật email confirmation, user được nhắc kiểm
tra email và vẫn ở màn hình auth cho tới khi có session.

## Bảo mật và riêng tư

SDK quản lý session; app không log token, mật khẩu hay email. Client chỉ dùng
publishable key. RLS vẫn là lớp phân quyền dữ liệu, không dựa vào việc ẩn UI.

## Kiểm thử và nghiệm thu

Widget test kiểm tra chuyển sign-up và validation. Integration/QA còn phải kiểm tra
sign-up thực tạo đủ row bootstrap, session restore, expired session, sign-out và
hai tài khoản không truy cập chéo.

## Tương thích, rollback và việc còn lại

Không có migration trong thay đổi client này. Revert adapter/UI không làm mất dữ
liệu Auth. Còn thiếu quên mật khẩu, xử lý account-disabled chi tiết, deep link xác
nhận email và integration test trên Supabase Dev.

## Liên quan

- [Application foundation](./application-foundation.md)
- [Profiles, settings và ownership](../db/profiles-settings.md)
- [Roadmap MVP](../other/mvp-roadmap.md)
