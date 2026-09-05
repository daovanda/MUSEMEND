# Roadmap MVP đầu tiên

**Trạng thái:** `in-progress`  
**Cập nhật:** 2026-09-05

## Mục tiêu

Đưa MuseMend từ backend Supabase hiện có thành ứng dụng Flutter Android/iOS có thể
QA theo từng vertical slice. Một slice chỉ hoàn thành khi UI, repository, RPC/RLS,
test và tài liệu cùng hoạt động.

## Thứ tự triển khai

### P0.0 — Foundation

- Flutter tại `app/`, SDK được pin, cấu hình Dev/Production bằng `--dart-define`.
- Feature-first với `data/domain/presentation`, Riverpod và go_router.
- Theme/token theo Figma; shell bốn vùng Reflect/Journal/Library/Profile.
- CI format, analyze, test, APK, DB/RLS, Edge Function và secret scan.

**Nghiệm thu:** clean checkout chạy được; presentation không import Supabase SDK;
CI tạo APK debug; không có secret trong source/artifact.

### P0.1 — Auth và account bootstrap

- Email/password sign-up, sign-in, session restore và sign-out.
- Đọc profile/settings sau trigger bootstrap.
- Loading, retry, expired session và account-disabled state.

**Nghiệm thu:** user mới có đúng profile/settings/travel progress; session phục hồi;
hai tài khoản không đọc/sửa dữ liệu của nhau.

### P0.2 — Reflect: app-open, streak và check-in

- Gọi `record_app_open()` khi phiên authenticated sẵn sàng.
- Check-in một lần/ngày, cho sửa, dùng năm mood chuẩn trong DB.
- Cloud artwork phản ánh mood nhưng không đưa ra chẩn đoán.

**Nghiệm thu:** mở lặp không tạo visit trùng; streak đúng ngày Việt Nam; check-in
lần hai cập nhật cùng record; UI có loading/empty/error/retry.

### P0.3 — Missions, energy và checkpoint

- Chọn template theo mood, tạo mission và mission tự tạo.
- Complete/skip/update chỉ qua RPC.
- Hiển thị năng lượng tích lũy và checkpoint/reward vừa mở.

**Nghiệm thu:** custom mission thưởng đúng 5; complete retry không cộng đôi; client
không ghi trực tiếp energy/progress/unlock.

### P0.4 — Journey và Library

- Khởi hành, tiến độ tỉnh/checkpoint, passport và collection.
- Equip item qua RPC; ba tỉnh demo là catalog của internal MVP.

**Nghiệm thu:** reward mở đúng một lần; checkpoint thuộc tỉnh hiện tại; user không
tự mở khóa; tiến độ dùng `current_energy - journey_energy_used`.

### P0.5 — Daily journal và ảnh riêng tư

- List/detail/create/update/soft-delete journal.
- Tag và upload ảnh vào bucket private theo đường dẫn owner/journal.
- Retry upload/attach mà không làm mất draft.

**Nghiệm thu:** journal + subtype cùng commit/rollback; user B không đọc metadata
hoặc object của A; soft-delete ẩn ngay và cleanup vật lý theo retention.

### P0.6 — Future letter và local notification

- Tạo/sửa/đọc/mở sớm thư; schedule/reschedule local notification.
- Đồng bộ notification inbox DB và deep-link.

**Nghiệm thu:** không nhân đôi lịch/row; tắt quyền OS vẫn có inbox; user không xem
notification của người khác.

### P0.7 — Profile, settings và xóa tài khoản

- Tên hiển thị/tên mây, theme, âm thanh, notification setting.
- Privacy/terms, sign-out và request account deletion.

**Nghiệm thu:** app chỉ sửa cột được cấp; request deletion vô hiệu hóa nghiệp vụ;
cleanup xử lý Auth + DB + Storage idempotently.

### P0.8 — QA và release readiness

- Disclaimer: hỗ trợ phản tư, không chẩn đoán/thay chuyên gia.
- Test Android/iOS, mạng chậm/mất mạng, permission denied, expired session.
- Dev/Production tách project và production có approval.

## P1 sau MVP lõi

- Yearly journal/goals/highlights/lessons và mood history.
- Catalog/bản đồ Việt Nam đầy đủ, avatar và tùy biến mây nâng cao.
- FCM push đa thiết bị, reorder mission, trash/restore và tag management đầy đủ.
- Local-first/background sync/E2EE chỉ bắt đầu sau ADR và threat model riêng.

## Ngoài phạm vi MVP hiện tại

AI đọc/đánh giá journal, premium/shop/affiliate, community/referral, GPS/weather
background, IoT/wearable, audio library và bản đồ quốc tế.

## Quyết định đang chờ

- Export chính thức artwork/logo/icon từ Figma.
- Project Supabase Production trước public release.
- Mapping các nhãn mood phong phú trong Figma sang năm enum chuẩn.

Android application ID và iOS bundle ID đã chốt là `com.musemend.app`.

## Liên kết

- [Kiến trúc và quy ước](../README.md)
- [CI/CD](./ci-cd.md)
- [UI/UX direction](../fe/ui-design-direction.md)
- [Database contracts](../db/README.md)
