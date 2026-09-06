# ADR-0001 — Kiến trúc Flutter client cho MVP

**Trạng thái:** `accepted`  
**Ngày:** 2026-09-05

## Bối cảnh

MVP đọc/ghi trực tiếp Supabase, nhưng roadmap dài hạn yêu cầu ưu tiên dữ liệu trên
thiết bị và đồng bộ. Nếu widget phụ thuộc trực tiếp Supabase SDK, việc chuyển đổi
sẽ tốn kém và khó kiểm thử.

## Quyết định

- Đặt Flutter module tại `app/`.
- Tổ chức feature-first; mỗi feature có `data/domain/presentation`.
- Domain định nghĩa entity và repository interface, không import Flutter/Supabase.
- Data layer triển khai Supabase adapter và ánh xạ DTO → domain.
- Application/use-case/controller điều phối nghiệp vụ; presentation chỉ render state.
- Riverpod quản lý dependency/state; go_router quản lý route và auth redirect.
- MVP là cloud-first. Local persistence/sync chưa triển khai nhưng có thể thêm
  adapter sau repository mà không đổi UI contract.
- Cấu hình môi trường qua compile-time `--dart-define`; mobile chỉ nhận project URL
  và publishable/anon key.
- Navigation bốn vùng theo Figma: Reflect, Journal, Library và Profile.

## Hệ quả

- Có thêm mapping/interface so với gọi SDK trực tiếp, đổi lại test dễ hơn và giảm
  coupling với Supabase.
- Offline MVP chỉ cung cấp error/retry và giữ draft cục bộ ở phạm vi feature; chưa
  tuyên bố local-first.
- Cross-feature communication đi qua domain/application contract, không import
  implementation của nhau.

## Bảo mật

- Không có service-role key/cleanup secret trong app.
- User identity luôn lấy từ authenticated session, không nhận `user_id` từ UI.
- Nghiệp vụ thưởng/progress/unlock chỉ gọi RPC server.
- Không log token, journal, mood chi tiết hoặc PII.

## Thay thế đã cân nhắc

- Gọi Supabase trực tiếp từ widget: nhanh ban đầu nhưng coupling và test kém.
- BLoC/Cubit: hợp lệ, nhưng Riverpod phù hợp DI + async state với ít boilerplate hơn
  cho quy mô MVP.
- Local-first ngay: chưa phù hợp với quyết định MVP hiện tại và làm tăng rủi ro sync.

## Xem lại

Xem lại ADR khi bắt đầu local-first, E2EE, push đa thiết bị hoặc khi số feature
đòi hỏi tách package độc lập.

