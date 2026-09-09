# Flutter Web local QA

**Trạng thái:** implemented

## Mục đích

Flutter Web được bật để kiểm tra nhanh giao diện, navigation và các luồng dữ
liệu Supabase Development mà không phải khởi động Android Emulator. Đây là
target QA cục bộ, không phải bản phát hành production.

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

Web không thay thế Android/iOS QA. Permission native, local notification, image
picker, back button, hiệu năng GPU và gesture cảm ứng phải được kiểm tra trên
thiết bị thật hoặc simulator tương ứng. Khi thêm plugin mới, cần xác nhận plugin
có web implementation hoặc đặt adapter có điều kiện nền tảng trước khi dùng
trong target này.

Không dùng service-role key trong `config/dev.json`; chỉ dùng Supabase URL và
publishable/anon key của môi trường Development.
