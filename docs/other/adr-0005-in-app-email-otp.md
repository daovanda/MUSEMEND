# ADR-0005 — OTP email trong ứng dụng

**Trạng thái:** accepted
**Cập nhật:** 2026-09-21

## Bối cảnh

MuseMend là ứng dụng di động, nhưng ADR-0004 dùng Vercel callback portal cho
xác nhận email và đặt lại mật khẩu. CTA qua email bị mail client/click tracking
đi qua nhiều redirect và tạo trải nghiệm chuyển sang web không cần thiết. Luồng
đó cũng khiến QA khó phân biệt link mới, link đã bị scanner mở và callback cũ.

Supabase Auth đã cung cấp email OTP một lần, hết hạn và có `verifyOTP` cho cả
xác nhận email và recovery. App đã có adapter và màn nhập OTP để sử dụng cơ chế
này một cách an toàn.

## Quyết định

Email Confirm Sign Up và Reset Password chỉ chứa OTP 6 số và nội dung đã bản địa
hóa; không có `<a>`, URL callback, `emailRedirectTo` hay `redirectTo` trong luồng
mới. App chuyển ngay vào `/confirm-email` hoặc `/reset-password` sau khi gửi
email và điền sẵn địa chỉ email:

```text
sign-up → gửi OTP email → /confirm-email → verifyOTP(email) → onboarding
forgot password → gửi OTP email → /reset-password → verifyOTP(recovery)
                → mật khẩu mới → updateUser → sign-in
```

OTP length là 6; TTL là 3.600 giây. Recovery form chỉ có sau recovery session từ
Supabase. Flutter Web callback portal vẫn giữ tạm thời cho token lịch sử nhưng
không phải đích của email mới. ADR-0004 bị thay thế.

## Hệ quả

- Người dùng luôn hoàn tất Auth trong app, kể cả khi đọc email trên thiết bị khác.
- Không phụ thuộc PKCE verifier hoặc click tracking trên URL callback.
- Template hosted Supabase là cấu hình vận hành phải đồng bộ thủ công từ source.
- Public web không còn là thành phần bắt buộc của luồng mới, nhưng có thể giữ
  cho tương thích cho đến khi callback lịch sử hết vòng đời.

## Bảo mật và rollback

Không log/lưu OTP, token hay mật khẩu. OTP dùng một lần; request mới thay mã cũ.
Rollback source chỉ áp dụng sau khi đánh giá tác động vì đưa link callback trở lại
sẽ thay đổi trải nghiệm đa thiết bị. Không thay đổi Auth user, session hoặc dữ
liệu nghiệp vụ khi rollback template/routing.
