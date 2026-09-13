# Content pack catalog v1

**Trạng thái:** `implemented`  
**Cập nhật:** 2026-09-13

Migration `20260913100000_content_pack_v1.sql` nạp catalog server-owned sau
development reset. Migration được sinh bởi
[`supabase/seed/generate_content_pack.py`](../../supabase/seed/generate_content_pack.py)
để có thể kiểm tra và tái tạo nhất quán; không sửa trực tiếp migration đã chạy.

## Phạm vi dữ liệu

- 30 điểm đến ở Việt Nam và nhiều quốc gia khác, với `country_code` và
  `destination_type` toàn cầu.
- 90 checkpoint (3 checkpoint hoạt động cho mỗi điểm đến), có `required_energy`
  và asset path riêng.
- Mỗi điểm đến có 1 landmark, 1 food và 2 destination item; checkpoint có reward
  landmark/food/item và một bonus energy nhỏ.
- 30 mission template, gồm `demo-water` và `demo-walk` bắt buộc cho
  `ensure_home_missions()`, cùng các mẫu daily/weekly/monthly/yearly/custom.
- 100 daily quote thuộc các chủ đề `love_life`, `enjoy_moment`, `life`, `smile`
  và `happiness`.
- Mỗi entity catalog có đủ 12 bản dịch (`vi`, `en`, `ja`, `fr`, `es`, `it`,
  `de`, `ko`, `pt`, `ms`, `id`, `th`). Tiếng Việt là bản tham chiếu; client và
  RPC dùng tiếng Anh làm fallback khi thiếu locale.

## Asset

240 SVG minh họa deterministic nằm trong
`app/assets/illustrations/journey/content-pack/v1/`: cover/checkpoint,
landmark, food và item. Đây là artwork vector nội bộ để QA offline khi chưa có
image-generation connector; asset path trong DB luôn trỏ tới đường dẫn `assets/`
được bundle bởi Flutter. Có thể thay SVG bằng artwork đã duyệt mà không đổi code
hay khóa catalog.

Asset không chứa dữ liệu người dùng, URL do người dùng cung cấp hoặc secret.
Media nhật ký riêng tư vẫn thuộc bucket Storage và không nằm trong content pack.

## Vận hành và kiểm thử

1. Tạo migration/asset bằng script nếu nội dung cần cập nhật, sau đó review diff
   SQL và danh sách locale.
2. Chạy `node tools/db-validation/validate.mjs`; test kiểm tra số lượng catalog,
   tối thiểu 3 checkpoint/điểm đến, đủ bản dịch và asset path.
3. Merge vào `develop` để CI replay migration và deploy Supabase Development.
4. Không chạy lại migration reset trên môi trường có dữ liệu thật; content pack
   dùng upsert theo mã ổn định để staging replay an toàn.
