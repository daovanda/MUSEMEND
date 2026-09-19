# Auth email templates

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-19

## Mục tiêu

Email xác nhận đăng ký và khôi phục mật khẩu có hai nội dung riêng, cùng giọng
điệu MuseMend và bản dịch theo `language_code` đã lưu trong Auth metadata. Link
reset hướng tới web production `https://musemend-app.vercel.app/reset-password`;
link xác nhận hướng tới `https://musemend-app.vercel.app/email-confirmed`, kể cả
khi yêu cầu được gửi từ app local hoặc app di động.

## Triển khai

- Source template chuẩn trong repository:
  - `supabase/templates/confirm-sign-up.html`
  - `supabase/templates/reset-password.html`
- Hosted template của Supabase được quản lý tại Authentication → Emails. Hai
  mẫu production đã được thay thế hoàn chỉnh ngày 2026-09-19 bằng nội dung tương
  ứng; không nối thêm vào HTML mặc định.
- Client gửi `language_code` khi đăng ký. Template chọn `vi`, `en`, `ja`, `fr`,
  `es`, `it`, `de`, `ko`, `pt`, `ms`, `id`, `th`; mã khác fallback về tiếng Anh.
- CTA dùng `{{ .ConfirmationURL }}` để Supabase tạo và xác thực token. Không tự
  ghép token, không đưa token/session/password/PII vào HTML, log hay repository.
- Subject giữ ngắn, ổn định; nội dung và CTA được bản địa hoá trong body.
- Email reset và confirmation là hai mẫu độc lập, mỗi mẫu chỉ có một CTA và
  một khối HTML hoàn chỉnh.

## Link reset: thời hạn, tính dùng một lần và điều hướng

Supabase Auth tạo recovery token cho mỗi yêu cầu. Link/token có thể dùng một lần;
Email OTP Expiration trong production được xác minh là `3600` giây (1 giờ). Hạn
này cũng áp dụng cho confirmation link. Link reset dùng URL `.ConfirmationURL`
của Supabase, trong đó đích cuối nhận redirect đã allow-list.

Public Flutter Web chỉ cung cấp ba trạng thái: trang hướng dẫn trung tính ở `/`,
thành công xác nhận tại `/email-confirmed`, và form recovery tại `/reset-password`.
Không có đăng nhập, onboarding hay màn nghiệp vụ trên web. Hai redirect được
truyền trực tiếp trong `signUp(emailRedirectTo: ...)` và
`resetPasswordForEmail(redirectTo: ...)`; mẫu email tiếp tục dùng
`{{ .ConfirmationURL }}` để Supabase xác minh token. Web dùng Path URL strategy.

Vercel cần rewrite hai pathname callback về `index.html`. Repository đặt cấu hình
tại `vercel.json` và `app/vercel.json` để khớp cấu hình project root dù được đặt
ở repo root hay `app`; deployment phải chứa Flutter web `index.html` ở output
root. Supabase Site URL là `https://musemend-app.vercel.app`; URL allow-list phải
có origin, `/email-confirmed` và `/reset-password`. Không dùng URL hash cũ cho
luồng email mới.

Trang xác nhận chỉ báo thành công khi Auth SDK nhận được session từ callback;
thiếu session/lỗi sẽ hiện trạng thái link không hợp lệ/hết hạn. Trang reset cũng
chỉ hiện form khi có recovery session. Sau đổi mật khẩu web hiển thị xác nhận và
đăng xuất; người dùng quay lại app để tiếp tục. Link reset luôn đi đến web utility
trên mọi nền tảng, không về trang sign-in web.

Supabase khuyến nghị không để SMTP provider rewrite link trong email Auth. Mục
Brevo Transactional → Settings → Tracking hiện chỉ cho chọn tracking ẩn danh;
trạng thái đang là `No` (tracking vẫn hoạt động, không ẩn danh) và không có công
tắc tắt click tracking ở màn hình đó. Vì vậy chưa thể xác nhận Brevo giữ nguyên
liên kết Supabase trong email thực gửi. Một số email scanner cũng có thể mở link
dùng một lần trước người dùng. Cần gửi email QA và kiểm tra link đích; nếu
Brevo rewrite hoặc prefetch gây lỗi, phải dùng SMTP không rewrite link hoặc nhờ
Brevo xác nhận cách tắt click tracking cho Auth email trước khi phát hành.

## Bảo mật và lỗi

- Reset endpoint luôn trả thông báo thành công chung để không tiết lộ email có
  tồn tại hay không.
- Token chỉ do Supabase phát hành, có thời hạn, dùng một lần; client không lưu
  token vào DB hoặc log.
- Chỉ sau callback hợp lệ, màn reset gọi `supabase.auth.updateUser` để ghi mật
  khẩu mới thực sự vào Auth. Sau thành công app đóng recovery session và đưa
  người dùng về đăng nhập.
- Không tạo email/link test bằng tài khoản thật trong automated tests và không
  submit đổi mật khẩu thay người dùng.

## Kiểm thử, nghiệm thu và rollback

- Chạy Flutter analyze, widget/unit tests và build web.
- Kiểm tra URL production `/reset-password` mở form khi callback recovery hợp lệ;
  `/email-confirmed` hiển thị xác nhận sau callback đăng ký hợp lệ.
- Mở root và URL không xác định để chắc chắn website không hiển thị form đăng
  nhập; trang trung tính không được tự tuyên bố email đã xác nhận.
- Kiểm tra Vercel rewrite cho hai pathname và Supabase allow-list chứa chính xác
  hai URL callback.
- Supabase UI hiện Email OTP Expiration `3600`; không thay đổi nếu đã đúng.
- Hosted templates phải được kiểm tra source và Preview để chắc chắn không còn
  phần template mặc định nối thêm hoặc text HTML thô.
- QA thủ công với email test: mỗi request tạo email/link mới; cùng link thứ hai
  không dùng lại được; link quá 1 giờ bị từ chối; link còn hạn mở form, đổi mật
  khẩu thành công, rồi đăng nhập được bằng mật khẩu mới. Không xem bước này là
  hoàn tất khi chưa kiểm tra trên Supabase/Vercel production thật.
- Rollback: khôi phục source template trước đó và redeploy app path routing; không
  thay đổi Auth users hay dữ liệu nhật ký. Nếu token bị lộ, gửi yêu cầu reset mới
  thay vì lưu hoặc phát tán link cũ.
