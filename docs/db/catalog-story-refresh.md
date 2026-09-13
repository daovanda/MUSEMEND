# Catalog story refresh

**Trạng thái:** `implemented`  
**Cập nhật:** 2026-09-13

## Mục tiêu

Migration `20260913120000_catalog_story_refresh.sql` thay thế các mô tả
placeholder của content pack bằng nội dung có ngữ cảnh: điểm đến được giới
thiệu như một nơi để bắt đầu hành trình, ba checkpoint nối tiếp thành một câu
chuyện, còn landmark, food và destination item có mô tả/story riêng. Tiếng Việt
là bản biên tập gốc; các locale còn lại giữ cùng ý nghĩa và giọng văn dịu dàng.

## Phạm vi và dữ liệu

- Chỉ cập nhật các hàng catalog của content pack (`code LIKE 'content-%'`), không
  chạm dữ liệu người dùng hoặc catalog cũ.
- `destination_translations.description` là lời giới thiệu ngắn về điểm đến.
- `checkpoint_translations.description` dùng ba bước mở đầu → nhận ra kết nối →
  mang theo điều muốn giữ lại, nhờ đó các chặng đọc liền mạch.
- `landmark_translations` và `food_translations` cập nhật cả `description` và
  `story_content`; `destination_item_translations.description` kể vai trò của
  vật phẩm trong hành trình.
- Bản `vi` của điểm đến được đồng bộ về cột fallback `destinations.description`.

## Bảo mật và tương thích

Migration chỉ `UPDATE` catalog server-owned, không mở thêm quyền và không thay
đổi RLS. Các bảng translation vẫn chỉ cho role `authenticated` đọc. Migration
độc lập, replay an toàn và không sửa migration content pack đã chạy.

## Kiểm thử và rollback

1. Replay migration trên database sạch; kiểm tra 12 locale cho từng loại entity.
2. Đăng nhập bằng tài khoản test, đổi locale và xác nhận mô tả điểm đến, chặng,
   landmark, food, item không còn câu placeholder lặp lại.
3. Nếu cần rollback, tạo migration mới khôi phục snapshot nội dung đã duyệt;
   không chỉnh sửa migration đã chạy trên môi trường dùng chung.

Liên quan: [Content pack catalog v1](./catalog-content-pack.md),
[Đa ngôn ngữ cho catalog](./catalog-localization.md).
