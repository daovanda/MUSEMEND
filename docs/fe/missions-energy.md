# Missions và energy client

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-12

## Mục tiêu và phạm vi

Lát cắt P0.3 hiển thị nhiệm vụ đang làm, gợi ý theo mood và loại, cho tạo nhiệm vụ
ngày/tuần/tháng/năm/custom, hoàn thành/bỏ qua và hiển thị năng lượng tích lũy.

## Thiết kế và luồng

`MissionRepository` là contract domain. `SupabaseMissionRepository` gọi
`refresh_scheduled_missions()` rồi `ensure_home_missions()` trước khi đọc
`user_missions`, sau đó đọc
`user_missions`, `mission_templates`, `travel_progress` và chỉ ghi qua RPC.
`MissionsController` lấy check-in hôm nay từ application contract của Reflect để
lọc template và cung cấp `source_checkin_id` khi template yêu cầu mood. Controller
cũng truyền locale đã resolve; repository đọc `mission_template_translations` và
overlay bản dịch lên cả gợi ý Muse lẫn mission tạo từ template. Mission user tự
viết giữ nguyên nội dung.

UI `MissionsSection` nằm sau check-in trên Reflect:

- daily pending/in-progress còn hạn được nhóm theo buổi từ `startAt` ở UTC+7;
  bản ghi đã quá `dueAt` vẫn giữ trong DB để audit nhưng không còn hiển thị trên
  Home;
- hành động hoàn thành/bỏ qua và thêm nhiệm vụ riêng;
- Home/Bầu trời materialize hai nhiệm vụ mẫu nhẹ mỗi ngày (`Uống một cốc nước`,
  `Đi bộ 5 phút`) qua RPC server và hiển thị tối đa năm gợi ý còn lại ngay bên
  dưới để người dùng chọn thêm; chưa có route nhiệm vụ riêng trong MVP;
- bottom sheet bắt buộc chọn loại khi tạo thủ công. Daily chọn giờ/phút bắt đầu và
  kết thúc trong hôm nay; custom chọn đủ ngày/giờ; tuần/tháng/năm hiển thị mốc
  kết thúc cố định do server tính;
- khi chọn template daily/custom, sheet lịch tương ứng mở trước khi gửi command;
  template tuần/tháng/năm dùng boundary server;
- bottom sheet tạo nhiệm vụ dùng khung kính có chiều cao tối đa theo viewport và
  cuộn độc lập khi bàn phím mở; phần `Loại nhiệm vụ` hiển thị trực tiếp năm nút
  viên thuốc Ngày/Tuần/Tháng/Năm/Tùy chỉnh, mặc định chọn Ngày và tự xuống dòng
  trên màn hình hẹp; ngày bắt đầu/kết thúc của loại tùy chỉnh và mọi ô giờ được
  nhập trực tiếp trong khung bằng bàn phím theo `dd/MM/yyyy` và `HH:mm`, không mở
  date/time picker hoặc modal phụ; ngày quá khứ và ngày/giờ không hợp lệ bị từ chối;
- tên và ghi chú của nhiệm vụ tự tạo dùng nhãn cố định phía trên thay vì floating
  label để không chạm viền hoặc đè nội dung khi tăng cỡ chữ;
- bottom sheet thêm gợi ý giữ nguyên loại do template quyết định, hiển thị loại
  và năng lượng bằng badge viên thuốc; tên cùng ghi chú dùng khối chỉ đọc có nhãn
  nằm trong nội dung thay vì floating label để không đè chữ;
- ngoài bốn nhóm daily còn có nhóm nhiệm vụ tuần, tháng, năm và tùy chỉnh; UI chỉ
  dựng tiêu đề của nhóm khi nhóm đó có ít nhất một nhiệm vụ để không hiển thị các
  phần trống;
- tiến độ checkpoint hiển thị `earned_energy/required_energy` từ journey state.

Repository lọc các dòng có `due_at` trong tương lai hoặc `NULL` trước khi dựng
dashboard. Nó cũng chỉ hiển thị một snapshot system cho mỗi `template_id` để
không lặp các starter mission legacy nếu dữ liệu phát triển cũ đã tạo trùng
trước khi `occurrence_key` được áp dụng. Các template đã có occurrence trong
ngày hiện tại (kể cả đã hoàn thành hoặc bỏ qua) không còn hiện nút thêm lần nữa;
nhiệm vụ tự tạo không bị gộp theo tên.

Các nhóm daily là `Buổi sáng` (05:00–11:59), `Buổi chiều` (12:00–16:59),
`Buổi tối` (17:00–21:59) và `Bất kỳ lúc nào` (22:00–04:59), suy ra từ startAt.
Sticker bên phải header hiện là
placeholder code-native vì landmark/food thuộc catalog động; không crop cứng sprite
Figma vào nhiệm vụ. Toàn nhóm nằm trên panel gradient xanh nhạt sang tím nhạt,
bo góc và viền white nhẹ đúng layer Home.

Mọi nhãn, loại nhiệm vụ, validation, lịch và trạng thái rỗng/lỗi của client lấy
từ ARB. Tên/mô tả gợi ý Muse vẫn là catalog động từ
`mission_template_translations`; nhiệm vụ do user tự viết không bị dịch. Icon của
gợi ý dùng ký hiệu trung tính thay vì đoán theo từ khóa tiếng Việt trong nội dung.

## RPC và mapping

- `create_scheduled_mission`: template hoặc user-created với loại/lịch; UUID v4
  chống retry trùng và làm daily series id; client không gửi mức thưởng.
- `refresh_scheduled_missions`: expire nhiệm vụ quá hạn và tạo daily occurrence
  hôm nay từ chuỗi trước đó.
- `complete_mission`: nhận `mission_id`, trả reward/already-completed từ server.
- `skip_mission`: không sửa trực tiếp status.

DTO ánh xạ snapshot DB sang domain. UI không import Supabase và không tự cộng điểm.

## Validation, lỗi và bảo mật

Tên tự tạo sau trim dài 1–200, ghi chú tối đa 500 ở UI. User-created không được gắn
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

Migration `mission_scheduling_and_recurrence` bổ sung lịch và daily series. Client
tạm bỏ qua riêng lỗi PostgREST `PGRST202` cho RPC materialize/refresh trong khoảng
thời gian migration đang triển khai;
các lỗi khác vẫn đi vào trạng thái retry. Repository cho phép thay adapter local-first sau này. Còn thiếu sửa custom mission, pagination/lịch sử, animation
reward, thông báo checkpoint vừa mở và test accessibility/golden.

## Liên quan

- [DB missions và energy](../db/missions-energy.md)
- [DB journey và rewards](../db/journey-rewards.md)
- [Daily check-in](./daily-checkin.md)
- [Home Figma inventory](./home-figma-inventory.md)
