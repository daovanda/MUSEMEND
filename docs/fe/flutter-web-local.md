# Flutter Web callback portal QA

**Trạng thái:** in-progress

## Mục đích

Flutter Web public trên Vercel chỉ xử lý callback email xác nhận và đặt lại mật
khẩu; nó không phải bản web để đăng nhập hay sử dụng nghiệp vụ. Flutter Web
local mặc định chạy app đầy đủ để QA; có thể bật callback portal riêng bằng
`--dart-define=PUBLIC_AUTH_PORTAL=true`. Dùng Android Emulator hoặc thiết bị thật
để QA permission và tích hợp native.

## Chạy local

Từ thư mục `app/`, tạo `config/dev.json` từ file mẫu nếu chưa có rồi chạy:

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Flutter sẽ mở một URL `http://localhost:<port>`. Giữ terminal chạy trong suốt
thời gian QA; dừng bằng `q` hoặc `Ctrl+C`. Muốn chạy callback portal local thì
thêm `--dart-define=PUBLIC_AUTH_PORTAL=true` vào lệnh trên.

## Phạm vi phù hợp

- kiểm tra giao diện responsive của trang xác nhận email và đặt lại mật khẩu
  khi bật callback portal;
- xác minh callback URL mở đúng route và token/session được xử lý bởi Supabase
  Development;
- kiểm tra form đổi mật khẩu, trạng thái thành công và lỗi.

## Giới hạn

Vercel cần phục vụ `index.html` cho `/email-confirmed` và `/reset-password` theo
cấu hình `vercel.json`. Nếu Vercel Project Root Directory là repo root, dùng
`/vercel.json`; nếu đặt root là `app`, cấu hình tương ứng nằm tại
`/app/vercel.json`. Cả hai file giữ cùng rewrite để không phụ thuộc cấu hình
monorepo hiện tại. Supabase Auth allow-list phải có hai URL production.

Web callback portal không cung cấp sign-in hay dữ liệu nghiệp vụ. Người dùng
xác nhận email xong hoặc đổi mật khẩu xong sẽ quay lại ứng dụng MuseMend để
tiếp tục. Đây là hành vi có chủ đích, không phải fallback về trang đăng nhập.

Web không thay thế Android/iOS QA. Permission native, local notification, image
picker, back button, hiệu năng GPU và gesture cảm ứng phải được kiểm tra trên
thiết bị thật hoặc simulator tương ứng. Khi thêm plugin mới, cần xác nhận plugin
có web implementation hoặc đặt adapter có điều kiện nền tảng trước khi dùng
trong target này.

## Build public callback portal trên Vercel

Vercel build dùng `app/tool/vercel_build.sh` cùng Flutter version pin trong
`app/.fvmrc`; script xác minh checksum SDK, lấy dependencies theo lockfile, rồi
build release vào `app/build/web`. `app/vercel.json` dành cho project Root
Directory `app`, còn `/vercel.json` hỗ trợ Root Directory là repository. Cả hai
giữ rewrite callback cho `/email-confirmed` và `/reset-password`.

Trong build container Vercel, Flutter có thể chạy dưới UID khác với owner của
SDK vừa giải nén. Sau khi xác minh SHA-256, script chỉ thêm đúng thư mục SDK đã
pin vào Git `safe.directory` trước khi gọi Flutter; không đánh dấu toàn bộ repo
hay thư mục cha là an toàn.

Vercel cần Environment Variables `APP_ENV`, `SUPABASE_URL` và
`SUPABASE_PUBLISHABLE_KEY`. Chúng là compile-time values được nhúng vào bundle;
`APP_ENV` phải đặt tường minh. Chỉ dùng project URL và publishable/anon key;
script từ chối service-role/secret key. Lưu ý callback URL hiện dùng một domain
cố định, vì vậy domain chỉ xác thực được email do đúng project Supabase đang
được build phát hành. Cấu hình QA tạm thời và giới hạn môi trường được ghi tại
[Vercel auth callback portal](../other/vercel-auth-callback-portal.md).

Không dùng service-role key trong `config/dev.json`; chỉ dùng Supabase URL và
publishable/anon key của môi trường Development.
