# Privacy và safety MVP

Trạng thái: `in-progress`
Cập nhật: 2026-09-05

## Mục tiêu

MuseMend là công cụ nhật ký và phản tư. Ứng dụng không chẩn đoán, không đưa ra chỉ
định y tế và không thay thế chuyên gia sức khỏe tâm thần. Disclaimer được hiển thị
trong Reflect và mục “Điều khoản và giới hạn” ở Profile.

Nếu nội dung sản phẩm sau này phát hiện hoặc phản hồi khủng hoảng, phải có thiết kế
safety riêng, chuyên gia thẩm định và danh bạ hỗ trợ theo quốc gia; không suy luận
nguy cơ từ mood rồi tự động can thiệp trong MVP.

## Dữ liệu và quyền riêng tư

- Journal và media là dữ liệu riêng tư, được giới hạn bằng Auth/RLS và bucket private.
- Notification màn hình khóa dùng nội dung chung, không lộ title/body của journal.
- Không log nội dung journal, token, email hoặc signed URL vào analytics/CI.
- MVP lưu plaintext phía server và chưa có E2EE; UI phải mô tả đúng giới hạn này.
- Account deletion khóa nghiệp vụ ngay, queue object Storage và xóa Auth qua worker.

## Trạng thái văn bản pháp lý

Nội dung Privacy/Terms trong app hiện là bản tóm tắt cho QA nội bộ, không phải văn
bản pháp lý hoàn chỉnh. Trước khi phân phối công khai cần:

1. xác định pháp nhân/controller, email liên hệ và phạm vi quốc gia;
2. lập data inventory, retention, subprocessors và cơ sở xử lý;
3. review chính sách quyền riêng tư/điều khoản bởi người có thẩm quyền;
4. host URL công khai ổn định cho Google Play và App Store;
5. hoàn thiện export, quyền truy cập/xóa và quy trình xử lý sự cố;
6. rà soát age rating, consent và quy định dữ liệu sức khỏe áp dụng.

Thiếu các mục trên là blocker cho public release, nhưng không chặn internal MVP QA.

## Nghiệm thu

- Disclaimer không dùng ngôn ngữ chẩn đoán hoặc hứa hẹn điều trị.
- Hai account test không đọc/sửa dữ liệu nhau.
- Permission bị từ chối không làm mất dữ liệu hoặc khóa app.
- Xóa tài khoản cần xác nhận rõ và không chứa service role trong client.

Liên quan: [Security/CI](./ci-cd.md),
[Profile client](../fe/profile-overview.md),
[Notifications/cleanup DB](../db/notifications-cleanup.md).
