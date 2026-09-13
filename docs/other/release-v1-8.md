# Android QA release 1.8

- **Trạng thái:** `in-progress`
- **Cập nhật:** 2026-09-13

## Mục tiêu

Phát hành bản Android QA `1.8.0+4` từ `develop`. Bản này giới hạn gợi ý Muse
trên màn Home còn năm mục ngẫu nhiên và bổ sung nội dung kể chuyện cho catalog
điểm đến, checkpoint, landmark, food và destination item bằng 12 ngôn ngữ.

## Luồng phát hành

1. Commit trên nhánh feature và tạo PR vào `develop`.
2. Chỉ squash merge sau khi CI, review và migration validation đạt.
3. CI trên `develop` triển khai migration `20260913120000_catalog_story_refresh.sql`
   vào Supabase Development rồi tạo GitHub prerelease Android.
4. Workflow đọc `1.8.0+4` và tạo tag dạng `qa-v1.8.0-4-<commit-sha>`.

## Kiểm thử

- Flutter format, analyzer và toàn bộ unit/widget tests phải đạt.
- Dashboard chỉ hiển thị tối đa năm gợi ý Muse; reload có thể chọn nhóm khác.
- Kiểm tra đủ `vi`, `en`, `ja`, `fr`, `es`, `it`, `de`, `ko`, `pt`, `ms`, `id`, `th`.
- Kiểm tra nội dung điểm đến là lời giới thiệu; ba checkpoint nối tiếp; landmark,
  food và item có câu chuyện riêng.
- Kiểm tra fallback locale không hỗ trợ về tiếng Anh và không ảnh hưởng dữ liệu
  người dùng.

## Bảo mật và rollback

Thay đổi catalog chỉ là migration server-owned, không mở thêm quyền và không
chạm dữ liệu user-owned. Nếu QA phát hiện nội dung không phù hợp, tạo migration
mới để chỉnh sửa; không sửa migration đã chạy và không ghi đè tag/release đã phát hành.

Liên kết: [Catalog story refresh](../db/catalog-story-refresh.md),
[Android QA Release](./android-qa-release.md).
