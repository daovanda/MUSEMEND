# MuseMend assets

Trạng thái: `in-progress`
Cập nhật: 2026-09-06

Thư mục này chứa các asset chính thức đã export từ Figma và được đóng gói cùng
ứng dụng. Không đặt screenshot của frame Figma vào đây. Khi artwork chưa có bản
export được xác nhận, UI dùng placeholder code-native để vẫn có thể phát triển và
kiểm thử.

## Quy ước

- Tên file dùng `kebab-case`, mô tả nội dung và không chứa thông tin người dùng.
- Ưu tiên SVG cho icon/illustration phẳng, WebP/PNG cho ảnh raster.
- Mỗi asset phải có nguồn Figma/node và quyền sử dụng ghi trong
  [`docs/fe/assets.md`](../../docs/fe/assets.md).
- Asset động của catalog (landmark, food, item, province) không commit vào app;
  chúng được map từ `asset_path` do repository đọc từ Supabase và phải được
  kiểm soát bởi policy catalog.

## Cấu trúc dự kiến

```text
assets/
  backgrounds/
  icons/
  illustrations/clouds/
  illustrations/journey/
```

Asset đã export:

- `illustrations/clouds/mascot-cloud.png`: Figma `image 22`, dùng ở màn Bầu trời.
- `illustrations/journey/sky-collection-sprite.png`: Figma `image 13/14/15`,
  sprite trang trí; chưa dùng làm asset catalog vì không thể suy ra từng item.

Khi thêm thư mục/file, cập nhật `pubspec.yaml`, manifest trong tài liệu frontend
và kiểm thử màn hình dùng asset đó.
