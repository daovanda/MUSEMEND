# Profile và settings

Trạng thái: `implemented`  
Cập nhật: 2026-09-05

## Mục tiêu và phạm vi

Miền này ánh xạ danh tính Supabase Auth sang hồ sơ ứng dụng và lưu các tùy chọn
cá nhân. Nó không quản lý phiên đăng nhập, OAuth UI, avatar Storage hoặc nội dung
nhật ký.

## Mô hình dữ liệu

- `auth.users` là nguồn danh tính do Supabase Auth quản lý.
- `profiles.id` vừa là khóa chính vừa tham chiếu `auth.users.id` với
  `ON DELETE CASCADE`. Trạng thái tài khoản: `active`, `suspended`, `deleted`.
- `user_settings.user_id` tham chiếu `profiles.id`, là duy nhất cho mỗi người dùng
  và bị cascade khi profile bị xóa.
- `travel_progress` cũng được tạo cùng tài khoản để các RPC năng lượng/hành trình
  luôn có bản ghi ban đầu.

Trigger `on_auth_user_created` gọi `public.handle_new_auth_user()` sau khi thêm
`auth.users`. Hàm tạo idempotent `profiles`, `user_settings`, `travel_progress` và
nhận provider `email`, `google`, `apple` hoặc `anonymous`. Provider không nhận diện
được hiện fallback về `email`.

Các bảng có trigger `set_updated_at()` để cập nhật `updated_at` khi sửa.

## Contract phía client

Client được:

- đọc profile và settings của chính tài khoản đang `active`;
- cập nhật duy nhất `profiles.display_name`;
- cập nhật các cột settings:
  `cloud_name`, `theme_mode`, `language_code`, `sound_enabled`,
  `background_music_enabled`, `notification_enabled`, `daily_reminder_time`,
  `biometric_lock_enabled`, `ai_personalization_enabled`.

Client không được tự cập nhật `account_status`, `deleted_at`, `auth_provider`,
`avatar_url`, khóa sở hữu hay timestamp hệ thống. Yêu cầu xóa tài khoản phải dùng
`request_account_deletion()` được mô tả trong
[notifications-cleanup.md](./notifications-cleanup.md).

## Authentication, RLS và bảo mật

`profiles` và `user_settings` đều bật RLS. Policy dùng `auth.uid()` và
`muse_private.active_user()`; tài khoản đã suspended/deleted không đọc được dữ liệu
ứng dụng. Blanket table grants đã bị thu hồi, sau đó chỉ cấp `SELECT` và quyền
`UPDATE(column-list)` cần thiết cho `authenticated`.

`muse_private.require_user()` là guard của các RPC ghi: yêu cầu JWT hợp lệ, profile
active/chưa soft-delete và khóa row profile `FOR UPDATE`. Row lock này đồng thời
serialize các thay đổi năng lượng/phần thưởng của một user.

## Kiểm thử và tiêu chí nghiệm thu

Integration test tạo hai `auth.users`; trigger bootstrap cho phép cả hai gọi RPC.
Test phân tách user xác nhận user B không thấy journal của user A. Chưa có assertion
riêng cho mọi cột settings được phép/cấm hoặc cho từng OAuth provider.

## Migration, rollback và tương thích

Baseline tạo hai bảng; migration `mvp_security_storage` thay policy rộng bằng quyền
tối thiểu và thay `handle_new_auth_user()` để hỗ trợ provider. Nếu cần đổi trường
profile/settings, dùng migration forward-only và giữ DTO Flutter tương thích trong
giai đoạn rollout. Không rollback bằng cách sửa baseline.

## Giới hạn và việc còn lại

- Chưa có flow cập nhật avatar an toàn hoặc bucket avatar.
- Chưa có flow khôi phục/cancel sau `request_account_deletion()`.
- Provider ngoài danh sách hiện bị ghi thành `email`, cần migration nếu bổ sung.
- Cần test cụ thể cho column-level privileges và trạng thái suspended/deleted.

Liên quan: [migrations-testing.md](./migrations-testing.md),
[notifications-cleanup.md](./notifications-cleanup.md).

