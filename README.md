# MuseMend

Ứng dụng nhật ký chữa lành trên Flutter cho Android/iOS, kết hợp check-in cảm xúc,
nhiệm vụ tích lũy năng lượng và hành trình khám phá Việt Nam. Backend MVP sử dụng
Supabase Auth, PostgreSQL/RLS/RPC, Storage, Edge Functions và Cron.

## Trạng thái

Dự án đã có Android internal MVP để bắt đầu nghiệm thu trên thiết bị thật:

- Database MVP, migrations, RLS/RPC và dữ liệu catalog demo đã có.
- Edge Function cleanup và scheduler đã được triển khai ở môi trường Supabase Dev.
- Flutter client feature-first đã có các vertical slice Auth/Profile, Reflect,
  Mission/Energy, Journey/Library, Journal/Media, Future Letter và notification.
- CI/CD Flutter + Supabase đang hoạt động; CI trên `develop` phát hành APK release
  đã ký dưới dạng GitHub prerelease.
- iOS hiện được kiểm tra bằng simulator build; signing/TestFlight và thiết bị thật
  được tạm hoãn.

Bản Android QA đầu tiên:
[MuseMend `0.1.0+1`](https://github.com/daovanda/MUSEMEND/releases/tag/qa-v0.1.0-1-e679e367ade5).
Kết quả QA thiết bị thật phải được ghi theo
[checklist nghiệm thu Android](./docs/other/android-device-qa-acceptance.md).

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
app/                 Flutter Android/iOS (`com.musemend.app`)
docs/                tài liệu kiến trúc, feature, DB và vận hành
supabase/
  migrations/        nguồn sự thật của schema
  functions/         Edge Functions
  tests/             integration tests RPC/RLS
tools/db-validation/ validator migration PostgreSQL nhúng
.github/workflows/   CI và deploy Dev/Production
```

## Chạy Flutter client

Yêu cầu Flutter 3.29.2. Tạo cấu hình cục bộ từ file mẫu và điền Supabase Dev URL
cùng publishable key; file thật đã được `.gitignore` bảo vệ:

```powershell
Copy-Item app/config/dev.example.json app/config/dev.json
cd app
flutter pub get
flutter run --dart-define-from-file=config/dev.json
```

Mobile app chỉ được dùng publishable key. Không đặt service-role key, database
password hoặc cleanup secret trong `app/config/` hay mã Dart.

## Kiểm tra backend cục bộ

Yêu cầu Node.js tương thích với lockfile:

```powershell
npm ci --prefix tools/db-validation
node tools/db-validation/validate.mjs
```

Kiểm tra Flutter trước khi tạo PR:

```powershell
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/dev.json
```

## Git flow

```text
feature/* hoặc fix/* → PR + CI + review → develop → QA
develop → release/* → main + tag → production approval
```

Xem [CI/CD](./docs/other/ci-cd.md) và
[release runbook](./docs/other/release-runbook.md) để biết chi tiết.
