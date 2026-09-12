# Onboarding tài khoản mới

**Trạng thái:** `implemented`
**Cập nhật:** 2026-09-12

## Mục tiêu và phạm vi

Tài khoản tạo mới được giới thiệu ngắn về giá trị của MuseMend, định hướng riêng
tư/offline và có thể chọn tên hiển thị cùng cách xưng hô trước khi vào Bầu trời.
Ảnh tham khảo chỉ cung cấp nội dung; UI dùng nền mây, glass card, màu pastel và
motion hiện có của MuseMend, không sao chép bố cục thiết kế cũ.

## Luồng và module

Router tải `onboardingProfileProvider` sau khi có session. Profile chưa có
`onboarding_completed_at` được chuyển tới `/onboarding`; profile đã hoàn tất đi
thẳng tới app. Ba bước gồm:

1. Chào mừng: gọi tên cảm xúc, viết riêng tư và chăm sóc bằng bước nhỏ.
2. Riêng tư: giới thiệu nhật ký trên thiết bị, dùng ngoại tuyến và sao lưu tùy chọn.
3. Cá nhân hóa: tên hiển thị tùy chọn và một trong năm cách xưng hô.

Tên từ đăng ký được điền sẵn. Tên người dùng nhập ở bước cuối được ưu tiên; bỏ
qua giữ tên hiện có. Nếu không có tên, các màn hình tiếp tục dùng fallback
`Bạn của Muse`. Cách xưng hô được lưu cho cá nhân hóa nội dung về sau; chuỗi trong
toàn app chưa được thay đổi trong lát cắt này.

Ở bước cá nhân hóa, nhãn tên hiển thị nằm thành một dòng riêng phía trên ô nhập,
không dùng floating label. Cách này tránh nhãn chồng lên viền ô khi màn hình hẹp
hoặc khi người dùng tăng cỡ chữ hệ thống.

## Contract, validation và lỗi

`OnboardingRepository` tách presentation khỏi Supabase. Adapter đọc ba cột profile
và gọi `complete_onboarding(display_name, preferred_address)`. Tên rỗng được coi
là không thay đổi; tên nhập mới dài 2–80 ký tự. Cách xưng hô chỉ nhận tập giá trị
đã định nghĩa trong domain và DB. Khi tải/lưu lỗi, màn hình giữ người dùng ở flow,
không giả định đã hoàn tất và cung cấp retry.

## Bảo mật và riêng tư

Client không được update trực tiếp trạng thái onboarding. RPC owner-scoped dùng
`muse_private.require_user()`, `SECURITY DEFINER`, `search_path=''` và chỉ cấp
execute cho `authenticated`. Theo quyết định sản phẩm, onboarding giới thiệu
offline/backup ở thì hiện tại để phản ánh trải nghiệm phát hành mục tiêu. Tại mốc
implementation này dữ liệu vẫn dùng Auth, RLS và Storage private, chưa có local-first
hay E2EE; hai năng lực đó phải được hoàn thiện trước khi phát hành công khai.

## Kiểm thử, rollout và giới hạn

Migration backfill tài khoản hiện có thành đã hoàn tất để không thay đổi trải
nghiệm đăng nhập của họ; tài khoản tạo sau migration có giá trị null và thấy flow.
Integration test kiểm tra trạng thái ban đầu và RPC hoàn tất. Widget/DTO test kiểm
tra mapping, nội dung ba bước và hành vi bỏ qua/lưu tên.

Rollback ứng dụng vẫn tương thích với hai cột mới. Sau khi migration đã deploy,
không xóa cột/RPC trong rollback nóng; dùng forward migration nếu cần sửa. Offline,
backup tùy chọn, áp dụng cách xưng hô toàn app và liên kết chính sách riêng tư công
khai vẫn là việc tiếp theo trước production.

Có thể QA giao diện trước khi deploy migration mà không dùng tài khoản hay ghi dữ
liệu bằng entrypoint preview:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 64563 `
  -t tool/onboarding_preview.dart
```

Liên quan: [Authentication](./authentication.md),
[Profile](./profile-overview.md),
[Profiles/settings DB](../db/profiles-settings.md).
