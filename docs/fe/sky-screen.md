# Màn Bầu trời (Reflect)

- **Trạng thái:** in-progress
- **Cập nhật:** 2026-09-06
- **Nguồn tham chiếu:** Figma frame `Bầu trời` (`233-893`)

## Phạm vi

Màn Bầu trời là màn mặc định sau khi đăng nhập. Bản MVP hiện ưu tiên một scene
code-native có thể thay bằng artwork export chính thức, check-in một lần/ngày,
journey card, nhiệm vụ và lời nhắc viết nhật ký.

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

- `SkyScene` và `CloudMascot` trong `app/lib/features/checkin/presentation/sky_scene.dart`
  là placeholder painter, không dùng screenshot Figma.
- Mood card ánh xạ nhãn hiển thị (`QUẠO`, `TRỐNG RỖNG`, `ỔN ÁP`, `THƯ GIÃN`,
  `CHỮA LÀNH`) về đúng năm enum DB trong `Mood`.
- Nút `LƯU NHANH` chỉ lưu check-in; `VIẾT TÂM TÌNH` lưu rồi mở `/journal`.
- Quote P0 đang hardcode đúng nội dung Figma để tránh thêm nguồn dữ liệu chưa có.
  Khi có bảng đo lường/remote content, thay qua application interface và không
  cho nội dung server tự chèn HTML/URL.
- Navigation dưới dùng bốn route hiện có, với nhãn sản phẩm Bầu trời, Nhật ký,
  Khám phá và Cá nhân.

## Trạng thái và lỗi

- Loading, lỗi/retry của check-in vẫn giữ nguyên.
- Journey/missions lỗi không làm mất check-in; card có thể hiển thị fallback và
  các provider tự retry theo hành vi hiện tại.
- Mood chưa chọn thì cả hai nút lưu bị vô hiệu hóa.
- Nội dung nhập note giới hạn 500 ký tự, không hiển thị trong notification.

## Accessibility và responsive

Mood option, menu và navigation có semantic label/selected state và vùng chạm từ
48dp. Scene trang trí bị loại khỏi accessibility tree; mascot có nhãn ngắn.
Layout dùng chiều rộng khả dụng, không dựa vào frame 390px và không chặn text
scale lớn.

## Asset và migration

Asset chính thức theo [asset manifest](./assets.md). Catalog động đã map các cột
`asset_path`, `cover_asset_path`, `map_asset_path` về domain model; chưa seed path
giả khi chưa có file export. Thay đổi này không cần migration DB.

## Kiểm thử/tiêu chí nghiệm thu

- Widget test giữ được màn lỗi/retry và kiểm tra mood selection, nút lưu.
- Chạy `flutter analyze`, `flutter test` và `git diff --check` trước PR.
- So sánh trực quan với frame Figma khi review; không commit screenshot thay cho
  UI.

## Việc còn lại

- Nhận export chính thức cho cloud, landscape, mood và navigation icon.
- Bổ sung widget/golden test cho text scale 200% và màn hình nhỏ.
- Quyết định nguồn quote động sau khi có analytics/content model.
