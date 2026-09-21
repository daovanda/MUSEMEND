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
- Hosted template của Supabase được quản lý riêng tại Authentication → Emails;
  Vercel/Git deploy không tự cập nhật các template này. Ngày 2026-09-19, QA một
  email reset cho thấy link cuối có query `?code=...`; template Reset Password
  production khi đó còn 11 CTA `{{ .ConfirmationURL }}`. Đã thay các CTA đó bằng
  callback `#token_hash={{ .TokenHash }}&amp;type=recovery`, lưu và tải lại trang
  để xác nhận không còn `{{ .ConfirmationURL }}` trong hosted template. Template
  Ngày 2026-09-19, cả Reset Password và Confirm Sign Up production đã được đổi
  sang mẫu OTP 6 số; tải lại trang xác nhận Save changes đã hoàn tất.
- Client gửi `language_code` khi đăng ký. Template chọn `vi`, `en`, `ja`, `fr`,
  `es`, `it`, `de`, `ko`, `pt`, `ms`, `id`, `th`; mã khác fallback về tiếng Anh.
- Email mới hiển thị `{{ .Token }}` (OTP 6 số). CTA chỉ mở `/email-confirmed`
  hoặc `/reset-password` và không mang credential, nên click tracking hoặc
  scanner của SMTP không thể làm biến dạng hay dùng trước OTP.
- Người dùng nhập email và OTP trên web. Client chỉ gửi chúng trực tiếp tới
  Supabase `verifyOTP` sau thao tác xác nhận; không lưu OTP trong URL, log, DB
  hoặc persistent storage. Callback `TokenHash` cũ vẫn được hỗ trợ tạm thời.
- Subject giữ ngắn, ổn định; nội dung và CTA được bản địa hoá trong body.
- Email reset và confirmation là hai mẫu độc lập, mỗi mẫu chỉ có một CTA và
  một khối HTML hoàn chỉnh.

## Link reset: thời hạn, tính dùng một lần và điều hướng

Supabase Auth tạo recovery token cho mỗi yêu cầu. Link/token có thể dùng một lần;
Email OTP Expiration trong production được xác minh là `3600` giây (1 giờ). Hạn
này cũng áp dụng cho confirmation. Template hiển thị OTP `{{ .Token }}` và CTA
không credential tới `/reset-password` hoặc `/email-confirmed`. Người dùng nhập
email cùng mã; trang gửi POST `verifyOTP` đến đúng Supabase project. Recovery chỉ
mở form khi verify trả session hợp lệ, sau đó `updateUser` mới ghi mật khẩu.

Public Flutter Web chỉ cung cấp ba trạng thái: trang hướng dẫn trung tính ở `/`,
thành công xác nhận tại `/email-confirmed`, và form recovery tại `/reset-password`.
Không có đăng nhập, onboarding hay màn nghiệp vụ trên web. Hai redirect được
truyền trực tiếp trong `signUp(emailRedirectTo: ...)` và
`resetPasswordForEmail(redirectTo: ...)`; template email dùng token hash và OTP
type cụ thể để callback có thể xác minh cả khi email được gửi từ app native rồi
mở trên trình duyệt/thiết bị khác. Web dùng Path URL strategy.

Vercel cần rewrite hai pathname callback về `index.html`. Repository đặt cấu hình
tại `vercel.json` và `app/vercel.json` để khớp cấu hình project root dù được đặt
ở repo root hay `app`; deployment phải chứa Flutter web `index.html` ở output
root. Supabase Site URL là `https://musemend-app.vercel.app`; URL allow-list phải
có origin, `/email-confirmed` và `/reset-password`. Không dùng URL hash cũ cho
luồng email mới.

Trang xác nhận chỉ báo thành công sau khi Supabase chấp nhận token hash; trang
reset chỉ hiện form sau khi Supabase chấp nhận recovery token và trả session.
Callback cũ có session vẫn được đọc trong giai đoạn chuyển tiếp. Sau đổi mật
khẩu web hiển thị xác nhận và đăng xuất; người dùng quay lại app để tiếp tục.
Link reset luôn đi đến web utility
trên mọi nền tảng, không về trang sign-in web.

Supabase khuyến nghị không để SMTP provider rewrite link trong email Auth. Mục
Brevo Transactional → Settings → Tracking hiện chỉ cho chọn tracking ẩn danh và
không có công tắc tắt click tracking trên gói hiện tại. Vì vậy credential đã được
tách khỏi CTA: Brevo có thể bọc URL mở portal nhưng không thể thay đổi OTP trong
nội dung. Về lâu dài vẫn nên tắt click tracking hoặc dùng provider giữ nguyên link.

## Bảo mật và lỗi

- Reset endpoint luôn trả thông báo thành công chung để không tiết lộ email có
  tồn tại hay không.
- Token chỉ do Supabase phát hành, có thời hạn, dùng một lần; không đặt trong
  query string, không gửi tới server qua HTTP, và client không lưu token vào DB,
  persistent storage hoặc log.
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
- Hosted Supabase templates cần được đồng bộ thủ công từ file source tương ứng;
  CI/Vercel deploy không tự cập nhật email template trên Supabase. Reset Password
  và Confirm Sign Up production đã được đồng bộ sang OTP ngày 2026-09-19.
- URL QA dạng `/reset-password?code=...` là kết quả của PKCE redirect và không
  dùng cho flow đa thiết bị. Email mới phải có OTP 6 số và CTA chỉ mở pathname
  không credential; trang chỉ xác minh sau khi người dùng nhập email, OTP và bấm
  xác nhận. Auth Logs production chưa có dữ liệu tại lúc kiểm tra;
  tính năng ghi audit log trong Auth đang tắt nên không thể suy ra mã lỗi server
  hoặc thời điểm hết hạn chỉ từ log.
- QA thủ công với email test: mỗi request tạo email/link mới; cùng link thứ hai
  không dùng lại được; link quá 1 giờ bị từ chối; link còn hạn mở form, đổi mật
  khẩu thành công, rồi đăng nhập được bằng mật khẩu mới. Không xem bước này là
  hoàn tất khi chưa kiểm tra trên Supabase/Vercel production thật.
- Rollback: khôi phục source template trước đó và redeploy app path routing; không
  thay đổi Auth users hay dữ liệu nhật ký. Nếu token bị lộ, gửi yêu cầu reset mới
  thay vì lưu hoặc phát tán link cũ.
