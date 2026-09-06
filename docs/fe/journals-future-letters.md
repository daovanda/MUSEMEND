# Daily Journal và Future Letter

Trạng thái: `in-progress`
Cập nhật: 2026-09-05

## Phạm vi triển khai

Tab Journal hỗ trợ MVP:

- tải tối đa 50 daily journal và future letter gần nhất;
- tạo/sửa nhật ký ngày với tiêu đề và nội dung;
- tạo/sửa thư tương lai, chọn ngày nhắc và đọc/mở trước hạn;
- nhập tối đa 8 tag phân cách bằng dấu phẩy và hiển thị tag trên journal card;
- tùy chọn lên lịch nhắc cục bộ khi lưu thư tương lai;
- chọn ảnh JPG/PNG/WebP/HEIC tối đa 10 MiB, upload private và xem preview bằng
  signed URL 5 phút;
- pull-to-refresh, trạng thái loading/empty/retry;
- xác nhận rồi xóa mềm journal.

Yearly journal, tag, audio/video/PDF attachment và tìm kiếm chưa nằm trong lát cắt
UI này.

## Kiến trúc và luồng dữ liệu

`features/journals/` dùng cấu trúc `domain/data/application/presentation`:

- domain model không phụ thuộc response Supabase;
- mapper ghép `journals` với subtype `daily_journals`/`future_letters`;
- repository là ranh giới để thay bằng local-first adapter sau MVP;
- Riverpod controller tải lại danh sách sau mỗi mutation;
- presentation không chứa Supabase client.

## RPC, validation và bảo mật

Mọi create/update gọi `save_journal_with_tags()` để parent, subtype và tag
assignments được lưu trong cùng transaction. Mở thư gọi `open_future_letter()`; xóa gọi
`soft_delete_journal()`. Client không INSERT/UPDATE trực tiếp các bảng journal.

Ảnh được chọn qua platform picker, giảm chiều rộng tối đa 2048 px và upload vào
`journal-media/<auth.uid()>/<journal UUID>/<file UUID>.<ext>`. Adapter gọi
`attach_journal_media()` sau upload; retry tối đa ba lần trên cùng path để trường
hợp upload thành công nhưng mất response không tạo object khác. Preview chỉ dùng
signed URL 300 giây, không lưu public URL vào model hay database.

Android dùng system Photo Picker nên không xin quyền đọc toàn bộ thư viện. iOS chỉ
khai báo `NSPhotoLibraryUsageDescription` cho hành động do user chủ động bấm; app
không xin camera vì MVP chưa chụp ảnh trực tiếp. Manifest main có INTERNET để bản
release truy cập Supabase, thay vì chỉ hoạt động ở debug/profile.

Khi user chọn nhắc trên thiết bị, app chỉ xin quyền notification sau thao tác lưu
chủ động. Lịch nhắc dùng múi giờ `Asia/Ho_Chi_Minh`, payload chỉ chứa journal UUID;
title/body hệ điều hành là nội dung chung, không đưa nội dung riêng tư của thư ra
lock screen. Nếu quyền bị từ chối hoặc plugin lỗi, thư trên Supabase vẫn được lưu
và UI thông báo rõ reminder cục bộ chưa bật.

UI giới hạn title 120 và content 10.000 ký tự, yêu cầu content không rỗng. Ngày
giao thư mới phải từ ngày mai đến tối đa 10 năm; adapter gửi timestamp UTC. DB vẫn
là nguồn xác thực cuối cùng, kiểm tra owner bằng `auth.uid()` và cho phép đọc/sửa
thư trước hạn theo quyết định MVP.

Không hiển thị lỗi DB thô, không log nội dung nhật ký và không lưu nội dung vào
analytics. Nội dung hiện là plaintext được RLS bảo vệ, chưa có E2EE.

## Kiểm thử và nghiệm thu

- Unit test mapper bao phủ daily/future-letter response.
- DB integration test bao phủ chuẩn hóa tag, atomic wrapper và cross-user guard.
- Flutter test, analyze và APK build phải đạt.
- Android E2E với tài khoản QA đã xác nhận tạo daily atomically, tạo future letter
  hẹn ngày mai, mở sớm và reload vẫn giữ đúng nội dung/trạng thái đã mở.
- Android E2E đã xác nhận Photo Picker → private upload → attach RPC → reload →
  signed preview. Audit DB xác nhận bucket private, metadata/object khớp 1:1 và
  mọi path đều đúng prefix owner/journal. Picker vẫn cần kiểm thử trên thiết bị iOS.
- Android E2E đã xác nhận thêm hai tag vào daily journal, reload hiển thị đúng và
  audit Supabase Dev thấy đúng hai assignments.
- Android E2E đã xác nhận runtime permission được xin sau khi lưu và AlarmManager
  có lịch `ScheduledNotificationReceiver`; callback khi chạm notification mở tab
  Journal. Cấu hình iOS đã có nhưng cần nghiệm thu trên thiết bị thật.
- DB integration test hiện có bao phủ save journal, mở thư sớm, notification đến
  hạn và soft-delete.

## Giới hạn tiếp theo

- Thêm yearly journal/goals/highlights/lessons.
- Giữ pending upload qua app restart khi chuyển sang local-first; hiện retry nằm
  trong cùng phiên upload.
- Thêm tag, tìm kiếm, detail route và UI khôi phục trong thời gian xóa mềm.
- Khi chuyển local-first cần version/conflict policy; không để cache làm giảm RLS.

Liên quan: [Journal DB và Storage](../db/journals-media.md),
[Notification cục bộ và inbox](./notifications-inbox.md),
[Application foundation](./application-foundation.md).
