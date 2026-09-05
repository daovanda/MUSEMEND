# Daily check-in và streak client

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-05

## Mục tiêu và phạm vi

Lát cắt P0.2 ghi nhận mở app để tính streak và cho user tạo/sửa một check-in mỗi
ngày theo giờ Việt Nam. P0 dùng năm mood chuẩn `great/good/okay/sad/awful`.

## Luồng và interface

`CheckinRepository` cung cấp `recordAppOpen`, `loadToday`, `saveToday`.
`SupabaseCheckinRepository` gọi RPC `record_app_open()` và
`upsert_daily_checkin(p_mood, p_energy_level, p_note)`; đọc row hôm nay qua RLS.
`ReflectController` tải streak/check-in, còn `ReflectScreen` chỉ render và gửi yêu
cầu. Khi app resume, shell gọi lại RPC; DB đảm bảo idempotent trong cùng ngày.

## Quy tắc dữ liệu và lỗi

- Ngày client dùng UTC+7 để truy vấn nhất quán với DB.
- Mood ánh xạ cố định; mood score, user, ngày và timestamp do DB quyết định.
- Energy level không bắt buộc, nếu có là 1–5; note tối đa 500 ký tự ở UI.
- Check-in lần sau cập nhật row cùng ngày thay vì tạo row mới.
- Tải lỗi có retry; lưu lỗi không hiện chi tiết DB và không báo thành công giả.

## Bảo mật và riêng tư

Không gửi `user_id`, `mood_score` hoặc ngày do UI chọn. RLS giới hạn row theo
`auth.uid()`. Mood/note không được ghi log, analytics hoặc notification lock screen.
Ứng dụng không diễn giải mood thành chẩn đoán sức khỏe tinh thần.

## Kiểm thử và nghiệm thu

Unit test bảo vệ mapping enum. Widget/integration test tiếp theo phải kiểm tra năm
lựa chọn, loading/error/retry, sửa trong ngày, mở app lặp, ranh giới ngày Việt Nam
và phân tách hai tài khoản. DB tests là nguồn nghiệm thu cho score và idempotency.

## Tương thích, rollback và việc còn lại

Không đổi schema trong lát cắt này. Có thể thay Supabase adapter bằng local-first
adapter sau `CheckinRepository`. Còn thiếu artwork mây chính thức, golden/
accessibility test và mapping nhãn mood phong phú từ Figma.

## Liên quan

- [DB daily check-in và streak](../db/daily-checkins-streak.md)
- [UI direction](./ui-design-direction.md)
- [Roadmap MVP](../other/mvp-roadmap.md)
