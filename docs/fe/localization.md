# Localization Flutter

**Trạng thái:** `in-progress`  
**Cập nhật:** 2026-09-12

## Hành vi

Flutter dùng ARB/gen-l10n với `app_vi.arb` là tham chiếu nội dung tiếng Việt và
`app_en.arb` là template kỹ thuật bắt buộc của generator. App hỗ trợ 12 locale:
`vi`, `en`, `ja`, `fr`, `es`, `it`, `de`, `ko`, `pt`, `ms`, `id`, `th`.

Mặc định app đọc locale hệ điều hành, không dùng GPS và không xin quyền vị trí.
Nếu locale thiết bị không được hỗ trợ, `resolveDeviceLocale()` trả tiếng Anh.
User có thể chọn ngôn ngữ tại Cá nhân → Hồ sơ và cài đặt; lựa chọn được lưu vào
`user_settings.language_code`. Giá trị `NULL` là “Tự động (thiết bị)”.

## Kiến trúc

- `core/localization/supported_locales.dart` là allowlist và fallback thuần;
- `AppLanguageCodeController` tải/sanitize lựa chọn theo session;
- `MaterialApp` nhận locale, delegates và supported locales từ gen-l10n;
- quote, mission và journey provider chuyển locale đã resolve xuống repository;
- màn Khám phá overlay `destination/checkpoint/landmark/food/item` translations;
- catalog DB áp dụng requested → English → Vietnamese base.

Bottom navigation và form cài đặt đã dùng chuỗi sinh từ ARB. Catalog động của
quote, gợi ý Muse và Khám phá đã dùng bảng translation. Các chuỗi feature
còn hard-code tiếng Việt sẽ được chuyển dần theo module; vì vậy trạng thái tài
liệu vẫn là `in-progress`, không tuyên bố toàn bộ UI đã được dịch.

## Quy tắc dịch

Mọi key mới phải được viết/chốt bằng tiếng Việt trước. Bản dịch cần giữ ý và giọng
văn chữa lành, tự nhiên trong ngôn ngữ đích. Không đưa text UI vào DB; chỉ catalog
động như điểm đến, checkpoint, phần thưởng, nhiệm vụ Muse và quote dùng bảng
translation. PR thiếu key hoặc dùng tiếng Anh giả cho locale khác không đạt DoD.

## Kiểm thử

Unit test bảo vệ locale hợp lệ và fallback `ru`/`zh` về `en`, DTO settings và
fallback mission translation. QA cần kiểm tra device locale ngoài danh sách,
chọn thủ công, đăng xuất/đăng nhập lại và thay đổi locale khi app đang mở.
