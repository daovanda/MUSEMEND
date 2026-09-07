# Journal editor

- **Trạng thái:** `in-progress`
- **Cập nhật:** 2026-09-07

## Mục tiêu và phạm vi

Nhật ký là không gian viết tự do, không phải một form ngắn trong dialog. Khi tạo
hoặc chạm vào một daily journal/future letter, app mở `JournalEditorScreen` toàn
màn hình. Người dùng có thể viết dài, sửa lại, gắn tag và thêm ảnh riêng tư ngay
trong trang viết.

## Bố cục trang viết

Editor dùng chung nền gradient của trang, không đặt tiêu đề hoặc nội dung vào
card/input box riêng. Thứ tự thị giác giống một lá thư:

1. ngày, tháng, năm ở phía trên (chỉ áp dụng cho nhật ký hàng ngày);
2. tiêu đề với serif lớn, đậm;
3. nội dung với serif thoáng, line-height rộng để đọc và viết dài.

Với thư gửi tương lai, ngày hiện tại không chiếm vị trí đầu trang. Ngày thư đến
được đặt ở phần cuối lá thư, sau nội dung và tùy chọn nhắc, để giữ cảm giác một
lá thư hoàn chỉnh.

Các trường vẫn là `TextField` để giữ bàn phím, selection và accessibility của
Flutter, nhưng decoration trong suốt, không fill, không outline. Divider mảnh
chỉ dùng để phân nhịp giữa tiêu đề và nội dung. Tag, ảnh và tùy chọn thư nằm sau
nội dung với nhãn nhẹ; không tạo thêm một “form card” cạnh tranh với trang viết.

## Luồng

1. `JournalScreen` tải danh sách owner-scoped và chỉ điều hướng tới editor.
2. Editor gọi `JournalController.saveDaily()` hoặc `saveFutureLetter()` qua
   repository/RPC; không gọi Supabase trực tiếp.
3. Sau khi có journal ID, nút `Thêm ảnh` gọi picker → upload private →
   `attach_journal_media()`. Ảnh hiện trên canvas tự do trong vùng ghi chú; người
   dùng kéo một ngón tay để di chuyển, chụm hai ngón để đổi cỡ và xoay hai ngón
theo ý muốn. Ảnh dùng `BoxFit.contain`, nên không crop.
Mỗi ảnh có thêm một ghim đỏ nhỏ đè lên đúng góc trên-trái như một lớp trang trí;
ghim dùng cùng transform của ảnh (vị trí, góc và tỉ lệ) và không bắt gesture nên
không cản trở việc kéo, đổi cỡ hoặc xoay ảnh.
4. Future letter cho phép đổi ngày mở, mở sớm theo quyết định MVP và tùy chọn nhắc
   trên thiết bị. Payload notification chỉ chứa journal ID.
5. Lưu thành công quay về danh sách; controller reload nên card hiển thị nội dung
   mới ngay.

## Validation và lỗi

Title tối đa 120, content tối đa 10.000 và không được rỗng; tối đa 8 tag, mỗi tag
40 ký tự. Ngày thư mới phải từ ngày mai đến 10 năm. Lỗi upload/permission chỉ
hiện thông báo an toàn; bản ghi server không bị coi là thất bại nếu local reminder
không tạo được.

Editor yêu cầu lưu lần đầu trước khi gắn ảnh để có journal ID và storage prefix.
Các attachment hiện được trình bày trên canvas ảnh trong trang viết. Mỗi gesture
được lưu vào `journal_media` qua `update_journal_media_transform()` sau khi thả
tay; metadata vị trí/kích thước/góc vẫn giữ nguyên khi mở lại trang. Vị trí ảnh
inline giữa từng đoạn văn sẽ là bước riêng khi schema có model block/position.
Trong giai đoạn triển khai migration theo từng môi trường, thao tác đọc vẫn có
fallback về ba cột media cũ nếu project từ xa chưa có metadata transform; thao
tác lưu transform chỉ hoạt động sau khi migration đã được áp dụng.

## Privacy và security

Ảnh đi qua Photo Picker, giới hạn 10 MiB và bucket private; preview dùng signed URL
ngắn hạn. RLS/RPC kiểm tra owner, còn UI không tự quyết định quyền hoặc đường dẫn.
Không đưa title/content vào analytics, URL hay lock-screen notification.

## Kiểm thử và rollback

Deep-link test xác nhận entry mở trong editor toàn màn hình và không tạo
`AlertDialog`. Chạy `flutter analyze --fatal-infos` và `flutter test`. Rollback UI
bằng revert commit. Không sửa hoặc xóa migration đã chạy; nếu cần rollback dữ
liệu, giữ các cột transform vì chúng chỉ là metadata trình bày và không làm thay
đổi file ảnh gốc.

## Việc còn lại

Thêm preview inline theo vị trí con trỏ, xoá/reorder ảnh và draft local khi chuyển
sang local-first. Những việc này không làm thay đổi quy tắc private storage.

Liên quan: [Daily Journal và Future Letter](./journals-future-letters.md),
[Journal DB và Storage](../db/journals-media.md), [UI system](./ui-system.md).
