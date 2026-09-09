# MuseMend Flutter app

Flutter Android/iOS client với application/bundle ID `com.musemend.app`; target
Web được bật cho QA giao diện local.

Chạy Web local từ thư mục này:

```powershell
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Target Web không thay thế kiểm thử native trên Android/iOS.

Xem hướng dẫn chạy tại [README gốc](../README.md) và quy ước frontend tại
[docs/fe/README.md](../docs/fe/README.md). Không commit file `config/*.json` thật
hoặc bất kỳ service-role key/secret nào vào module này.
