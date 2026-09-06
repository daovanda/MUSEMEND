# Ma trận QA MVP

Trạng thái: `in-progress`
Cập nhật: 2026-09-06

## Phạm vi đã xác nhận

| Miền | Automated | Android emulator + Supabase Dev |
|---|---|---|
| Auth/Profile | DTO/widget, 320×568 + text 200%, RLS/column grants | session restore, profile load/update, sign-out |
| Check-in | mood/DTO, RPC transaction | một check-in/ngày, sửa, streak |
| Mission/Energy | mapper/domain, RPC idempotency | custom reward 5, complete không cộng đôi |
| Journey/Library | mapper, reward integration | start, checkpoint, landmark/food unlock |
| Journal | mapper, atomic RPC/RLS | daily/future letter, mở sớm, soft-delete |
| Media | DB policy/metadata audit | Photo Picker, private upload, signed preview |
| Tags | atomic/cross-user integration | tạo/assign/reload hai tag |
| Notification | mapper, alarm config, journal-ID deep-link widget | runtime permission, alarm, foreground/cold deep-link |
| Deletion | transaction rollback | dialog bị khóa trước chuỗi xác nhận; không xóa account QA thật |
| Offline | HTTP timeout + widget error/retry | network recovery smoke-test; device cut-off cần lặp lại |

Toàn bộ Flutter format/analyze/test, APK debug build, iOS Simulator build và
database validator phải đạt trên commit phát hành nội bộ. Screenshot/build local
nằm trong thư mục bị ignore, không chứa trong Git artifact.

APK Release đầu tiên đã được CI tạo và ký tại
[`qa-v0.1.0-1-e679e367ade5`](https://github.com/daovanda/MUSEMEND/releases/tag/qa-v0.1.0-1-e679e367ade5).
Release artifact đã được xác minh ở pipeline; lượt nghiệm thu trên thiết bị thật
phải ghi theo [checklist Android](./android-device-qa-acceptance.md) trước khi đổi
trạng thái tài liệu này thành `implemented`.

## Mạng và lỗi

Supabase dùng HTTP timeout 20 giây; các màn có loading/error/retry và không hiển thị
message thô từ server. QA tắt mạng phải xác nhận Reflect chuyển sang error trong
khoảng timeout, bật mạng và “Thử lại” tải được dữ liệu. Permission notification bị
từ chối không được làm mất Future Letter.

## Chưa được chứng minh

- iOS device archive/signing, Photo Picker, notification permission/scheduling/
  deep-link và VoiceOver trên thiết bị thật;
- Android thiết bị thật, TalkBack, nhiều kích thước/font scale và mạng di động yếu;
- concurrent/load test, restore/PITR, cleanup Storage/Auth thật sau retention;
- account/session token hết hạn cưỡng bức, notification DB đúng thời điểm theo cron;
- production project tách biệt, store signing, privacy/terms URL đã legal review.

Các mục này không chặn APK QA nội bộ, nhưng iOS/public release chưa sẵn sàng cho đến
khi phần tương ứng được kiểm chứng và ký duyệt.

## Regression trước mỗi bản QA

1. Replay migration + integration test từ database sạch.
2. Format, analyze, Flutter tests và build APK từ config development.
3. Smoke-test sign-in, check-in, mission complete, journal save và profile.
4. Kiểm tra không có secret/config local trong `git status` hoặc artifact.
5. Chờ GitHub CI xanh trên commit đã push trước khi chuyển APK cho tester.

Liên quan: [Roadmap](./mvp-roadmap.md), [CI/CD](./ci-cd.md),
[Runbook](./release-runbook.md), [Privacy/safety](./privacy-safety.md),
[Nghiệm thu Android](./android-device-qa-acceptance.md).
