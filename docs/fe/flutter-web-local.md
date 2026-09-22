# Flutter Web callback portal QA

**Trạng thái:** implemented

## Mục đích

Flutter Web local mặc định chạy app đầy đủ để QA. Xác nhận email và đặt lại mật
khẩu hiện dùng OTP 6 số ngay trong app, vì vậy không cần mở Vercel từ email.
Callback portal public cũ vẫn có thể bật riêng bằng
`--dart-define=PUBLIC_AUTH_PORTAL=true` để xử lý liên kết lịch sử, nhưng không
phải luồng mới. Dùng Android Emulator hoặc thiết bị thật để QA permission và
tích hợp native.

## Chạy local

Từ thư mục `app/`, tạo `config/dev.json` từ file mẫu nếu chưa có. Cách chuẩn để
khởi động một lượt QA Web mới là:

```powershell
.\tool\start-local-web-qa.ps1
```

Script build Web release từ source hiện tại với `config/dev.json`, sau đó phục
vụ tại `http://127.0.0.1:64580` và in URL có `qa=<run-id>` để mở. Chỉ dùng
Supabase Development URL và publishable key trong `config/dev.json`; không đặt
service-role key, password hay token ở đây.

Mỗi lần chạy, script làm theo thứ tự:

1. Dừng **cây tiến trình do chính script khởi động ở lượt trước**, bằng PID mà
   static server thật tự ghi sau khi bind cổng trong
   `.dart_tool/musemend-local-web-qa.json`. Runbook còn đối chiếu mốc khởi động
   của PID, nên PID đã bị Windows tái sử dụng sẽ không bị dừng nhầm.
2. Từ chối dừng một tiến trình không thuộc runbook nếu nó đang chiếm cổng. Cách
   này tránh vô tình giết server hoặc ứng dụng khác của developer.
3. Sửa file khóa Flutter bị sót chỉ khi không còn Dart/Flutter process, build
   lại với `--pwa-strategy=none`, rồi chạy static server cục bộ có header
   `Cache-Control: no-store`.
4. Sinh `qa=<run-id>` mới. Kết hợp với PWA bị tắt và header không cache, trình
   duyệt không thể tái sử dụng service worker/bundle của lượt QA cũ.

Vì cổng mặc định `64580` đã có trong Supabase Development redirect allow-list,
hãy giữ cổng này khi kiểm thử Google OAuth trên Web. Nếu thực sự cần đổi cổng,
thêm origin tương ứng vào allow-list Supabase Development trước; nếu không,
OAuth Web sẽ bị từ chối redirect.

Tùy chọn hữu ích:

```powershell
# Mở URL mới bằng trình duyệt mặc định sau khi server sẵn sàng.
.\tool\start-local-web-qa.ps1 -OpenBrowser

# Dừng đúng server do runbook quản lý, không chạm tiến trình khác.
.\tool\start-local-web-qa.ps1 -Stop
```

Nếu cổng 64580 đang thuộc một tiến trình không do runbook tạo, script dừng với
PID để developer tự xác minh và dừng tiến trình đó. Không dùng `taskkill` theo
tên process hoặc đóng toàn bộ Dart/Flutter process.

Muốn chạy callback portal lịch sử local, vẫn dùng build riêng với
`--dart-define=PUBLIC_AUTH_PORTAL=true`; đó không phải luồng auth OTP hiện tại.

## Phạm vi phù hợp

- kiểm tra giao diện responsive của màn nhập OTP xác nhận email và khôi phục
  mật khẩu;
- xác minh OTP 6 số được xác minh bởi Supabase Development;
- kiểm tra form đổi mật khẩu, trạng thái thành công và lỗi.

## Giới hạn

Vercel cần phục vụ `index.html` cho `/email-confirmed` và `/reset-password` theo
cấu hình `vercel.json`. Nếu Vercel Project Root Directory là repo root, dùng
`/vercel.json`; nếu đặt root là `app`, cấu hình tương ứng nằm tại
`/app/vercel.json`. Cả hai file giữ cùng rewrite để không phụ thuộc cấu hình
monorepo hiện tại. Supabase Auth allow-list phải có hai URL production.

Web callback portal không cung cấp sign-in hay dữ liệu nghiệp vụ. Nó chỉ giữ
tương thích cho liên kết lịch sử; email mới không còn đưa người dùng tới portal.

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
