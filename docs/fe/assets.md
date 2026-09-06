# Frontend asset manifest

- **Trạng thái:** in-progress
- **Cập nhật:** 2026-09-07
- **Nguồn thiết kế:** [Figma — Nhật Ký Chữa Lành](https://www.figma.com/design/AhhlLUWAyvLVs7R5ZBVcQV/Nh%E1%BA%ADt-K%C3%BD-Ch%E1%BB%AFa-L%C3%A0nh)

## Mục tiêu

Giữ asset dùng chung của Flutter tách khỏi code feature, có nguồn và có thể thay
thế mà không sửa nghiệp vụ. Frame screenshot chỉ là tài liệu tham chiếu; không
được dùng làm nền ứng dụng.

## Manifest hiện tại

| Nhóm | Nguồn/node | Implementation hiện tại | Trạng thái |
| --- | --- | --- | --- |
| Sky gradient/ánh sáng | Figma `Bầu trời` (`233-893`) | Flutter gradient + fallback painter | implemented |
| Sky background, hills, river | Figma `image 20` | `app/assets/illustrations/journey/sky-background.png` | implemented export |
| Cloud mascot | Figma `image 22` (`233-1049`) | `app/assets/illustrations/clouds/mascot-cloud.png` | implemented export |
| Journey decoration sprite | Figma `image 13`, `image 14`, `image 15` | `app/assets/illustrations/journey/sky-collection-sprite.png` | exported; integration pending |
| Province/landmark/food/item | Catalog Supabase (`asset_path`) | repository map vào domain model | implemented mapping; catalog paths pending approved per-item exports |
| Quote card | Figma `Quote` | Flutter card, quote hardcoded P0 | implemented |

## Quy trình thêm asset chính thức

1. Export từng object từ Figma (SVG/WebP/PNG), không export cả frame.
2. Đặt file trong `app/assets/` theo nhóm và thêm vào `pubspec.yaml`.
3. Ghi node, kích thước, license/nguồn và fallback vào bảng manifest này.
4. Với catalog động, upload vào bucket/catalog flow được phê duyệt rồi ghi
   `asset_path` vào seed/migration; client không tự ghi đường dẫn.
5. Thêm widget test cho trạng thái có asset và trạng thái `null` (placeholder).

## Bảo mật và giới hạn

Catalog path là dữ liệu server-owned; không nhận URL tuỳ ý từ người dùng và không
đưa signed URL vào log. Asset journal riêng tư thuộc Storage bucket khác, không
được trộn vào asset bundle. Hai object đã được export từ Figma và ghi nguồn ở
manifest trên. Sprite trang trí không được gán vào một dòng catalog vì nó chứa
nhiều object đã crop; catalog vẫn chờ export riêng cho từng landmark/food/item.

## Liên quan

- [UI/UX direction](./ui-design-direction.md)
- [Journey và Library](./journey-library.md)
- [App assets README](../../app/assets/README.md)
