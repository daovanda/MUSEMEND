# Màn Bầu trời (Reflect)

- **Trạng thái:** in-progress
- **Cập nhật:** 2026-09-07
- **Nguồn tham chiếu:** page Home, Figma frame `Bầu trời` (`233:893`) và biến thể mood mở (`57:24`)

## Phạm vi

Màn Bầu trời là màn mặc định sau khi đăng nhập. Đây là màn đầu tiên được hoàn
thiện trong phạm vi page `Home`; không lấy object từ page `Style` hoặc `Page 3`.
Bản MVP gồm scene cố định theo Figma, check-in một lần/ngày, journey, nhiệm vụ và
lời nhắc viết nhật ký.

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

- `SkyScene` hiển thị trực tiếp export `sky-background.png` trong vùng tỷ lệ
  `390×560`; painter code-native là fallback. `CloudMascot` dùng
  `mascot-cloud.png` ở tỷ lệ `145×97`, bồng bềnh dọc tối đa `3dp` theo chu kỳ
  `4s` để tạo cảm giác nhẹ nhàng mà không làm xê dịch layout. Animation tự dừng
  khi hệ điều hành bật `disableAnimations`.
- Logo `MuseMend` ở header dùng `ShaderMask` với gradient ngang xanh teal →
  xanh lá nhạt, giữ chữ là text để sắc nét ở mọi mật độ màn hình.
- Mood bubble rộng `332`, tối thiểu cao `179`, radius `48`, white 60%, border
  white 50% và background blur `12`. Năm artwork ánh xạ nhãn `QUẠO`,
  `TRỐNG RỖNG`, `ỔN ÁP`, `THƯ GIÃN`, `CHỮA LÀNH` về đúng enum DB.
- `LƯU NHANH` lưu check-in; `LƯU VÀ VIẾT TÂM TƯ` lưu rồi mở `/journal`.
- Journey hiển thị tỉnh, trạm và tối đa năm checkpoint từ `JourneyDashboard`;
  `province_checkpoints.asset_path` được truyền tới `CatalogArtwork` khi đã có
  export được duyệt, còn `NULL` dùng placeholder. Không dùng sprite cố định thay
  cho dữ liệu hiện tại.
- Mission nằm trên panel gradient xanh nhạt sang tím nhạt; khi tài khoản mở Home
  lần đầu trong ngày, server tạo idempotent hai nhiệm vụ starter (`Uống một cốc
  nước`, `Đi bộ 5 phút`). Các nhiệm vụ được nhóm theo `Buổi sáng`, `Bất kỳ lúc nào`,
  `Buổi chiều`, `Buổi tối` từ `dueAt` ở UTC+7. Tiến độ cạnh sticker là
  `earned_energy/required_energy` của checkpoint hiện tại.
- Quote P0 hardcode đúng nội dung Figma. Khi có nguồn nội dung động, nó phải đi
  qua application interface và không cho nội dung server tự chèn HTML/URL.
- `Chia sẻ khoảnh khắc` dùng carousel card đúng composition Home: preview, tiêu
  đề, mô tả và nút chia sẻ. Nội dung hiện là mẫu cứng; hành vi export/share thực
  tế được để vòng sau và không truy cập journal riêng tư trong lát cắt này.
- Bottom navigation có bốn route và mây ở giữa. Nút mây `56×56`, màu `#366672`,
  nhô lên `19dp`, icon `#EFFBFF`; chạm về Bầu trời, giữ để mở năm mood. Bốn tab
  dùng icon nét mảnh, không có selected pill lớn như bản cũ.

## Layer order và chuyển tiếp

Vùng hero render theo thứ tự: nền `image 20`, fade về màu nền từ khoảng
`top 294`, header, mascot, mood bubble, khoảng thở và journey. Mission tiếp tục
trên nền sáng. Opacity, blur và gradient được dựng trong Flutter, không bake bằng
screenshot toàn frame.

## Trạng thái, lỗi và an toàn dữ liệu

- Loading và lỗi/retry của check-in giữ nguyên; lỗi journey/missions không làm
  mất dữ liệu check-in.
- Mood chưa chọn thì hai nút lưu bị vô hiệu hóa.
- Picker trung tâm có saving state, scale khi chạm và khóa thao tác lặp.
- `ReflectController.updateMood()` giữ nguyên `energyLevel` và `note` của check-in
  đã có; đổi mood ở bottom nav không gửi `null` làm mất dữ liệu cũ.
- UI không tự cộng thưởng, đổi checkpoint hoặc unlock catalog; việc materialize
  nhiệm vụ starter cũng chỉ gọi RPC và không tự ghi bảng.

## Accessibility và responsive

Mood option, menu và navigation có semantic label/selected state. Scene trang trí
bị loại khỏi accessibility tree; mascot có nhãn ngắn. Layout dùng chiều rộng khả
dụng thay vì khóa toàn màn ở 390px. Các nút thao tác chính cần tiếp tục được kiểm
tra ở text scale 200% và màn hình nhỏ.

## Asset và database

Asset chính thức theo [asset manifest](./assets.md). Catalog động đã map các cột
`asset_path`, `cover_asset_path`, `map_asset_path` về domain model; chưa seed path
giả khi chưa có export từng dòng. Sprite nhiều object chỉ là nguồn tham chiếu.
Thay đổi asset bundle này không cần migration DB.

## Kiểm thử và nghiệm thu

- Unit test bảo vệ việc đổi mood không xóa `energyLevel`/`note`.
- Asset test tải đủ nền, mascot và năm mood.
- Chạy `flutter analyze`, `flutter test` và `git diff --check` trước PR.
- So sánh trực quan với đúng frame trên page Home; không commit screenshot thay
  cho UI.

## Việc còn lại

- Nhận export riêng cho từng landmark/food/item trước khi publish `asset_path`.
- Emulator Android đang dùng báo lỗi OpenGL ES. Software rendering đã chụp được
  Home và mood picker nhưng emulator vẫn mất kết nối sau một số lần chạy; lặp
  visual QA trên thiết bị thật trước khi gọi là pixel-perfect.
- Bổ sung golden test cho text scale 200% và màn hình nhỏ.
- Chốt nguồn quote động sau khi có content model.

## Liên quan

- [Home Figma inventory](./home-figma-inventory.md)
- [Asset manifest](./assets.md)
- [Daily check-in](./daily-checkin.md)
- [Missions và energy](./missions-energy.md)
