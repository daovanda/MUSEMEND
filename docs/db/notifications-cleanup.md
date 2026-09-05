# Notifications, cleanup và account deletion

Trạng thái: `implemented` ở database/cleanup và Android client; iOS chưa nghiệm thu
Cập nhật: 2026-09-05

## Mục tiêu và phạm vi

Miền này tạo inbox notification khi future letter đến hạn, soft-delete dữ liệu,
điều phối xóa object Storage và hoàn tất xóa Auth account. Flutter đã đọc inbox và
lên lịch local notification; push notification đa thiết bị chưa nằm trong MVP.

## Mô hình dữ liệu

- `notifications`: row own-user, hiện chỉ có kind `future_letter_due`; unique theo
  `(journal_id, kind, scheduled_for)`.
- `storage_cleanup_jobs`: queue nội bộ cho bucket `journal-media`, gồm lịch chạy,
  trạng thái, attempts, lease 10 phút và lỗi gần nhất.
- `account_deletion_requests`: một yêu cầu idempotent cho mỗi user.

Hai bảng vận hành bật RLS nhưng `authenticated` không có quyền SELECT. Worker dùng
RPC được cấp riêng cho `service_role`.

## Due notification

Cron `musemend-housekeeping` chạy mỗi phút và gọi
`muse_private.housekeeping()`. Hàm `process_due_letters()` dùng
`FOR UPDATE SKIP LOCKED`, tạo notification cho letter đến hạn, đặt
`notification_sent_at`, và đổi `scheduled` thành `available`. Letter `opened` trước
hạn vẫn nhận due notification khi đến thời điểm.

Client đọc own `notifications` qua RLS và gọi
`mark_notification_read(p_id)` để đặt `read_at` lần đầu. Flutter phải tự fetch hoặc
subscribe bảng này; DB row không tự hiện thông báo hệ điều hành. MVP hiện fetch tối
đa 30 row mới nhất, local reminder được lên lịch ngay khi user lưu thư, còn FCM và
Realtime subscription chưa triển khai.

## Soft-delete và retention

- `soft_delete_journal()`/`soft_delete_journal_media()` ẩn dữ liệu ngay và queue
  object với `not_before = deleted_at + 30 days`.
- Housekeeping chỉ hard-delete journal sau retention khi không còn cleanup job chưa
  done và không còn object theo prefix.
- Không có restore contract hiện tại dù object chưa bị xóa trong retention window.

## Xóa tài khoản

`request_account_deletion()` thực hiện trong transaction:

1. tạo request idempotent;
2. soft-delete toàn bộ journal và xóa notification;
3. queue mọi object `journal-media` của user để xóa ngay;
4. đặt profile `account_status=deleted` và `deleted_at`, khiến RLS/RPC khóa account.

Housekeeping tiếp tục quét prefix để bắt object đang upload dở tại thời điểm request.
Sau khi mọi job done và Storage không còn object, worker gọi Supabase Admin Auth
`deleteUser`. Cascade từ `auth.users` dọn profile và dữ liệu quan hệ user-owned.

## Worker RPC contract

Chỉ `service_role` được execute:

- `claim_storage_cleanup(p_limit=50)`: claim 1–100 job due bằng row lock +
  `SKIP LOCKED`, tăng attempts, cấp `lease_token`, lease 10 phút.
- `finish_storage_cleanup(p_id, p_lease, p_error?)`: success → `done`; lỗi →
  `pending`, lưu tối đa 500 ký tự lỗi và retry sau 15 phút; lease sai/hết hạn bị từ
  chối.
- `list_ready_account_deletions()`: trả tối đa 100 user không còn object/job chưa
  hoàn tất.

Edge Function và HTTP authentication được mô tả tại
[musemend-cleanup](../be/musemend-cleanup.md).

## Scheduler và secret

- `musemend-housekeeping`: mỗi phút, chạy SQL nội bộ.
- `musemend-cleanup-worker`: mỗi 5 phút, dùng `pg_net` POST Edge Function với
  timeout 10 giây.
- Header `x-cleanup-secret` được đọc lúc chạy từ Vault secret
  `musemend_cleanup_secret`; Edge Function so khớp với Edge secret
  `MUSEMEND_CLEANUP_SECRET`.

Audit remote ngày 2026-09-05 xác nhận cả hai cron active, Vault secret có tồn tại,
Edge Function active. Không ghi giá trị secret vào log, SQL, docs hoặc client. Khi
rotate phải cập nhật cả Edge Secret và Vault theo một cửa sổ vận hành có kiểm thử.

## RLS và bảo mật

User active chỉ SELECT notification của mình; mark-read kiểm tra owner trong RPC.
Queue/account request không lộ cho client. Các hàm internal không có execute cho
`PUBLIC`, `anon`, `authenticated`; worker RPC chỉ có `service_role`.

## Kiểm thử

Integration test xác nhận due letter tạo đúng notification, soft-delete journal ẩn
dữ liệu và ownership giữa hai account. Chưa có automated test cho queue lease/retry,
Storage delete thật, Auth delete, cron delivery, secret rotation, notification iOS/
FCM hoặc account deletion end-to-end. Android đã xác nhận quyền runtime, lịch alarm,
callback mở Journal; mapper inbox có unit test.

## Migration, rollback và giới hạn

`mvp_operations` tạo worker RPC/housekeeping; `schedule_housekeeping` và
`schedule_cleanup_worker` bật cron. Migration scheduler phụ thuộc hosted Supabase,
`pg_cron`, `pg_net` và Vault secret tồn tại. Rollback an toàn là unschedule job bằng
migration mới trước khi thu hồi function/secret.

Giới hạn đang biết:

- Cron HTTP timeout 10 giây trong khi worker xử lý tuần tự tối đa 50 object rồi tối
  đa 100 account; cần đo production và giảm batch/tăng timeout nếu cần.
- Job `done` của user còn tồn tại trong Auth hiện không được prune; bảng queue có
  thể tăng theo thời gian và unique path khiến filename cũ không nên tái sử dụng.
- Chưa có dead-letter state hoặc cảnh báo khi job retry liên tục.
- Chưa có push provider/device-token schema và chưa có restore/cancel deletion.

Liên quan: [journals-media.md](./journals-media.md),
[migrations-testing.md](./migrations-testing.md).
