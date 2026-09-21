# Auth email templates

**Trạng thái:** `implemented`
**Cập nhật:** 2026-09-21

## Mục tiêu

Supabase Auth gửi hai email riêng: Confirm Sign Up và Reset Password. Cả hai
email chỉ hiển thị OTP 6 số, hướng dẫn người dùng quay lại ứng dụng MuseMend và
không có liên kết/callback web. Luồng này hoạt động trên thiết bị nhận email khác
với thiết bị đang chạy app, không phụ thuộc PKCE verifier hay click-tracking.

## Source và đồng bộ hosted

Source chuẩn được version-control tại:

- `supabase/templates/confirm-sign-up.html`
- `supabase/templates/reset-password.html`

Supabase Dashboard tại Authentication → Emails là nơi chạy template thực tế;
Vercel, Git deploy và Flutter build **không** tự đồng bộ template. Khi thay đổi:

1. Thay thế toàn bộ source của đúng loại template bằng file tương ứng.
2. Save changes, mở lại source/preview và xác minh body chỉ có một `<!doctype html>`.
3. Xác minh không còn `<a`, `href=`, `redirectTo` hay URL Vercel trong cả hai body.
4. Gửi email test mới. Email cũ không đại diện cho source mới.

Ngày 2026-09-21, source đã được làm sạch sau khi phát hiện hosted body từng bị
nối nhiều template lịch sử. Bản chuẩn hiện tại có duy nhất một khối HTML và không
đưa credential hay link vào email.

## Locale và nội dung

Client đưa `language_code` vào Auth metadata lúc sign-up. Template chọn `vi`,
`en`, `ja`, `fr`, `es`, `it`, `de`, `ko`, `pt`, `ms`, `id`, `th`; mã không hỗ trợ
fallback về tiếng Anh. Đặt lại mật khẩu không tạo metadata mới, nên dùng metadata
ngôn ngữ đã lưu của user. Hai template đều dùng `{{ .Token }}`; độ dài là 6 do
cấu hình Auth Email OTP length của project.

Subject, h1 và nội dung của Confirm Sign Up phải nói về xác nhận email. Reset
Password phải nói về mã đặt mật khẩu mới. Cả hai nói rõ mã dùng một lần, hết hạn
sau một giờ, và người dùng có thể bỏ qua email nếu không phải mình yêu cầu.

## Contract và bảo mật

- Flutter gọi `signUp` và `resetPasswordForEmail` không truyền `emailRedirectTo`
  hay `redirectTo`.
- App gửi email + mã thẳng tới `verifyOTP`: `OtpType.email` khi xác nhận, và
  `OtpType.recovery` khi reset.
- Recovery form chỉ mở khi Supabase trả recovery session; `updateUser` mới đổi
  mật khẩu thực sự.
- OTP không nằm trong URL, không ghi DB, persistent storage hoặc log. Mã dùng
  một lần, có hạn 3.600 giây; request mới làm mã cũ mất hiệu lực.
- API reset vẫn trả phản hồi UI chung để không tiết lộ email tồn tại hay không.
- Không commit SMTP key, token Supabase, email người dùng thật hoặc nội dung mail
  chứa credential.

## Tương thích và vận hành

Vercel callback portal còn tồn tại để tương thích liên kết lịch sử, nhưng không
phải destination của email mới. Vì vậy không cần thêm URL Vercel vào lời gọi Auth
mới. Nếu lỡ thấy email có URL/CTA, trước tiên kiểm tra source hosted trong
Supabase, không kết luận từ file repository.

## Kiểm thử và rollback

- Xác minh UI Auth settings: Email OTP Expiration là 3.600 giây và OTP length là 6.
- Với email test mới, kiểm tra không có CTA/link; copy mã vào app để xác nhận hoặc
  đổi mật khẩu, rồi đăng nhập lại bằng mật khẩu mới.
- Test mã sai, mã cũ sau request mới và mã quá hạn; cả ba phải bị từ chối.
- Rollback chỉ dùng khi cần: restore source template đã được duyệt, Save changes,
  rồi kiểm tra lại preview. Không vô hiệu hóa user hoặc sửa mật khẩu thay người dùng.

## Liên quan

- [Authentication client](../fe/authentication.md)
- [ADR-0005 — OTP email trong ứng dụng](../other/adr-0005-in-app-email-otp.md)
