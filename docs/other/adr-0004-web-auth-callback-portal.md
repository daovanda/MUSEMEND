# ADR-0004 — Web chỉ phục vụ callback Auth

**Trạng thái:** accepted, implementation in-progress
**Cập nhật:** 2026-09-19

## Bối cảnh

MuseMend là ứng dụng di động. Link trong email vẫn cần mở được trên thiết bị có
trình duyệt, kể cả khi app native chưa cài hoặc người dùng đang dùng máy tính.
Website public hiện đang hiển thị form đăng nhập app, nhưng đây không phải nơi
người dùng sử dụng các chức năng thường ngày.

## Quyết định

Flutter Web public là auth callback portal, không phải web client đầy đủ. Portal
chỉ có landing trung tính, trang xác nhận email thành công/lỗi và form đổi mật
khẩu thành công/lỗi. Web không hiển thị sign-in, onboarding, hồ sơ hoặc dữ liệu
nghiệp vụ. App Android/iOS tiếp tục sở hữu các luồng đó.

Đăng ký truyền `emailRedirectTo` tới
`https://musemend-app.vercel.app/email-confirmed`; recovery luôn truyền
`https://musemend-app.vercel.app/reset-password`. Vercel rewrite hai đường dẫn
về Flutter `index.html`, Flutter dùng path URL strategy, và Supabase URL
allow-list phải khai báo đúng cả hai callback. Callback thành công phải có
session do Supabase Auth khôi phục; không có session thì giao diện báo link lỗi
hoặc hết hạn, không tự nhận thành công.

## Hệ quả

- Không cần đăng nhập trong trình duyệt để dùng app; hoàn tất xác nhận hoặc đổi
  mật khẩu thì người dùng quay lại ứng dụng MuseMend.
- Vercel cần deploy phiên bản Flutter mới cùng rewrite cho deep link.
- Supabase Auth Redirect URLs cần thêm `/email-confirmed` và giữ
  `/reset-password`; thay đổi cấu hình hosted phải được xác minh riêng.
- Email links tiếp tục dùng token một lần của Supabase; không đưa token vào app
  logs, database nghiệp vụ hoặc tài liệu.
- Các test web cần xác minh không có sign-in route, callback thành công/lỗi và
  reset form chỉ xuất hiện khi có recovery session.

## Rollout và rollback

Triển khai source và Vercel rewrite cùng lúc sau khi URL allow-list đã sẵn sàng.
Trước khi phát hành, QA bằng email thử mới cho cả xác nhận lẫn recovery; không
dùng lại link đã mở. Khi rollback, đưa Supabase redirect về phiên bản web trước
hoặc giữ callback pages tương thích; không vô hiệu hóa tài khoản hoặc đổi mật
khẩu người dùng.
