# MuseMend

Ứng dụng nhật ký chữa lành trên Flutter cho Android/iOS, kết hợp check-in cảm xúc,
nhiệm vụ tích lũy năng lượng và hành trình khám phá Việt Nam. Backend MVP sử dụng
Supabase Auth, PostgreSQL/RLS/RPC, Storage, Edge Functions và Cron.

## Trạng thái

Dự án đang ở giai đoạn xây dựng MVP đầu tiên:

- Database MVP, migrations, RLS/RPC và dữ liệu catalog demo đã có.
- Edge Function cleanup và scheduler đã được triển khai ở môi trường Supabase Dev.
- CI/CD cho Flutter + Supabase đã được định nghĩa.
- Flutter client đang được khởi tạo theo kiến trúc feature-first.

Không sử dụng repository hoặc môi trường hiện tại như production cho tới khi hoàn
tất checklist QA/release.

## Bắt đầu

Mọi developer và coding agent phải đọc:

1. [AGENTS.md](./AGENTS.md)
2. [Quy ước kiến trúc và phát triển](./docs/README.md)
3. README/tài liệu trong miền đang thay đổi:
   [FE](./docs/fe/README.md), [BE](./docs/be/README.md),
   [DB](./docs/db/README.md), [Other](./docs/other/README.md)

## Cấu trúc

```text
app/                 Flutter Android/iOS (đang khởi tạo)
docs/                tài liệu kiến trúc, feature, DB và vận hành
supabase/
  migrations/        nguồn sự thật của schema
  functions/         Edge Functions
  tests/             integration tests RPC/RLS
tools/db-validation/ validator migration PostgreSQL nhúng
.github/workflows/   CI và deploy Dev/Production
```

## Kiểm tra backend cục bộ

Yêu cầu Node.js tương thích với lockfile:

```powershell
npm ci --prefix tools/db-validation
node tools/db-validation/validate.mjs
```

Các lệnh Flutter và cấu hình môi trường sẽ được bổ sung khi module `app/` được
scaffold. Không lưu service-role key, database password hoặc cleanup secret trong
repository hay mobile app.

## Git flow

```text
feature/* hoặc fix/* → PR + CI + review → develop → QA
develop → release/* → main + tag → production approval
```

Xem [CI/CD](./docs/other/ci-cd.md) và
[release runbook](./docs/other/release-runbook.md) để biết chi tiết.
