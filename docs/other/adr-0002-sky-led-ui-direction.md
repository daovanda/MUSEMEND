# ADR-0002: Dùng Bầu trời làm neo thị giác cho các màn MVP

- **Trạng thái:** `accepted`
- **Ngày:** 2026-09-07

## Bối cảnh

Các frame Figma ngoài màn Bầu trời đã bị loại khỏi giao diện sau buổi họp sản
phẩm. Nếu giữ chúng làm nguồn chuẩn, Auth, Nhật ký, Khám phá và Cá nhân sẽ tiếp
tục có các card, màu và modal không nhất quán với màn đã được duyệt.

## Quyết định

Trong vòng MVP này, Bầu trời là visual anchor duy nhất. Các page còn lại dùng
`MusePageBackground`, `MuseGlassCard`, typography/color token và motion nhẹ trong
`app/lib/core/presentation/muse_ui.dart`; không sao chép object từ các page Figma
đã loại bỏ. Hành vi dữ liệu vẫn theo repository/RPC hiện có.

Nhật ký là ngoại lệ về interaction: tạo/sửa mở editor toàn màn hình để ưu tiên
viết tự do; modal sheet chỉ dùng cho form ngắn như thêm nhiệm vụ.

## Hệ quả

- Auth, Journal, Library/Khám phá và Profile có surface/gradient/spacing đồng bộ.
- Figma inventory vẫn được lưu để truy nguyên lịch sử, nhưng không tự động tạo
  thêm UI.
- Rich-text attachment inline chưa được bật vì schema hiện tại chỉ lưu media
  theo journal, chưa có block/position.

## Kiểm thử và rollback

Chạy `flutter analyze --fatal-infos`, `flutter test`, kiểm tra text scale 200%,
dark mode và màn hình nhỏ. Rollback bằng revert commit presentation/ADR; không có
thay đổi DB hay migration.

Liên quan: [UI direction](../fe/ui-design-direction.md), [UI system](../fe/ui-system.md),
[Journal editor](../fe/journal-editor.md).
