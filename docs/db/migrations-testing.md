# Migrations, seed và kiểm thử database

Trạng thái: `implemented` cho migration MVP; coverage còn giới hạn  
Cập nhật: 2026-09-12

## Nguồn sự thật và baseline

Thứ tự file trong `supabase/migrations/` là nguồn sự thật. Migration
`20260905042807_adopt_mvp_baseline.sql` bootstrap schema nếu
`public.profiles` chưa tồn tại; trên project MVP đã có schema, nó là no-op để nhận
quản lý trạng thái có sẵn. `supabase/baseline/schema_snapshot.json` là metadata
trước hardening, không bao gồm các bảng/RPC/policy về sau.

Không sửa migration đã chạy. Mọi sửa lỗi dùng migration timestamp mới và chiến
lược expand → migrate → contract khi có client cũ.

## Lịch sử đã áp dụng

Các migration tới `20260907150000` đã có trên nhánh phát triển; dòng
`20260908110000` đang chờ CI/deploy cùng content pack:

| Version | Migration | Trách nhiệm |
|---|---|---|
| `20260905042807` | `adopt_mvp_baseline` | Nhận/bootstrap schema ban đầu |
| `20260905042816` | `mvp_core` | Account guard, check-in, streak, mission core, relation trigger |
| `20260905042822` | `mvp_journey` | Journey/reward engine và complete mission |
| `20260905042828` | `mvp_journals` | Atomic journal, future letter, soft-delete, queue |
| `20260905042836` | `mvp_security_storage` | Least privilege, RLS, private bucket, media RPC, auth bootstrap |
| `20260905042846` | `mvp_operations` | Cleanup lease RPC, housekeeping, final grants |
| `20260905042852` | `mvp_demo_catalog` | Catalog/sample mission idempotent |
| `20260905042858` | `schedule_housekeeping` | Cron mỗi phút |
| `20260905042933` | `fix_checkin_rpc_signature` | Loại overload `smallint` |
| `20260905043212` | `restrict_checkin_rpc` | Khóa lại execute ACL check-in |
| `20260905053723` | `schedule_cleanup_worker` | `pg_net` cron + Vault secret |
| `20260906001034` | `mvp_journal_tags_rpc` | Atomic journal + tags và ownership guard |
| `20260907100000` | `home_mission_defaults` | Hai nhiệm vụ Home mặc định, tạo idempotent |
| `20260907120000` | `daily_journal_one_per_day` | Một daily journal mỗi user/ngày Việt Nam và revoke RPC nền |
| `20260907150000` | `journal_media_transforms` | Metadata vị trí, scale, xoay ảnh và RPC owner-scoped |
| `20260908110000` | `curated_world_catalog` | 10 điểm đến/trạm/reward và 10 mission template curated |
| `20260911140000` | `mission_scheduling_and_recurrence` | Lịch mission, daily series, expire/refresh RPC |
| `20260912090000` | `daily_quotes` | 100 daily quote và RPC xoay theo ngày Việt Nam |
| `20260912140000` | `global_destinations` | Đổi schema tỉnh thành điểm đến toàn cầu, giữ nguyên dữ liệu/ID/RLS |

## Quy ước migration

- DDL, RLS, grants, function, trigger, extension, cron và seed đều phải có migration.
- Không hard-code ID sinh tự động; seed catalog dùng natural code + `ON CONFLICT`.
- Bảng user-owned phải bật RLS, index cột owner/lookup và test bằng hai user.
- `SECURITY DEFINER` phải `SET search_path=''`, tham chiếu object đầy đủ schema,
  kiểm tra `auth.uid()` và revoke execute mặc định trước khi grant cụ thể.
- Không đưa secret/value Vault vào migration; migration chỉ tham chiếu tên secret.
- Thay đổi rủi ro production cần backup, manual approval và kế hoạch forward fix.

## Chạy validation cục bộ

```powershell
node tools/db-validation/validate.mjs
```

Runner dùng PGlite, dựng stub tối thiểu cho `auth`, `storage` và các role Supabase,
apply migration `.sql` theo tên rồi chạy `supabase/tests/mvp_integration.sql` trong
transaction được rollback.

Runner cố ý bỏ qua mọi file có chuỗi `schedule`; vì vậy hai migration cron, extension
hosted, Vault và `pg_net` **không được chứng minh** bởi validation cục bộ. Đây là
smoke/integration test logic, không thay thế `supabase db reset`, staging hoặc test
trên PostgreSQL/Supabase thật.

## Coverage hiện tại

Đã có test cho:

- bootstrap hai auth user và phân tách journal qua RLS;
- one-check-in-per-day, sửa check-in và streak idempotent;
- custom reward 5, complete idempotent, energy/journey/reward cơ bản;
- daily schedule/series, refresh idempotent, missed → expired, boundary tuần/
  tháng/năm và custom range;
- daily/yearly/future-letter save và quan hệ cùng owner;
- due notification và soft-delete visibility.
- journal tags chuẩn hóa/khử trùng, lưu atomic và chặn gắn tag chéo user;
- daily journal một-mục-mỗi-ngày, tái sử dụng khi gọi tạo trùng và chặn đổi sang
  ngày đã có mục khác;
- cập nhật metadata vị trí/scale/góc xoay media và chặn user khác sửa transform;
- số lượng, country metadata, artwork path và reward của curated catalog;
- nâng cấp tên bảng/khóa ngoại toàn cầu, backfill quốc gia và loại bỏ bảng tỉnh cũ;
- 100 daily quote, phân bổ đều năm chủ đề, vòng quay ổn định và đổi theo ngày;
- cột profile/settings được phép, cột trạng thái bị chặn và account deletion khóa profile.

Chưa có test cho:

- matrix RLS/column grants đầy đủ và role `anon`;
- concurrent calls, deadlock/load, mọi constraint và invalid payload;
- Storage MIME/size/object policies qua API thật;
- cleanup lease/retry, cron/HTTP, hard delete Storage/Auth và account deletion worker E2E;
- migration catalog từ dữ liệu production lớn và rollback/restore;
- Flutter contract hoặc local/push notification.

## Tiêu chí nghiệm thu migration mới

1. Replay thành công từ database sạch và nâng cấp thành công từ schema trước đó.
2. Test positive + negative cho RPC/RLS/constraint bị ảnh hưởng.
3. Hai user không đọc/ghi chéo; `anon` và client không gọi internal RPC.
4. `git diff --check`, formatter/linter và database tests đều đạt.
5. Tài liệu miền, rollout và rollback được cập nhật trong cùng PR.
6. Với cron/Storage/Auth, có smoke test trên Supabase Dev và quan sát log/job status.

## Rollback và giới hạn vận hành

Repo không duy trì down migration tự động. Với thay đổi đã deploy, ưu tiên migration
forward sửa lỗi; chỉ rollback app nếu schema vẫn tương thích ngược. Trước thao tác
xóa/đổi kiểu dữ liệu production phải backup và kiểm tra restore.

Hiện bằng chứng repo chỉ thể hiện một project Supabase đã kết nối; việc tách Dev và
Production, promotion pipeline, backup/restore drill và security regression suite
cần được hoàn thiện trước khi có dữ liệu người dùng thật.

Liên quan: [README](./README.md),
[notifications-cleanup.md](./notifications-cleanup.md).
