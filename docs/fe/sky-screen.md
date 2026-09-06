# Màn Bầu trời (Reflect)

- **Trạng thái:** in-progress
- **Cập nhật:** 2026-09-07
- **Nguồn tham chiếu:** Figma frame `Bầu trời` (`233-893`)

## Phạm vi

Màn Bầu trời là màn mặc định sau khi đăng nhập. Bản MVP ưu tiên scene cố định theo
Figma, check-in một lần/ngày, journey card, nhiệm vụ và lời nhắc viết nhật ký.

## Luồng dữ liệu

```text
ReflectScreen
  ├─ reflectControllerProvider → check-in hôm nay, streak, save/update
  ├─ journeyControllerProvider → năng lượng, tỉnh, checkpoint, tiến độ
  └─ MissionsSection(skyStyle: true) → repository/RPC nhiệm vụ
```

Presentation không gọi Supabase trực tiếp. Quyền thưởng, năng lượng, mở khóa và
tiến độ vẫn do RPC/database xác định; các con số hiển thị chỉ là kết quả đọc.

## Thành phần UI

- `SkyScene` trong `app/lib/features/checkin/presentation/sky_scene.dart` ghép
  gradient/sun với export alpha `sky-background.png`; painter code-native chỉ là
  fallback khi asset không tải được. `CloudMascot` dùng export chính thức
  `mascot-cloud.png`.
- Mood card ánh xạ nhãn hiển thị (`QUẠO`, `TRỐNG RỖNG`, `ỔN ÁP`, `THƯ GIÃN`,
  `CHỮA LÀNH`) về đúng năm enum DB trong `Mood`.
- Nút `LƯU NHANH` chỉ lưu check-in; `VIẾT TÂM TÌNH` lưu rồi mở `/journal`.
- Quote P0 đang hardcode đúng nội dung Figma để tránh thêm nguồn dữ liệu chưa có.
  Khi có bảng đo lường/remote content, thay qua application interface và không
  cho nội dung server tự chèn HTML/URL.
- Navigation dưới có năm vị trí thị giác: bốn route hiện có (Bầu trời, Nhật ký,
  Khám phá, Cá nhân) và mây ở giữa. Chạm mây về Bầu trời; nhấn giữ mở picker
  năm mood chuẩn. Chọn mood gọi application layer để lưu check-in.

## Trạng thái và lỗi

- Loading, lỗi/retry của check-in vẫn giữ nguyên.
- Journey/missions lỗi không làm mất check-in; card có thể hiển thị fallback và
  các provider tự retry theo hành vi hiện tại.
- Mood chưa chọn thì cả hai nút lưu bị vô hiệu hóa.
- Nội dung nhập note giới hạn 500 ký tự, không hiển thị trong notification.
- Picker mood trung tâm có hiệu ứng scale khi chạm, bottom sheet bo góc và vùng
  chạm đủ lớn.

## Accessibility và responsive

Mood option, menu và navigation có semantic label/selected state và vùng chạm từ
48dp. Scene trang trí bị loại khỏi accessibility tree; mascot có nhãn ngắn.
Layout dùng chiều rộng khả dụng, không dựa vào frame 390px và không chặn text
scale lớn.

## Asset và migration

Asset chính thức theo [asset manifest](./assets.md). Catalog động đã map các cột
`asset_path`, `cover_asset_path`, `map_asset_path` về domain model; chưa seed path
giả khi chưa có file export theo từng dòng catalog. Thay đổi asset bundle này
không cần migration DB.

## Kiểm thử/tiêu chí nghiệm thu

- Widget test giữ được màn lỗi/retry, mood selection, nút lưu và picker mood
  trung tâm.
- Chạy `flutter analyze`, `flutter test` và `git diff --check` trước PR.
- So sánh trực quan với frame Figma khi review; không commit screenshot thay cho
  UI.

## Việc còn lại

- Nhận export chính thức riêng cho từng landmark/food/item trước khi publish
  `asset_path` vào catalog; sprite nhiều object hiện chỉ là trang trí.
- Bổ sung widget/golden test cho text scale 200% và màn hình nhỏ.
- Quyết định nguồn quote động sau khi có analytics/content model.
