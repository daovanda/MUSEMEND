# Flutter Web local QA và public callback pages

**Trạng thái:** in-progress

## Mục đích

Flutter Web được bật để kiểm tra nhanh giao diện app và các luồng dữ liệu
Supabase Development mà không phải khởi động Android Emulator. Production web
không phải bản phát hành app: chỉ có landing trung tính, email-confirmed và
reset-password cho callback email từ ứng dụng Android/iOS.

## Chạy local

Từ thư mục `app/`, tạo `config/dev.json` từ file mẫu nếu chưa có rồi chạy:

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Flutter sẽ mở một URL `http://localhost:<port>`. Giữ terminal chạy trong suốt
thời gian QA; dừng bằng `q` hoặc `Ctrl+C`.

## Phạm vi phù hợp

- kiểm tra layout, typography, animation, navigation và responsive UI;
- kiểm tra form, repository và đọc/ghi Supabase Development;
- kiểm tra nhanh các tương tác chuột/pointer trước khi xác nhận trên Android.

## Giới hạn

Vercel cần phục vụ `index.html` cho `/email-confirmed` và `/reset-password` theo
cấu hình `vercel.json`. Nếu Vercel Project Root Directory là repo root, dùng
`/vercel.json`; nếu đặt root là `app`, cấu hình tương ứng nằm tại
`/app/vercel.json`. Cả hai file giữ cùng rewrite để không phụ thuộc cấu hình
monorepo hiện tại. Supabase Auth allow-list phải có hai URL production.

Web callback portal không cung cấp sign-in hay dữ liệu nghiệp vụ. Người dùng
xác nhận email xong hoặc đổi mật khẩu xong sẽ quay lại ứng dụng MuseMend để
tiếp tục.

Web không thay thế Android/iOS QA. Permission native, local notification, image
picker, back button, hiệu năng GPU và gesture cảm ứng phải được kiểm tra trên
thiết bị thật hoặc simulator tương ứng. Khi thêm plugin mới, cần xác nhận plugin
có web implementation hoặc đặt adapter có điều kiện nền tảng trước khi dùng
trong target này.

Không dùng service-role key trong `config/dev.json`; chỉ dùng Supabase URL và
publishable/anon key của môi trường Development.
