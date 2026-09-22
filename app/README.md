# MuseMend Flutter app

Flutter Android/iOS client với application/bundle ID `com.musemend.app`; target
Web được bật cho QA giao diện local.

Chạy Web QA local từ thư mục này (build release mới, dừng server runbook cũ và
không tái sử dụng cache/service worker):

```powershell
.\tool\start-local-web-qa.ps1
```

Xem [runbook Flutter Web local](../docs/fe/flutter-web-local.md) để biết cơ chế
quản lý tiến trình, cache và cách dừng server. Target Web không thay thế kiểm
thử native trên Android/iOS.

Xem hướng dẫn chạy tại [README gốc](../README.md) và quy ước frontend tại
[docs/fe/README.md](../docs/fe/README.md). Không commit file `config/*.json` thật
hoặc bất kỳ service-role key/secret nào vào module này.
