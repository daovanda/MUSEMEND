# Frontend asset manifest

- **Trạng thái:** in-progress
- **Cập nhật:** 2026-09-07
- **Nguồn thiết kế:** [Figma — page Home](https://www.figma.com/design/AhhlLUWAyvLVs7R5ZBVcQV/Nh%E1%BA%ADt-K%C3%BD-Ch%E1%BB%AFa-L%C3%A0nh?node-id=130-25)

## Mục tiêu

Giữ asset dùng chung của Flutter tách khỏi code feature, có nguồn và có thể thay
thế mà không sửa nghiệp vụ. Frame screenshot chỉ là tài liệu tham chiếu; không
được dùng làm nền ứng dụng.

## Manifest hiện tại

| Nhóm | Nguồn/node | Implementation hiện tại | Trạng thái |
| --- | --- | --- | --- |
| Sky gradient | Home/Bầu trời (`233:893`) | Flutter gradient `#E0F2F7 → #FBF9F5` | implemented |
| Sky background, hills, river | `image 20` (`58:184`), source `1024×1536` | `app/assets/illustrations/journey/sky-background.png` | integrated |
| Cloud mascot | `image 22` (`118:41`), source `1536×1024` | `app/assets/illustrations/clouds/mascot-cloud.png` | integrated |
| Mood QUẠO | `85:587`, source `1024×1024` | `app/assets/illustrations/clouds/moods/awful.png` | integrated |
| Mood TRỐNG RỖNG | `85:570`, source `1024×1024` | `app/assets/illustrations/clouds/moods/sad.png` | integrated |
| Mood ỔN ÁP | `85:576`, source `1024×1024` | `app/assets/illustrations/clouds/moods/okay.png` | integrated |
| Mood THƯ GIÃN | `85:573`, source `1024×1024` | `app/assets/illustrations/clouds/moods/good.png` | integrated |
| Mood CHỮA LÀNH | `85:595`, source `1024×1024` | `app/assets/illustrations/clouds/moods/great.png` | integrated |
| Journey decoration sprite | Home mission/weather source, `2400×1309` | `app/assets/illustrations/journey/sky-collection-sprite.png` | reference only; excluded from app bundle |
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
được trộn vào asset bundle. Nền, mascot và năm mood đã được export trực tiếp từ
page Home. Sprite trang trí không được gán vào một dòng catalog vì nó chứa nhiều
object đã crop; catalog vẫn chờ export riêng cho từng landmark/food/item.

## Liên quan

- [UI/UX direction](./ui-design-direction.md)
- [Home Figma inventory](./home-figma-inventory.md)
- [Journey và Library](./journey-library.md)
- [App assets README](../../app/assets/README.md)
