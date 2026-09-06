# Database documentation

Trạng thái: `implemented`  
Cập nhật: 2026-09-05

Đây là chỉ mục kỹ thuật cho PostgreSQL/Supabase của MuseMend. Nguồn sự thật của
schema là các migration trong `supabase/migrations/`; snapshot baseline chỉ mô tả
schema trước đợt hardening MVP và không đại diện cho trạng thái cuối cùng.

## Tài liệu theo miền

- [Profile và settings](./profiles-settings.md)
- [Daily check-in và streak](./daily-checkins-streak.md)
- [Missions và energy](./missions-energy.md)
- [Journey, checkpoints và rewards](./journey-rewards.md)
- [Journals, tags và media](./journals-media.md)
- [Notifications, cleanup và account deletion](./notifications-cleanup.md)
- [Migrations, seed và kiểm thử](./migrations-testing.md)

## Ranh giới truy cập

- Flutter dùng role `authenticated`, đọc dữ liệu qua RLS và chỉ sửa trực tiếp
  các cột đã được cấp quyền rõ ràng.
- Năng lượng, nhiệm vụ, tiến độ, unlock, nhật ký và xóa tài khoản đi qua RPC.
- Worker cleanup dùng `service_role`; key này không được đưa vào ứng dụng.
- Các hàm nội bộ nằm trong schema `muse_private`; client không có quyền thực thi,
  ngoại trừ hai predicate dùng cho RLS/Storage là `active_user()` và
  `can_access_journal_object(text)`.

Mọi thay đổi schema tiếp theo phải là migration mới, cập nhật tài liệu miền trong
cùng PR và bổ sung test tương ứng. Không sửa migration đã chạy trên môi trường dùng
chung.
