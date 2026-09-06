# Android QA Release qua GitHub Releases

**Trạng thái:** `implemented`
**Cập nhật:** 2026-09-06

## 1. Mục tiêu và phạm vi

Phân phối bản Android QA chính thức mà không cần Google Play Console. CI vẫn
giữ APK debug artifact để kiểm tra nhanh; bản QA dùng APK release có chữ ký ổn
định và được đính kèm vào GitHub Release dạng prerelease.

Package ID cố định là `com.musemend.app`. Bản QA dùng Supabase Development và
không được coi là bản production.

## 2. Luồng phát hành

```text
merge develop
    ↓
CI xanh
    ↓
workflow_run checkout đúng SHA đã CI xác minh
    ↓
build APK release + checksum SHA-256
    ↓
tạo GitHub Release prerelease
    ↓
QA tải APK, kiểm tra checksum và cài thủ công
```

Workflow là `.github/workflows/distribute-android-qa-release.yml`. Nó chạy sau
CI thành công trên `develop` hoặc khi owner gọi thủ công từ `develop`.

Luồng đã được xác minh lần đầu bằng Release
[`qa-v0.1.0-1-e679e367ade5`](https://github.com/daovanda/MUSEMEND/releases/tag/qa-v0.1.0-1-e679e367ade5)
từ commit `e679e367ade59bb2db044fbb2fdd501829f3e895` sau khi CI và deploy Development
đều thành công. Việc phát hành artifact đã hoàn tất; nghiệm thu thiết bị thật được
theo dõi riêng trong checklist liên kết ở cuối tài liệu.

APK debug của workflow `CI` vẫn được lưu 7 ngày dưới dạng artifact. Artifact đó
chỉ dùng để kiểm tra nhanh, không phải kênh phát hành QA chính thức.

## 3. Ký ứng dụng và cấu hình

Không dùng debug key cho bản QA Release. Tạo upload keystore riêng, giữ bí mật
trong GitHub Environment `android-development`, và không commit file `.jks` hoặc
mật khẩu.

Environment `android-development` cần các secrets:

| Secret | Nội dung |
| --- | --- |
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | File upload keystore đã encode Base64 |
| `ANDROID_UPLOAD_STORE_PASSWORD` | Mật khẩu keystore |
| `ANDROID_UPLOAD_KEY_ALIAS` | Alias của upload key |
| `ANDROID_UPLOAD_KEY_PASSWORD` | Mật khẩu key |

Workflow không cần Google Play service account. Repository variables
`SUPABASE_URL` và `SUPABASE_PUBLISHABLE_KEY` được dùng để build client
Development. Publishable key có thể nằm trong APK; keystore và password không
được nhúng vào app.

Gradle chỉ tạo keystore tạm trong thư mục build khi đủ bốn biến ký. Workflow
dừng trước build nếu thiếu cấu hình và không in giá trị secret.

## 4. Phiên bản và GitHub Release

`app/pubspec.yaml` phải tăng build number ở phần sau dấu `+` cho mỗi bản cần cài
đè, ví dụ:

```yaml
version: 0.1.0+2
```

Workflow tạo tag dạng `qa-v<version>-<commit-sha>` và Release dạng prerelease.
APK và file `.sha256` được đính kèm; asset trung gian của Actions chỉ giữ 7 ngày
để chuyển giữa các job.

GitHub Release không tự cập nhật app. QA mở Release, tải APK mới, xác minh
checksum rồi cài đặt. Repository private yêu cầu tester có quyền đọc repository.

## 5. Bảo mật

- Không commit upload key, password, `.env`, Supabase service-role key hoặc
  cleanup secret.
- Chỉ workflow publish có `contents: write`; job build chỉ có `contents: read`.
- Không log giá trị secret hoặc dữ liệu người dùng.
- APK luôn dùng Supabase Development; dữ liệu production không được đưa vào QA.
- Cùng package ID và upload key phải được giữ ổn định để cài đè hoạt động.

## 6. Kiểm thử và nghiệm thu

CI phải đạt policy/docs, secret scan, Flutter tests, Android build, DB/RLS/RPC
và Edge Function checks trước workflow phát hành. Sau khi Release được tạo, QA
xác nhận:

- APK cài được trên thiết bị Android;
- chữ ký và package ID không thay đổi;
- version code tăng so với bản trước;
- đăng nhập, Supabase Development, journal, upload media và notification hoạt động;
- cập nhật giữ nguyên dữ liệu server và không có secret trong log/artifact.

## 7. Giới hạn và chuyển đổi sau này

Kênh này không có tester management, automatic update hoặc rollback tức thời như
Google Play Internal Testing. Khi có ngân sách, có thể giữ workflow build hiện
tại và thay bước publish GitHub Release bằng Play upload; signing lineage vẫn
được giữ nguyên.

Vì đây là workflow `workflow_run`, file workflow cần được bootstrap lên default
branch `main` trước khi tự động chạy sau mỗi merge vào `develop`. Chỉ bootstrap
workflow, không đưa source MVP vào `main`.

## Liên quan

- [CI/CD](./ci-cd.md)
- [Nghiệm thu Android trên thiết bị thật](./android-device-qa-acceptance.md)
- [GitHub Environments](./github-environments.md)
- [Android Internal Testing cũ](./android-internal-testing.md)
- [Runbook phát hành](./release-runbook.md)
