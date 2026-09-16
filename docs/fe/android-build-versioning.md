# Android build versioning

- **Trạng thái:** `implemented`
- **Phạm vi:** version hiển thị và build number của APK Flutter Android.

## Quy tắc

`app/pubspec.yaml` dùng định dạng `version: x.y.z+N`. Phần `x.y.z` trở thành
`versionName`, còn `N` trở thành Android `versionCode`. Với cùng application id
`com.musemend.app`, `N` phải luôn tăng so với mọi APK đã phát hành; không được
đặt lại về `1` khi chỉ đổi versionName.

Ví dụ, sau `1.8.0+5`, bản có thể cài đè phải dùng ít nhất `1.8.1+6`. Nếu build
number giảm, Android có thể từ chối cài đặt như một gói không hợp lệ hoặc bản
hạ cấp.

## Kiểm thử phát hành

- Kiểm tra `aapt2 dump badging` cho `versionName`, `versionCode` và
  `com.musemend.app`.
- Cài APK mới đè lên bản QA trước đó mà không gỡ ứng dụng hoặc xóa dữ liệu cục
  bộ.
- Xác minh checksum của APK trong GitHub Release trước khi cài.

Build number không chứa dữ liệu người dùng, secret hoặc thông tin xác thực.
