# Missions và energy

Trạng thái: `implemented`  
Cập nhật: 2026-09-05

## Mục tiêu và phạm vi

Miền này tạo nhiệm vụ từ catalog hoặc do user tự viết, hoàn thành nhiệm vụ một lần
và cộng năng lượng trong cùng transaction. Năng lượng là điểm tích lũy; phần đã
phân bổ cho hành trình được theo dõi riêng bằng `journey_energy_used`.

## Mô hình dữ liệu

- `mission_templates`: catalog do server quản lý, gồm loại nhiệm vụ, mood mục tiêu,
  phần thưởng mặc định và trạng thái active.
- `user_missions`: snapshot title/description/reward tại lúc tạo; liên kết template
  và check-in là tùy chọn; `occurrence_key` chống tạo trùng.
- `energy_transactions`: sổ giao dịch bất biến phía client; unique một nguồn cho
  `(user_id, source_type, source_id)` khi có `source_id`.
- `travel_progress.current_energy`: tổng điểm hiện có; không giảm khi qua trạm.
- `travel_progress.lifetime_energy`: tổng năng lượng đã kiếm.
- `travel_progress.journey_energy_used`: phần điểm tích lũy đã phân bổ để vượt các
  checkpoint, luôn không âm.

## RPC contract

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

Integration test xác nhận custom reward bằng 5, hai mission tạo tổng 10 energy,
gọi complete lần hai không cộng đôi và mission completion tự tiến hành checkpoint.
Chưa có stress test concurrent, test kỳ weekly/monthly/yearly, quá hạn, template
theo mọi mood hoặc privilege test trực tiếp cho từng cột.

## Migration, seed và rollback

`mvp_core` thêm occurrence key và RPC create/update/skip; `mvp_journey` thêm RPC
complete. Demo seed có 10 template (9 daily, 1 weekly), tất cả reward 5. Catalog
thật phải dùng migration seed idempotent mới; không thay đổi snapshot mission đã
tạo. Rollback logic reward cần migration bù trừ/audit, không xóa transaction cũ.

## Giới hạn và việc còn lại

- Mission quá hạn bị từ chối hoàn thành nhưng chưa có job tự đổi status thành
  `expired`.
- Không có giới hạn custom mission theo ngày theo quyết định MVP; cần chống spam ở
  tầng UX/rate limit nếu lạm dụng trở thành vấn đề.
- Chưa có admin workflow quản trị template ngoài migration/service role.
- Chưa có pagination contract và retention cho lịch sử transaction/mission.

Liên quan: [journey-rewards.md](./journey-rewards.md),
[daily-checkins-streak.md](./daily-checkins-streak.md).

