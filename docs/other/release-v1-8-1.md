# Android QA release 1.8.1

- **Trạng thái:** `in-progress`
- **Cập nhật:** 2026-09-16

## Mục tiêu

Phát hành bản Android QA `1.8.1+1` với logo mascot đám mây nhất quán ở bước
cá nhân hóa onboarding và thanh thương hiệu trong ứng dụng.

## Luồng phát hành

1. Commit trên nhánh feature/fix và tạo PR vào `develop`.
2. Squash merge sau khi CI và review đạt.
3. CI trên `develop` tạo artifact/release Android QA theo version trong
   `app/pubspec.yaml`.

## Kiểm thử và nghiệm thu

- `flutter analyze` không có issue.
- `flutter test` đạt toàn bộ test hiện có.
- Onboarding preview hiển thị ảnh `mascot-cloud.png` ở huy hiệu trung tâm của
  bước cá nhân hóa; hai bước trước vẫn giữ icon tay và khiên.
- Logo không làm thay đổi luồng vuốt, nút quay lại, bỏ qua hoặc hoàn tất
  onboarding.

## Rollback và bảo mật

Đây là thay đổi asset/UI phía client, không có migration hoặc quyền mới. Nếu QA
không đạt, rollback bằng một commit tiếp theo để trả huy hiệu về icon cũ; không
đưa secret, token hoặc dữ liệu người dùng vào commit.

Liên kết: [Onboarding tài khoản mới](../fe/new-user-onboarding.md),
[Android QA Release](./android-qa-release.md), [CI/CD](./ci-cd.md).
