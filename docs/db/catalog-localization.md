# Đa ngôn ngữ cho catalog

**Trạng thái:** `implemented`

**Cập nhật:** 2026-09-13

## Quy tắc nội dung và fallback

Tiếng Việt (`vi`) là bản tham chiếu biên tập: nội dung mới được viết, duyệt giọng
văn và chốt ý nghĩa bằng tiếng Việt trước khi dịch. Mười một bản dịch phải giữ
giọng văn dịu dàng, tự nhiên của MuseMend, không dịch từng chữ máy móc.

App hỗ trợ `vi`, `en`, `ja`, `fr`, `es`, `it`, `de`, `ko`, `pt`, `ms`, `id` và
`th`. Khi user chọn ngôn ngữ đã hỗ trợ, dữ liệu được tìm theo thứ tự:

1. ngôn ngữ được yêu cầu;
2. tiếng Anh (`en`) làm fallback kỹ thuật;
3. cột nội dung gốc tiếng Việt trên bảng catalog để tương thích dữ liệu cũ.

Ngôn ngữ thiết bị ngoài danh sách luôn được chuẩn hóa thành `en`. Tiếng Anh là
fallback runtime, không thay vai trò tiếng Việt là bản gốc biên tập.

## Schema

`supported_languages` là catalog mã ngôn ngữ. Bảy bảng translation dùng khóa
ghép `(entity_id, language_code)`:

- `destination_translations`;
- `checkpoint_translations`;
- `landmark_translations`;
- `food_translations`;
- `destination_item_translations`;
- `mission_template_translations`;
- `daily_quote_translations`.

Foreign key entity dùng `ON DELETE CASCADE`; mã ngôn ngữ dùng `ON DELETE
RESTRICT`. Index bắt đầu bằng `language_code` phục vụ lookup locale-first.
Translation là catalog server-owned: user active chỉ được `SELECT`, không được
ghi trực tiếp.

`user_settings.language_code` nullable: `NULL` nghĩa là tự động theo locale thiết
bị. Lựa chọn thủ công phải tham chiếu `supported_languages`.

## Nhiệm vụ gợi ý và quote

Flutter đọc `mission_template_translations` cùng `mission_templates`. Cả gợi ý
từ Muse lẫn nhiệm vụ đã materialize từ template được overlay bằng bản dịch khi
hiển thị; nhiệm vụ user tự viết không bị dịch. RPC `get_daily_quote(text)` nhận
locale đã resolve từ app và áp dụng fallback tại server. Overload không tham số
được giữ để tương thích client cũ.

Content pack đầu tiên được nạp bởi
[`catalog-content-pack.md`](./catalog-content-pack.md), gồm 30 mission template
và 100 quote với đủ 12 locale.

## Reset development và triển khai

Migration `20260912210000_multilingual_catalog_reset.sql` là reset trước phát
hành, có chủ đích xóa toàn bộ app rows và `auth.users` ở Supabase Development để
nhập content pack mới. Trước khi xóa metadata nhật ký, đường dẫn media được đưa
vào `storage_cleanup_jobs`; worker xóa vật lý qua Storage API. Không xóa trực tiếp
`storage.objects` bằng SQL.

Migration giữ schema, lịch sử migration, bucket riêng tư, danh sách ngôn ngữ và
hàng đợi cleanup. Không được chạy migration reset này trên production có dữ liệu
thật nếu chưa backup và diễn tập restore.

## Kiểm thử còn lại

Validation cục bộ kiểm tra đủ bảy bảng, 12 locale, fallback locale chưa hỗ trợ về
`en`, reset user/catalog và các fixture transaction mới. Sau CI cần smoke test
Supabase Development: đổi ngôn ngữ, quote, gợi ý Muse, RLS hai tài khoản và trạng
thái cleanup Storage.

