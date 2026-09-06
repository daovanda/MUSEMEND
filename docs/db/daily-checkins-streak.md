# Daily check-in và streak

Trạng thái: `implemented`  
Cập nhật: 2026-09-05

## Mục tiêu và phạm vi

Miền này lưu một check-in có thể sửa cho mỗi ngày Việt Nam và tính streak từ các
ngày ứng dụng được mở. Check-in và app-open là hai tín hiệu độc lập.

## Mô hình và quy tắc dữ liệu

`daily_checkins` chứa mood, `mood_score`, mức năng lượng tùy chọn và ghi chú ngắn.
`checkin_date` được sinh từ `checkin_at` theo `Asia/Ho_Chi_Minh`; unique constraint
`(user_id, checkin_date)` đảm bảo mỗi ngày một bản ghi. Mood và score phải khớp:
`awful=1`, `sad=2`, `okay=3`, `good=4`, `great=5`. `energy_level`, nếu có, nằm
trong 1–5.

`daily_visits` có khóa chính `(user_id, visit_date)`. Một ngày mở app nhiều lần chỉ
tạo một row. Streak là số ngày liên tiếp lùi từ ngày hiện tại và chỉ có giá trị nếu
hôm nay đã được ghi nhận.

## RPC contract

### `upsert_daily_checkin(p_mood, p_energy_level?, p_note?)`

- Quyền: `authenticated` với profile active.
- Trả về: row `daily_checkins` vừa tạo hoặc cập nhật.
- Hành vi: upsert theo user/ngày Việt Nam; lần gọi sau sửa cùng row và khôi phục
  `deleted_at` về `NULL`.
- Lỗi: chưa đăng nhập/tài khoản không active; enum mood sai; energy ngoài 1–5.
- Client không truyền `user_id`, `mood_score`, `checkin_date` hay timestamp.

### `record_app_open()`

- Quyền: `authenticated` với profile active.
- Trả về JSON `{ "visit_date": "YYYY-MM-DD", "streak": number }`.
- Idempotent trong ngày. App nên gọi sau khi khôi phục session ở mỗi launch/resume;
  UI dùng kết quả trả về thay vì tự tính bằng đồng hồ thiết bị.

## Quan hệ và bảo mật

Client chỉ có `SELECT` row của chính mình và row chưa soft-delete; ghi qua RPC.
Trigger `validate_relations()` từ chối liên kết `daily_journals.checkin_id` hoặc
`user_missions.source_checkin_id` nếu check-in không cùng chủ sở hữu.

## Kiểm thử

`supabase/tests/mvp_integration.sql` xác nhận:

- hai lần upsert trong ngày giữ nguyên ID và còn đúng một check-in;
- mood/note được sửa;
- hai lần record app-open chỉ tạo một visit và streak ban đầu bằng 1;
- user khác không thể dùng check-in làm quan hệ cho journal.

Chưa có test nhiều ngày, biên chuyển ngày/múi giờ, suspended account hoặc gọi đồng
thời.

## Migration và rollback

`mvp_core` thêm unique/check constraint, chuyển default ngày của daily journal sang
giờ Việt Nam và tạo hai RPC. `fix_checkin_rpc_signature` loại overload `smallint`;
contract hiện tại dùng `integer`. Rollback phải là migration mới vì bỏ unique hoặc
đổi timezone có thể làm dữ liệu không còn nhất quán.

## Giới hạn và việc còn lại

- Streak không có grace period, freeze hoặc backfill; thiếu một ngày là reset.
- Múi giờ cố định Việt Nam, chưa hỗ trợ timezone theo tài khoản.
- Check-in hiện không tự thưởng năng lượng.
- Chưa có RPC xóa check-in; `deleted_at` chỉ là phần schema kế thừa.

Liên quan: [journals-media.md](./journals-media.md),
[missions-energy.md](./missions-energy.md).

