# Edge Function `musemend-cleanup`

Trạng thái: `implemented` và deployed  
Cập nhật: 2026-09-05

## Mục tiêu và phạm vi

Function thực hiện hai thao tác mà PostgreSQL không nên tự làm: xóa object bằng
Supabase Storage API và xóa Auth user bằng Admin API. Database chịu trách nhiệm
queue, lease, retry timing và xác định account đủ điều kiện; function chỉ điều phối.

Source: `supabase/functions/musemend-cleanup/index.ts`  
Endpoint: `https://jpoktrdyehalxkhdhkzu.supabase.co/functions/v1/musemend-cleanup`

Audit remote ngày 2026-09-05 xác nhận function `ACTIVE`, version 2 và source remote
khớp nội dung file cục bộ tại thời điểm audit.

## HTTP contract

Scheduler hiện gửi:

```http
POST /functions/v1/musemend-cleanup
Content-Type: application/json
x-cleanup-secret: <secret từ Vault>

{}
```

Body không được sử dụng. Implementation hiện không giới hạn HTTP method; đây là
giới hạn cần harden, không phải contract để client dựa vào.

Kết quả:

- `401 text/plain`: thiếu/sai secret hoặc Edge secret chưa cấu hình.
- `200 application/json`: `{ "processed": [...] }`; mỗi phần tử mô tả object đã
  remove hoặc account đã delete.
- `500 application/json`: claim queue hoặc liệt kê account ready thất bại; response
  có trường `error`.

Endpoint không dành cho Flutter và không được gọi bằng anon/publishable key.

## Authentication và secret

`verify_jwt=false` có chủ đích vì request cron không mang user JWT. Function tự xác
thực header `x-cleanup-secret` với Edge secret `MUSEMEND_CLEANUP_SECRET`.

Runtime tự cung cấp `SUPABASE_URL` và `SUPABASE_SERVICE_ROLE_KEY`. Service-role key
chỉ được dùng bên trong function với session persistence tắt. Không đưa ba giá trị
này vào client, Git, response hay log.

Cron đọc cùng giá trị từ Vault secret `musemend_cleanup_secret`. Khi rotate, cập
nhật cả Edge Secret và Vault, gọi smoke test, rồi xác nhận cron thành công. Nếu một
bên lệch, mọi request sẽ 401 nhưng dữ liệu vẫn còn trong queue để chạy lại.

## Luồng xử lý

1. So khớp cleanup secret; fail closed nếu env không tồn tại.
2. Gọi `claim_storage_cleanup(p_limit=50)` bằng service role.
3. Xóa tuần tự mỗi object từ bucket/path do database trả về.
4. Gọi `finish_storage_cleanup(id, lease_token, error)` cho từng job.
5. Gọi `list_ready_account_deletions()` (tối đa 100 user).
6. Gọi `auth.admin.deleteUser(user_id)` cho từng account ready.
7. Trả danh sách kết quả.

Storage lỗi được chuyển lại thành job pending sau 15 phút; lease 10 phút cho phép
worker khác lấy lại job bị bỏ dở. Xóa object là idempotent về mục tiêu. Auth deletion
không có job riêng nhưng account request vẫn còn nên lần cron sau sẽ thử lại cho tới
khi Auth user bị xóa.

Chi tiết queue/retention: [Notifications và cleanup](../db/notifications-cleanup.md).

## Scheduler và vận hành

Cron `musemend-cleanup-worker` chạy mỗi 5 phút qua `pg_net`, HTTP timeout 10 giây.
Migration deploy scheduler yêu cầu Vault secret tồn tại và sẽ fail nếu thiếu.

Khi điều tra sự cố, kiểm tra theo thứ tự:

1. cron job còn active và lịch sử run không lỗi;
2. HTTP status của `pg_net` (đặc biệt 401/timeout);
3. Edge Function logs nhưng không sao chép secret/PII;
4. số job theo status, `attempts`, `last_error`, `lease_until`;
5. object Storage còn tồn tại và account deletion request còn pending.

Không chỉnh queue/lease bằng client hoặc Dashboard để “bỏ qua” lỗi. Sửa nguyên nhân
và để cơ chế retry xử lý, hoặc dùng runbook/admin migration có audit.

## Logging, privacy và lỗi

Function hiện không ghi log có cấu trúc. Response chứa ID job/user và thông báo lỗi
từ SDK; endpoint được bảo vệ nhưng vẫn không nên lưu response lâu hơn nhu cầu vận
hành. Tuyệt đối không bổ sung log request headers, service key, cleanup secret, nội
dung journal hoặc object signed URL.

## Kiểm thử và tiêu chí nghiệm thu

Đã xác minh remote function active và cron active. Integration SQL chỉ test logic
DB liên quan, không chạy Deno function. Chưa có automated test cho:

- request thiếu/sai/đúng secret;
- Storage success, not-found và provider error;
- finish RPC thất bại sau khi object đã xóa;
- Auth deletion/cascade end-to-end;
- timeout, batch lớn, concurrent workers và secret rotation.

Trước production cần một test Supabase Dev tạo object/account giả, queue deletion,
chờ cron, xác nhận Storage + Auth + relational data đều được dọn và không ảnh hưởng
user khác.

## Deploy, rollback và tương thích

Deploy source cùng `verify_jwt=false`; chỉ giữ cấu hình này khi custom-secret guard
còn tồn tại và được test. Thay đổi RPC worker phải triển khai theo thứ tự tương thích
ngược: database trước, Edge Function sau. Rollback function về version trước chỉ an
toàn khi signatures RPC vẫn tương thích; nếu không, pause cron trước.

## Giới hạn và việc còn lại

- Enforce `POST`; từ chối method khác và cân nhắc giới hạn content length.
- Pin chính xác phiên bản `@supabase/supabase-js` thay vì chỉ major `@2`.
- Thêm structured logs, request/correlation ID, metrics và alert cho retry/401/5xx.
- Batch đang xử lý tuần tự và có thể vượt HTTP timeout 10 giây; cần đo rồi điều chỉnh.
- Chuẩn hóa error response để không trả raw provider/database message.
- Thêm integration test Deno/Supabase Dev và runbook rotate secret.

Liên quan: [Backend index](./README.md),
[Database cleanup](../db/notifications-cleanup.md).

