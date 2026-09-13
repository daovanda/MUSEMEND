# Localization Flutter

**Trạng thái:** `implemented`
**Cập nhật:** 2026-09-13

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

Toàn bộ nội dung giao diện cố định trong Auth, Onboarding, Bầu trời/check-in,
Missions, Journal/editor, Khám phá/Library, Profile, navigation, trạng thái lỗi,
accessibility semantics và local notification đều lấy từ `AppLocalizations`.
Tên ngôn ngữ trong menu được cố ý hiển thị bằng tên bản địa để người dùng luôn
nhận ra lựa chọn của mình. `MuseMend`, email và mẫu nhập ngày/giờ là tên/định
dạng kỹ thuật, không phải bản dịch nội dung.

Catalog động của quote, gợi ý Muse, điểm đến, checkpoint, landmark, food và item
không nằm trong ARB: repository lấy bản dịch DB theo locale đã resolve. Nội dung
do người dùng tạo (nhật ký, nhiệm vụ riêng, tên mây) luôn được giữ nguyên.

## Quy tắc dịch

Mọi key mới phải được viết/chốt bằng tiếng Việt trước. Bản dịch cần giữ ý và giọng
văn chữa lành, tự nhiên trong ngôn ngữ đích. Không đưa text UI vào DB; chỉ catalog
động như điểm đến, checkpoint, phần thưởng, nhiệm vụ Muse và quote dùng bảng
translation. PR thiếu key hoặc dùng tiếng Anh giả cho locale khác không đạt DoD.
Test `arb_completeness_test.dart` bắt buộc đúng 12 locale được hỗ trợ, mọi file
ARB có cùng tập key với bản tham chiếu tiếng Việt, không có giá trị rỗng và giữ
nguyên tập placeholder. Nhờ vậy một màn hình không thể âm thầm trộn tiếng Anh do
thiếu key hoặc làm hỏng câu động vì thiếu/thừa placeholder.

## Kiểm thử

Unit test bảo vệ tính đầy đủ của ARB, locale hợp lệ và fallback `ru`/`zh` về
`en`, DTO settings và fallback mission translation. Widget test luôn khai báo
delegate và locale rõ ràng để không vô tình kiểm tra bằng locale của máy CI. QA
cần kiểm tra device locale ngoài danh sách, chọn thủ công, đăng xuất/đăng nhập
lại, đổi locale khi app đang mở và rà text overflow cho tiếng Đức/Pháp.
