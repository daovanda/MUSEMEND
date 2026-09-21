# Authentication client

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-21

## Mục tiêu và phạm vi

MuseMend là ứng dụng di động. Đăng ký, xác nhận email, đăng nhập, quên mật
khẩu và đặt mật khẩu mới đều hoàn tất trong Flutter app. Email Auth chỉ mang
OTP 6 số; không có URL callback, CTA hoặc trang đăng nhập web trong luồng mới.

## Thiết kế và trách nhiệm

`AuthRepository` là contract domain; `SupabaseAuthRepository` là adapter duy
nhất gọi Supabase Auth. `AuthController` quản lý `AsyncValue` cho thao tác Auth.
`SignInScreen` xác thực input và router quản lý navigation. Client không gửi
`user_id`, quyền hoặc phần thưởng.

Auth session khôi phục phải được xác thực lại bằng `getUser` trước khi router
tin cậy nó. Session đã bị xoá, hết hạn hoặc không còn user bị dọn khỏi thiết bị;
timeout 15 giây đưa người dùng về sign-in thay vì giữ splash vô hạn. Quy tắc này
xử lý cả trường hợp xoá tài khoản rồi đăng ký lại cùng email.

## Luồng OTP trong app

### Đăng ký và xác nhận email

1. Người dùng nhập tên hiển thị, email và mật khẩu ở `/sign-in`.
2. `signUp` gửi `display_name` cùng `language_code` trong Auth metadata để
   template chọn đúng ngôn ngữ.
3. Khi Supabase chấp nhận tạo account, router đi tới `/confirm-email` với email
   đã điền sẵn.
4. Người dùng nhập OTP 6 số từ email. Client gọi
   `verifyOTP(type: OtpType.email)`.
5. Chỉ OTP hợp lệ mới tạo phiên và chuyển người dùng tới `/onboarding`.
6. Nút gửi lại mã bị khóa 60 giây kể từ lúc màn OTP mở và sau mỗi lần gửi lại
   thành công; thời gian còn lại giảm theo từng giây trên nút. Xác nhận email
   gọi `auth.resend(type: signup)`.

### Quên mật khẩu

1. Từ sign-in, người dùng nhập email và chọn gửi mã.
2. `requestPasswordReset` gọi `resetPasswordForEmail(email)` **không** truyền
   `redirectTo`; phản hồi UI vẫn chung để không tiết lộ email có tồn tại hay không.
3. App đi tới `/reset-password`, điền sẵn email, và yêu cầu email cùng OTP 6 số.
4. `verifyOTP(type: OtpType.recovery)` phải trả recovery session hợp lệ trước
   khi form mật khẩu mới xuất hiện.
5. `updateUser(password: ...)` ghi mật khẩu thật lên Supabase Auth. App sign-out
   recovery session, rồi đưa người dùng về `/sign-in?reset=success`.
6. Nút gửi lại mã có cùng countdown 60 giây; do Supabase GoTrue không hỗ trợ
   `resend` cho recovery, client gọi lại `resetPasswordForEmail(email)` để phát
   mã mới. Lỗi gửi lại được báo riêng, không bị nhầm thành mã OTP sai.

OTP dùng một lần và hết hạn sau 3.600 giây (1 giờ) theo Supabase Auth. Mã mới
thay thế mã cũ. Client không lưu OTP, token, mật khẩu hoặc email vào DB, log hay
persistent storage.

Router trong app được tạo một lần và chỉ `refresh()` khi auth session, profile
onboarding hoặc thông báo khởi chạy đổi trạng thái. Không theo dõi các provider
này bằng `watch` trong provider tạo router, để quá trình khởi tạo session không
tạo lại router và đẩy người dùng khỏi `/confirm-email` hoặc `/reset-password`.
Khi QA Flutter Web mở thẳng một trong hai route OTP, router giữ nguyên path đó
thay vì ép qua splash; launch Android/iOS và Web tại `/` vẫn bắt đầu ở splash.

## Localization, UI và validation

Mọi chuỗi cố định dùng ARB theo locale đang hiệu lực. Các ngôn ngữ hỗ trợ là
`vi`, `en`, `ja`, `fr`, `es`, `it`, `de`, `ko`, `pt`, `ms`, `id`, `th`; mã khác
fallback về tiếng Anh. Email phải đúng định dạng, OTP đúng 6 chữ số, tên 2–60 ký
tự và mật khẩu ít nhất 8 ký tự. Lỗi Auth được ánh xạ sang thông báo an toàn, không
hiện stack trace hay chi tiết Supabase.

Màn auth giữ palette sáng, dùng asset brand cục bộ, tương phản đủ ngay cả khi
theme hệ thống tối. Giao diện phải có scroll an toàn ở text scale lớn và vùng chạm
tối thiểu 48 px. Đăng nhập, đăng ký, xác nhận email, nhập OTP và nhập mật khẩu
mới dùng cùng field theme (viền outline có notch cho nhãn) để nhãn của dữ liệu
điền sẵn hoặc field đang focus không đè lên nền ô nhập.

## Portal thông tin công khai và callback lịch sử

Build `PUBLIC_AUTH_PORTAL=true` trên Vercel phục vụ landing công khai tại `/`,
Privacy tại `/privacy`, Terms tại `/terms`, đồng thời vẫn đọc callback token lịch
sử tại `/email-confirmed` và `/reset-password`. Các trang công khai giải thích
mục đích app và dữ liệu Google tối thiểu dùng cho Google Sign-In; chúng không có
sign-in, onboarding, phiên đăng nhập hay dữ liệu nghiệp vụ. `signUp`,
`requestPasswordReset` và email template mới không gọi portal. Luồng OTP nội bộ
được quyết định tại [ADR-0005](../other/adr-0005-in-app-email-otp.md).

## Google OAuth

**Trạng thái:** `implemented` — public portal Vercel, Google Consent Branding
và Audience `External · In production` đã được cấu hình. Google Provider ở
Supabase đang bật; callback broker và deep link native đều nằm trong allow-list.

Nút “Tiếp tục với Google” có trên cả sign-in và sign-up. App gọi
`signInWithOAuth(OAuthProvider.google)`, không dùng Google Sign-In SDK và không
chứa Google Client Secret. Supabase nhận callback OAuth trước, sau đó trả:

- Android/iOS: `com.musemend.app://login-callback`.
- Flutter Web QA: origin của URL đang mở.

Android khai báo riêng host `login-callback`; iOS đã đăng ký URL scheme
`com.musemend.app`. Router tiếp tục dựa vào `authSessionProvider`, do đó account
Google mới đi tới onboarding còn account đã hoàn tất onboarding đi vào app.
Trigger profile hiện tại lấy `full_name` và `avatar_url` từ Auth metadata, đồng
thời nhận provider `google`; client không tự tạo hoặc cấp quyền cho profile.

Google cần được bật ở Supabase và URL redirect phải nằm allow-list trước khi
nhấn nút. Client secret chỉ được lưu tại Supabase Dashboard; không ghi vào
Flutter config, `config/dev.json`, log hay Git. Runbook và checklist QA ở
[Google OAuth](../other/google-oauth.md).

## Kiểm thử và nghiệm thu

- Widget test kiểm tra sign-up và reset chuyển vào route OTP nội bộ, email được
  điền sẵn và password form chỉ xuất hiện sau recovery OTP.
- Kiểm thử router giữ nguyên route OTP khi auth session chuyển từ loading sang
  signed-out, và hai luồng resend chỉ bật sau 60 giây rồi reset cooldown khi gửi
  thành công.
- Kiểm tra `flutter analyze`, unit/widget tests và build Flutter liên quan.
- QA với email test mới: xác nhận và reset đều gửi đúng 6 số, không có CTA/link,
  mã chỉ dùng một lần, mã quá một giờ bị từ chối, đổi mật khẩu xong đăng nhập lại
  được bằng mật khẩu mới.
- Không dùng email/mật khẩu người dùng thật trong automated tests.
- QA Google: thử một account Google mới và một account đã hoàn tất onboarding;
  kiểm tra return deep link trên Android/iOS, web QA, cancel/error từ provider
  và đảm bảo không có token/secret trong log.
- Production Google: xác minh Vercel phục vụ trực tiếp `/`, `/privacy`, `/terms`
  không yêu cầu login; đường dẫn Branding Google trùng đúng các URL này, Audience
  là `In production`, và một account Google chưa từng là test user vẫn hoàn tất
  OAuth rồi quay lại app.

## Liên quan

- [Auth email templates](../be/auth-email-templates.md)
- [ADR-0005 — OTP email trong ứng dụng](../other/adr-0005-in-app-email-otp.md)
- [Flutter Web local](./flutter-web-local.md)
