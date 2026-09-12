# Missions và energy

Trạng thái: `in-progress`
Cập nhật: 2026-09-11

## Mục tiêu và phạm vi

Miền này tạo nhiệm vụ từ catalog hoặc do user tự viết, hoàn thành nhiệm vụ một lần
và cộng năng lượng trong cùng transaction. Năng lượng là điểm tích lũy; phần đã
phân bổ cho hành trình được theo dõi riêng bằng `journey_energy_used`.

## Mô hình dữ liệu

- `mission_templates`: catalog do server quản lý, gồm loại nhiệm vụ, mood mục tiêu,
  phần thưởng mặc định và trạng thái active.
- `mission_template_translations`: tiêu đề/mô tả gợi ý Muse theo locale; tiếng
  Việt là bản tham chiếu biên tập, tiếng Anh là fallback runtime.
- `user_missions`: snapshot title/description/reward tại lúc tạo; `start_at` và
  `due_at` là khoảng hiệu lực; `occurrence_key` chống tạo trùng.
- `recurrence_series_id` chỉ áp dụng cho daily mission. Mọi occurrence trong cùng
  chuỗi giữ nguyên snapshot và giờ bắt đầu/kết thúc; occurrence lịch sử không bị
  xóa để còn audit.
- `energy_transactions`: sổ giao dịch bất biến phía client; unique một nguồn cho
  `(user_id, source_type, source_id)` khi có `source_id`.
- `travel_progress.current_energy`: tổng điểm hiện có; không giảm khi qua trạm.
- `travel_progress.lifetime_energy`: tổng năng lượng đã kiếm.
- `travel_progress.journey_energy_used`: phần điểm tích lũy đã phân bổ để vượt các
  checkpoint, luôn không âm.

## RPC contract

### `create_scheduled_mission(...)`

Đây là command chính cho client mới. Client gửi loại, template hoặc nội dung tự
tạo, cùng lịch cần thiết; không được gửi reward.

- `daily`: bắt buộc `start_at`/`due_at`, cùng ngày Việt Nam hiện tại và end sau
  start. Server tạo `recurrence_series_id`; ngày sau `refresh_scheduled_missions`
  sinh occurrence giống gần nhất. Buổi được suy ra từ giờ bắt đầu: sáng 05:00–
  11:59, chiều 12:00–16:59, tối 17:00–21:59, còn lại là bất kỳ lúc nào.
- `weekly`: server bỏ qua mốc client và đặt hết hạn 00:00 thứ Hai kế tiếp.
- `monthly`: hết hạn 00:00 ngày đầu tháng kế tiếp.
- `yearly`: hết hạn 00:00 ngày 01/01 năm kế tiếp.
- `custom`: bắt buộc đầy đủ ngày/giờ bắt đầu và kết thúc; end phải ở tương lai và
  sau start.
- Nhiệm vụ tự tạo thuộc bất kỳ loại nào vẫn thưởng cố định 5. Template phải active,
  đúng loại và đúng mood/check-in của user nếu template yêu cầu.
- `p_request_id` là UUID idempotency. Daily dùng UUID này làm định danh chuỗi;
  template daily đã được chọn không tạo thêm chuỗi thứ hai.

### `refresh_scheduled_missions()`

Được gọi trước khi tải dashboard. Trong một transaction ngắn, hàm đổi pending/
in-progress đã quá `due_at` thành `expired`, rồi materialize tối đa một daily
occurrence cho ngày Việt Nam hiện tại ở mỗi chuỗi. Gọi lặp không tạo trùng.
Weekly/monthly/yearly/custom không tự tái tạo sau khi hết hạn.

### `create_mission(p_template_id?, p_title?, p_description?, p_checkin_id?, p_request_id?)`

- Nếu không có template: title sau trim dài 1–200, không cho giả làm mood mission,
  `source_type=user_created`, `mission_type=custom`, thưởng luôn là **5**.
- `p_request_id` tạo occurrence key idempotent cho request custom. Nếu bỏ trống,
  server tạo UUID mới; không có giới hạn số nhiệm vụ custom.
- Nếu dùng template: template phải active; check-in nếu truyền phải thuộc user;
  template theo mood phải khớp check-in của ngày Việt Nam hiện tại.
- Daily/weekly/monthly/yearly dùng occurrence key theo kỳ và tính `due_at` theo
  `Asia/Ho_Chi_Minh`; loại khác dùng key `once`.
- Trả về row `user_missions` đã tạo hoặc row trùng occurrence hiện có.

RPC cũ được giữ tạm để tương thích với client/replay cũ; Flutter mới không dùng
RPC này để tạo nhiệm vụ.

### `update_custom_mission(p_mission_id, p_title, p_description?)`

Chỉ sửa nhiệm vụ `user_created`, chưa xóa, trạng thái `pending`/`in_progress` và
thuộc user. Title sau trim phải dài 1–200. Không sửa reward hay nguồn.

### `skip_mission(p_mission_id)`

Chuyển nhiệm vụ own `pending`/`in_progress` sang `skipped`; không cộng năng lượng.

### `complete_mission(p_mission_id)`

- Khóa mission và khóa profile user trong transaction.
- Chỉ nhận mission own, chưa xóa, chưa quá hạn và đang pending/in-progress.
- Custom luôn lấy reward server-side là 5; template dùng snapshot do server tạo.
- Cộng `current_energy`/`lifetime_energy`, ghi `energy_transactions`, đánh dấu
  completed/reward claimed, ghi travel event và gọi tiến hành journey atomically.
- Gọi lại sau khi đã nhận thưởng trả
  `{ mission_id, already_completed: true, reward }` và không cộng đôi.
- Lần đầu trả cùng cấu trúc với `already_completed: false`.

## Authentication, RLS và bảo mật

`authenticated` chỉ đọc mission, transaction và travel progress của mình. Không có
quyền client ghi reward, balance, trạng thái hoàn thành hoặc transaction. Tất cả
RPC là `SECURITY DEFINER`, `search_path=''`, gọi `require_user()` và đã thu hồi
execute khỏi `PUBLIC`/`anon`.

Khóa profile nhất quán serialize thay đổi reward cho cùng user; unique source của
energy transaction là lớp bảo vệ bổ sung. Client phải coi `complete_mission` là
command idempotent, không tự cộng số hiển thị trước khi nhận dữ liệu server.

## Kiểm thử

Integration test xác nhận reward 5, completion idempotent, daily scheduling và
validation, refresh idempotent, missed → expired, boundary tuần/tháng/năm,
custom range và journey reward. Chưa có stress test concurrent, boundary năm
nhuận hoặc template theo mọi mood.

## Migration, seed và rollback

`mvp_core` thêm occurrence key và RPC create/update/skip; `mvp_journey` thêm RPC
complete. Demo seed có 10 template (9 daily, 1 weekly), tất cả reward 5. Migration
`home_mission_defaults` bổ sung template `demo-walk` và RPC
`ensure_home_missions()` để materialize hai nhiệm vụ starter (`demo-water` và
`demo-walk`). Migration `mission_scheduling_and_recurrence` thêm lịch rõ ràng,
daily series, RPC create/refresh và chuyển các daily template occurrence cũ sang
series theo `(user_id, template_id)`. Hai starter mới dùng lịch cả ngày 00:00–
23:59:59 và nằm trong nhóm “Bất kỳ lúc nào”; tài khoản cũ giữ giờ của occurrence
gần nhất.
Migration cũng thêm một gợi ý yearly và một gợi ý custom để catalog có đủ năm
loại mà UI cho phép chọn; daily/weekly/monthly tiếp tục dùng catalog hiện có.
Catalog thật phải dùng migration seed idempotent mới; không thay đổi snapshot mission đã
tạo. Rollback logic reward cần migration bù trừ/audit, không xóa transaction cũ.

## Giới hạn và việc còn lại

- Mission quá hạn được đổi thành `expired` khi dashboard gọi refresh; không phụ
  thuộc cron, nên có thể vẫn mang status cũ trong DB cho tới lần mở app kế tiếp.
- Không có giới hạn custom mission theo ngày theo quyết định MVP; cần chống spam ở
  tầng UX/rate limit nếu lạm dụng trở thành vấn đề.
- Chưa có admin workflow quản trị template ngoài migration/service role.
- Chưa có pagination contract và retention cho lịch sử transaction/mission.

Liên quan: [journey-rewards.md](./journey-rewards.md),
[daily-checkins-streak.md](./daily-checkins-streak.md).

