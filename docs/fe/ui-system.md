# MuseMend UI system

- **Trạng thái:** `in-progress`
- **Cập nhật:** 2026-09-07

## Mục tiêu và phạm vi

Thiết lập một ngôn ngữ thị giác chung cho các màn ngoài Bầu trời: Auth, Nhật ký,
Khám phá và Cá nhân. Hệ thống kế thừa cảm giác pastel, gradient nhẹ, bề mặt kính
mờ, bo góc lớn và chuyển động ngắn của màn Bầu trời; không phụ thuộc vào Figma
đã bị loại khỏi phạm vi sản phẩm.

## Implementation

Token màu nằm ở `lib/app/theme/` (`MuseColors`, `buildMuseTheme`). Primitive dùng
chung nằm tại `lib/core/presentation/muse_ui.dart`:

- `MusePageBackground`: nền gradient theo page/accent, có dark-mode fallback.
- `MusePageHeader`: icon, tiêu đề và mô tả thống nhất.
- `MuseGlassCard`: surface bán trong suốt, blur, border và shadow nhẹ.
- `MuseSectionLabel` và `MusePill`: nhãn nhóm và hành động nhỏ.

Feature chỉ cung cấp nội dung/state/callback; primitive không gọi Supabase. Auth,
Library và Profile đã dùng nền/header/card mới. Mission custom dùng modal sheet
riêng, giữ toàn bộ validation và RPC cũ.

## Motion và accessibility

Button/surface dùng Material ink và animation 140–180ms. Không dùng animation làm
tín hiệu duy nhất; vùng chạm vẫn tối thiểu 48dp. Nền và card giữ contrast với
text token, hỗ trợ dark mode và text scale. Artwork trang trí không được chứa dữ
liệu người dùng.

## Bảo mật và giới hạn

Thay đổi chỉ ở presentation/theme, không mở thêm quyền Supabase, không thêm asset
remote hoặc log nội dung riêng tư. Blur là hiệu ứng hiển thị, không phải biện pháp
bảo mật; RLS/repository vẫn là lớp bảo vệ dữ liệu.

## Kiểm thử và nghiệm thu

- `flutter analyze --fatal-infos` không có issue.
- `flutter test` chạy qua toàn bộ test hiện có.
- Cần kiểm tra thủ công Android/iOS ở màn hình nhỏ, text scale 200%, dark mode,
  reduce motion và contrast trước khi gọi pixel-polished.

## Việc còn lại

Golden test cho primitive, localization và các biến thể empty/error riêng từng
page sẽ bổ sung trong vòng polish tiếp theo.

Liên quan: [UI direction](./ui-design-direction.md), [Application foundation](./application-foundation.md),
[Journal editor](./journal-editor.md).
