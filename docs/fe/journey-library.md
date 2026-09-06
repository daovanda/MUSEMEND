# Journey và Library

Trạng thái: `in-progress`
Cập nhật: 2026-09-05

## Phạm vi hiện đã triển khai

Tab Library đọc dashboard hành trình của user đang đăng nhập và hiển thị:

- trạng thái hành trình, tỉnh và checkpoint hiện tại;
- năng lượng còn có thể phân bổ, phần trăm hoàn thành tỉnh;
- tiến độ của từng checkpoint trong tỉnh hiện tại;
- bộ sưu tập địa danh, món ăn và vật phẩm đã mở khóa;
- thao tác bắt đầu hành trình/đến tỉnh tiếp theo và đồng bộ tiến độ.

Màn hình hỗ trợ pull-to-refresh, loading, lỗi có thể thử lại và trạng thái rỗng.
Asset của catalog MVP chưa có nên hiện dùng icon Material thay thế.

## Kiến trúc

Miền `features/journey/` tách theo:

- `domain`: dashboard, tỉnh, checkpoint, collectible, trạng thái và repository
  contract;
- `data`: Supabase adapter và mapper tổng hợp nhiều response thành domain model;
- `application`: Riverpod `JourneyController` điều phối load/start/advance;
- `features/library/presentation`: chỉ render domain state và phát intent.

Khi hoàn thành nhiệm vụ, Missions controller invalidate Journey controller để tab
Library không giữ energy/checkpoint cũ trong `StatefulShellRoute.indexedStack`.

## Hợp đồng Supabase và bảo mật

Client chỉ `SELECT` catalog active và dữ liệu hành trình được RLS giới hạn theo
`auth.uid()`. Client không gửi `user_id`, không tự ghi energy/progress/unlock và
không tự quyết định phần thưởng.

Mutation chỉ đi qua:

- `start_journey()` để máy chủ chọn tỉnh/checkpoint hợp lệ;
- `advance_journey()` để máy chủ phân bổ energy, vượt trạm và unlock atomically;
- `complete_mission()` tự invalidate dashboard sau khi engine journey chạy.

Các response lỗi không được hiển thị nguyên văn nhằm tránh lộ chi tiết DB.

## Kiểm thử

- Unit test mapper phải bao phủ trạng thái chưa khởi hành và tỉnh đang tiến hành,
  bao gồm collectible đã mở khóa.
- Integration test DB hiện xác nhận mốc 10 energy hoàn thành checkpoint đầu và mở
  landmark + food.
- E2E trên Android emulator với tài khoản QA đã xác nhận: bắt đầu hành trình ở Hà
  Nội phân bổ 5/10 energy; hoàn thành nhiệm vụ thứ hai đưa tổng điểm lên 10, tự
  hoàn tất trạm 1, chuyển sang trạm 2, cập nhật tỉnh thành 20% và mở đúng một địa
  danh cùng một món ăn.

## Chưa thuộc phần hoàn thiện này

- chi tiết từng collectible, đánh dấu đã xem và trang bị item;
- bản đồ/artwork thật và catalog nội dung production;
- animation nhận thưởng và lịch sử sự kiện;
- offline-first/cache cục bộ (giai đoạn sau MVP đọc/ghi trực tiếp Supabase).

Liên quan: [Missions và energy](./missions-energy.md),
[Journey DB](../db/journey-rewards.md).
