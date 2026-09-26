# Android QA 1.8.3

Trạng thái: `in-progress`
Cập nhật: 2026-09-27

## Mục tiêu và phạm vi

Phát hành `1.8.3+9` trên kênh Android QA, tích hợp thay đổi màn Bầu trời vào
`develop` và triển khai migration trên Supabase Development. Đây chưa phải bản
production/store.

## Thay đổi

- Check-in chỉ mở từ 12:00 giờ Việt Nam; RPC từ chối ghi sớm kể cả client cũ.
- Năm nhãn cảm xúc đổi tên, giữ icon; lời chào buổi sáng và lời đáp theo mood
  ổn định trong ngày, mỗi nhóm có 20 phương án và đủ 12 ngôn ngữ.
- Journey chưa khởi hành tự bắt đầu qua RPC; trạng thái đã bắt đầu không bị reset.
- Daily mission chọn sáng/trưa/chiều/tối; gợi ý khớp mood được ưu tiên, trước
  check-in chỉ hiện gợi ý trung tính.
- Bố cục Bầu trời và nút mây giữa bottom navigation vẫn như bản trước; tài liệu
  đề xuất “Thử thách” và nút Phản tư nổi chưa thuộc phạm vi phát hành này.

## Triển khai và tương thích

Merge PR vào `develop` sau CI/review. Workflow triển khai Development chạy các
migration `20260926170000` và `20260926171000`; workflow Android QA tạo APK đã
ký và prerelease với tag `qa-v1.8.3-9-<sha>`. Kiểm tra deployment thành công
trước khi gửi APK cho QA. Không đưa secret hoặc tài khoản người dùng vào release.

Migration check-in giữ nguyên chữ ký RPC. Client cũ gọi trước trưa sẽ nhận lỗi;
client mới khóa UI và RPC xác thực lại trên máy chủ. Catalog migration chỉ đổi
`target_mood` của template hệ thống, không đụng nhiệm vụ đã tạo hoặc mức thưởng.

## Kiểm thử và nghiệm thu

- `flutter analyze --fatal-infos`, `flutter test`, `flutter build web`.
- `node tools/db-validation/validate.mjs` cho migration và integration/RLS.
- CI Android QA build và phát hành phải xanh. QA trên thiết bị xác nhận cập nhật
  từ `1.8.2+8`, check-in trước/sau 12:00, lời đáp theo mood, journey tự mở và
  gợi ý/ngày nhiệm vụ.

## Rollback

Nếu APK lỗi, đánh dấu prerelease không dùng và phân phối lại bản `1.8.2+8` chỉ
cho cài mới; Android thường không cài đè build number thấp hơn. Nếu logic mới
gây lỗi dữ liệu, dùng migration forward-fix mới thay vì sửa/xóa migration đã
chạy. Server check-in trước trưa cần được điều chỉnh bằng migration mới và kiểm
thử an toàn trước khi khôi phục hành vi cũ.

## Liên quan

- [Runbook phát hành](./release-runbook.md)
- [Màn Bầu trời](../fe/sky-screen.md)
- [Daily check-in DB](../db/daily-checkins-streak.md)
- [Missions DB](../db/missions-energy.md)
