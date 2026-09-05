# Daily Journal và Future Letter

Trạng thái: `in-progress`
Cập nhật: 2026-09-05

## Phạm vi triển khai

Tab Journal hỗ trợ MVP:

- tải tối đa 50 daily journal và future letter gần nhất;
- tạo/sửa nhật ký ngày với tiêu đề và nội dung;
- tạo/sửa thư tương lai, chọn ngày nhắc và đọc/mở trước hạn;
- pull-to-refresh, trạng thái loading/empty/retry;
- xác nhận rồi xóa mềm journal.

Yearly journal, tag, media picker/upload và tìm kiếm chưa nằm trong lát cắt UI này.

## Kiến trúc và luồng dữ liệu

`features/journals/` dùng cấu trúc `domain/data/application/presentation`:

- domain model không phụ thuộc response Supabase;
- mapper ghép `journals` với subtype `daily_journals`/`future_letters`;
- repository là ranh giới để thay bằng local-first adapter sau MVP;
- Riverpod controller tải lại danh sách sau mỗi mutation;
- presentation không chứa Supabase client.

## RPC, validation và bảo mật

Mọi create/update gọi `save_journal()` để parent và subtype được lưu trong cùng
transaction. Mở thư gọi `open_future_letter()`; xóa gọi
`soft_delete_journal()`. Client không INSERT/UPDATE trực tiếp các bảng journal.

UI giới hạn title 120 và content 10.000 ký tự, yêu cầu content không rỗng. Ngày
giao thư mới phải từ ngày mai đến tối đa 10 năm; adapter gửi timestamp UTC. DB vẫn
là nguồn xác thực cuối cùng, kiểm tra owner bằng `auth.uid()` và cho phép đọc/sửa
thư trước hạn theo quyết định MVP.

Không hiển thị lỗi DB thô, không log nội dung nhật ký và không lưu nội dung vào
analytics. Nội dung hiện là plaintext được RLS bảo vệ, chưa có E2EE.

## Kiểm thử và nghiệm thu

- Unit test mapper bao phủ daily/future-letter response.
- Flutter test, analyze và APK build phải đạt.
- Android E2E với tài khoản QA đã xác nhận tạo daily atomically, tạo future letter
  hẹn ngày mai, mở sớm và reload vẫn giữ đúng nội dung/trạng thái đã mở.
- DB integration test hiện có bao phủ save journal, mở thư sớm, notification đến
  hạn và soft-delete.

## Giới hạn tiếp theo

- Thêm yearly journal/goals/highlights/lessons.
- Tích hợp private Storage theo flow upload → `attach_journal_media()`.
- Thêm tag, tìm kiếm, detail route và UI khôi phục trong thời gian xóa mềm.
- Khi chuyển local-first cần version/conflict policy; không để cache làm giảm RLS.

Liên quan: [Journal DB và Storage](../db/journals-media.md),
[Application foundation](./application-foundation.md).
