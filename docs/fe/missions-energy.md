# Missions và energy client

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-07

## Mục tiêu và phạm vi

Lát cắt P0.3 hiển thị nhiệm vụ đang làm, gợi ý theo mood, cho tạo nhiệm vụ riêng,
hoàn thành/bỏ qua và hiển thị năng lượng tích lũy. Journey chi tiết và collection
thuộc P0.4.

## Thiết kế và luồng

`MissionRepository` là contract domain. `SupabaseMissionRepository` gọi
`ensure_home_missions()` idempotent trước khi đọc `user_missions`, sau đó đọc
`user_missions`, `mission_templates`, `travel_progress` và chỉ ghi qua RPC.
`MissionsController` lấy check-in hôm nay từ application contract của Reflect để
lọc template và cung cấp `source_checkin_id` khi template yêu cầu mood.

UI `MissionsSection` nằm sau check-in trên Reflect:

- nhiệm vụ pending/in-progress được nhóm theo buổi từ `dueAt` ở UTC+7;
- hành động hoàn thành/bỏ qua và thêm nhiệm vụ riêng;
- Home/Bầu trời materialize hai nhiệm vụ mẫu nhẹ mỗi ngày (`Uống một cốc nước`,
  `Đi bộ 5 phút`) qua RPC server; các gợi ý còn lại vẫn tồn tại ở màn nhiệm vụ
  đầy đủ;
- bottom sheet tạo nhiệm vụ riêng;
- tiến độ checkpoint hiển thị `earned_energy/required_energy` từ journey state.

Các nhóm UI là `Buổi sáng` (<12h), `Bất kỳ lúc nào` (`dueAt == null`),
`Buổi chiều` (12h–16h59) và `Buổi tối` (từ 17h). Sticker bên phải header hiện là
placeholder code-native vì landmark/food thuộc catalog động; không crop cứng sprite
Figma vào nhiệm vụ. Toàn nhóm nằm trên panel gradient xanh nhạt sang tím nhạt,
bo góc và viền white nhẹ đúng layer Home.

## RPC và mapping

- `create_mission`: template hoặc custom; custom dùng UUID v4 làm request id để
  retry không tạo trùng và không gửi mức thưởng từ client.
- `complete_mission`: nhận `mission_id`, trả reward/already-completed từ server.
- `skip_mission`: không sửa trực tiếp status.

DTO ánh xạ snapshot DB sang domain. UI không import Supabase và không tự cộng điểm.

## Validation, lỗi và bảo mật

Tên custom sau trim dài 1–200, ghi chú tối đa 500 ở UI. Custom không được gắn
check-in và luôn nhận reward 5 do DB quyết định. Mood template chỉ hiện khi khớp
check-in hôm nay; template `all` luôn có thể hiện. Lỗi backend được hiển thị chung,
không lộ SQL/schema. Loading khóa thao tác lặp trên section.

RLS chỉ đọc dữ liệu user hiện tại. Client không có quyền ghi bảng mission,
energy transaction, travel progress hoặc unlock. `current_energy` là tích lũy;
`available = current_energy - journey_energy_used`.

## Kiểm thử và nghiệm thu

Unit test bảo vệ mapping DTO và công thức available energy. Cần kiểm thử emulator
với tài khoản demo: thêm template, tạo custom, complete retry, skip, reward 5 và
checkpoint tự tiến hành. DB integration test tiếp tục là nguồn sự thật cho
transaction/idempotency và phân tách user.

## Tương thích, rollback và việc còn lại

Migration `home_mission_defaults` bổ sung starter template và RPC materialize
idempotent. Client tạm bỏ qua riêng lỗi PostgREST `PGRST202` (hàm chưa có trong
schema cache) để giữ khả năng đọc trong khoảng thời gian migration đang triển khai;
các lỗi khác vẫn đi vào trạng thái retry. Repository cho phép thay adapter local-first sau này. Còn thiếu sửa custom mission, pagination/lịch sử, animation
reward, thông báo checkpoint vừa mở và test accessibility/golden.

## Liên quan

- [DB missions và energy](../db/missions-energy.md)
- [DB journey và rewards](../db/journey-rewards.md)
- [Daily check-in](./daily-checkin.md)
- [Home Figma inventory](./home-figma-inventory.md)
