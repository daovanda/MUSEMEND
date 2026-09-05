# Notification cục bộ và inbox

Trạng thái: `in-progress`
Cập nhật: 2026-09-05

## Phạm vi MVP

- Khi lưu Future Letter, user có thể bật/tắt nhắc trên thiết bị.
- App xin quyền notification theo ngữ cảnh, không xin ngay khi mở app.
- Android/iOS lên lịch local notification vào `deliver_at` theo
  `Asia/Ho_Chi_Minh`.
- Profile hiển thị tối đa 30 notification server mới nhất, gồm trạng thái đã đọc.
- Chạm notification hệ điều hành hoặc notification trong inbox mở tab Journal.

Push notification đa thiết bị, badge đồng bộ, Realtime subscription và màn hình
chi tiết định tuyến tới đúng journal ID chưa nằm trong lát cắt này.

## Kiến trúc

`features/notifications/` tách thành:

- `domain`: reminder, inbox model và hai interface riêng cho thiết bị/DB;
- `data`: adapter `flutter_local_notifications`, mapper và Supabase repository;
- `application`: provider/service singleton và inbox controller;
- presentation inbox được ghép vào Profile; app shell chỉ nhận yêu cầu điều hướng.

`NotificationService` được khởi tạo một lần trong bootstrap để nhận cả cold-start
payload. Cold start giữ journal ID ban đầu qua provider để router chọn `/journal`
sau khi khôi phục session; foreground callback chuyển branch trực tiếp. Payload
không được dùng để bypass auth hay query dữ liệu ngoài RLS.

## Supabase contract và bảo mật

Repository chỉ SELECT các cột cần thiết từ `notifications`; RLS giới hạn
`user_id = auth.uid()`. Đánh dấu đã đọc bắt buộc qua
`mark_notification_read(p_id)` để DB kiểm tra owner. Client không INSERT
notification và không thể tự tạo sự kiện đến hạn.

Notification trên lock screen dùng title/body chung, không có tiêu đề hoặc nội dung
thư. Payload chỉ là `journal:<uuid>`. Local initialization lỗi không được chặn app
khởi động hoặc làm rollback bản thư đã lưu thành công trên server.

## Platform

Android khai báo `POST_NOTIFICATIONS`, boot receiver và scheduled receiver, bật
core-library desugaring, dùng `inexactAllowWhileIdle` nên không xin quyền exact
alarm. iOS hoãn request alert/badge/sound đến lúc user bật nhắc khi lưu thư.

## Kiểm thử

- Unit test mapper bao phủ row đã đọc/chưa đọc.
- Analyze, toàn bộ Flutter tests và APK debug build phải đạt.
- Android emulator đã xác nhận dialog không che tùy chọn trên màn hình 720×1280,
  runtime permission được cấp, AlarmManager giữ scheduled receiver và foreground
  lẫn cold-start notification callback đều mở tab Journal.
- iOS cần kiểm thử trên thiết bị thật.

Liên quan: [Daily Journal và Future Letter](./journals-future-letters.md),
[Notifications DB/cleanup](../db/notifications-cleanup.md).
