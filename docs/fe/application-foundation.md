# Flutter application foundation

**Trạng thái:** `implemented`
**Cập nhật:** 2026-09-05

## Mục tiêu và phạm vi

Khởi tạo client Flutter Android/iOS tại `app/`, định danh
`com.musemend.app`, cấu hình môi trường, theme, dependency injection, auth-aware
router và shell bốn vùng Reflect/Journal/Library/Profile.

## Thiết kế và module

- `lib/main.dart` chỉ khởi động ứng dụng.
- `lib/bootstrap.dart` validate cấu hình, khởi tạo Supabase và Riverpod.
- `lib/app/` chứa router, shell và design token; không chứa nghiệp vụ feature.
- `lib/core/` chứa cấu hình và adapter provider dùng chung.
- `lib/features/` tổ chức feature-first theo domain/data/application/presentation.

Riverpod cung cấp dependency/state; go_router redirect theo session. Journal và
Library hiện chỉ là màn hình giữ chỗ, không được xem là feature đã hoàn thành.

## Cấu hình và interface

`AppConfig` nhận `APP_ENV`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` qua
`--dart-define-from-file`. URL bắt buộc HTTPS và key không được rỗng. File local
`config/*.json` bị ignore; chỉ các file `*.example.json` được commit.

## Validation, lỗi và bảo mật

Thiếu/sai cấu hình làm bootstrap dừng sớm. Client không nhận service-role key,
database password hay cleanup secret. Router không đưa token/PII vào URL và xóa
giao diện authenticated khi session mất.

## Kiểm thử và nghiệm thu

Chạy `dart format`, `flutter analyze`, `flutter test` và build APK debug. Cấu hình
parser có unit test. Nghiệm thu khi Android/iOS cùng dùng ID đã chốt và presentation
không import Supabase ngoài adapter/error translation cần thiết.

## Tương thích, rollback và việc còn lại

Flutter được pin bằng `.fvmrc` ở 3.29.2; dependency được khóa trong
`pubspec.lock`; Android NDK được pin theo phiên bản cao nhất dependency yêu cầu.
Release Android không dùng debug signing key. Rollback bằng revert commit, không
đổi ID sau khi phát hành nếu không có migration sản phẩm. Cần bổ sung localization,
asset chính thức, golden test và signing bằng CI secret ở P0.8.

## Liên quan

- [ADR kiến trúc client](../other/adr-0001-mvp-client-architecture.md)
- [UI direction](./ui-design-direction.md)
- [CI/CD](../other/ci-cd.md)
