# Android Internal Testing

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-06

## 1. Mục tiêu và phạm vi

Phân phối bản Android QA qua Google Play Internal Testing để tester nhận bản
mới từ Play Store thay vì tải APK debug thủ công. Phạm vi hiện tại chỉ là
Android; iOS sẽ dùng TestFlight ở thay đổi riêng.

Package ID cố định là `com.musemend.app`. Track `internal` chỉ dành cho tester
nội bộ và không phải kênh production.

## 2. Luồng phát hành

```text
merge develop
    ↓
CI xanh
    ↓
workflow_run checkout đúng SHA đã CI xác minh
    ↓
build AAB release với Supabase Development
    ↓
upload track internal trên Google Play
    ↓
tester cập nhật qua Play Store
```

Workflow là `.github/workflows/distribute-android-internal.yml`. Nó chỉ chạy
sau CI thành công trên `develop` hoặc khi owner gọi thủ công từ `develop`.

## 3. Ký ứng dụng và cấu hình

Không dùng debug key cho bản Play. Tạo upload keystore riêng, giữ bí mật ở
GitHub Environment `android-development`, và không commit file `.jks` hoặc
password.

Tạo Environment chính xác là `android-development` với các secrets:

| Secret | Nội dung |
| --- | --- |
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | File upload keystore đã encode Base64 |
| `ANDROID_UPLOAD_STORE_PASSWORD` | Mật khẩu keystore |
| `ANDROID_UPLOAD_KEY_ALIAS` | Alias của upload key |
| `ANDROID_UPLOAD_KEY_PASSWORD` | Mật khẩu key |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON service account được cấp quyền Play Console |

Repository variables `SUPABASE_URL` và `SUPABASE_PUBLISHABLE_KEY` được dùng để
build client Development. Publishable key có thể nằm trong artifact mobile;
service account và upload key không được nhúng vào app.

Gradle chỉ tạo file keystore tạm trong thư mục build khi đủ bốn biến ký. Nếu
thiếu cấu hình, workflow dừng trước build và không in giá trị bí mật.

## 4. Cấu hình Google Play Console

Owner cần:

1. Tạo app với package `com.musemend.app`.
2. Bật Google Play Developer API và tạo service account dành riêng cho CI.
3. Mời service account vào Play Console với quyền tối thiểu để quản lý Internal Testing.
4. Tạo track `Internal testing` và thêm email tester.
5. Lấy upload certificate/key theo Play App Signing guidance; chỉ lưu upload key ở GitHub secret.

Lần upload đầu tiên thường cần hoàn tất thiết lập app trong Play Console trước
khi API nhận AAB. Version code phải tăng ở mỗi AAB; không upload lại cùng một
version code.

## 5. Bảo mật và tương thích

- Chỉ dùng service account cho Play upload; không dùng Supabase service-role key.
- Không log JSON service account, keystore, password hoặc nội dung người dùng.
- Giữ `com.musemend.app` và upload signing lineage ổn định để update đè được.
- Database migration phải tương thích ngược với app cũ; deploy migration trước
  khi tester cập nhật app.
- Bản Internal Testing không được coi là production release.

## 6. Kiểm thử và nghiệm thu

CI phải đạt policy/docs, secret scan, Flutter tests, Android build, DB/RLS/RPC
và Edge Function checks trước workflow phân phối. Sau upload, tester xác nhận:

- app cài từ Play Store;
- bản mới hiển thị trong Internal Testing;
- cập nhật giữ nguyên package và dữ liệu local;
- đăng nhập, Supabase Development, upload ảnh và notification vẫn hoạt động;
- version code tăng và không có cảnh báo chữ ký.

## 7. Rollback và việc còn lại

Nếu AAB lỗi, dừng track hoặc phát hành lại build tốt với version code mới; không
ghi đè version code cũ. Thu hồi service account/upload key nếu có dấu hiệu lộ.

Việc còn lại: owner cấu hình Play Console, tạo GitHub Environment và secrets.
Vì đây là workflow `workflow_run`, cần bootstrap file workflow lên default branch
`main` (chỉ file workflow, không đưa source MVP vào `main`) trước khi tự động
phân phối theo mỗi merge vào `develop`. Trước thời điểm đó, có thể dùng
`workflow_dispatch` từ `develop` nếu GitHub hiển thị workflow, rồi xác minh quyền
upload lần đầu.

## Liên quan

- [CI/CD](./ci-cd.md)
- [GitHub Environments](./github-environments.md)
- [Runbook phát hành](./release-runbook.md)
