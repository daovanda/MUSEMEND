# Daily quotes catalog

**Trạng thái:** `implemented`  
**Cập nhật:** 2026-09-12

## Mục tiêu và phạm vi

Database cung cấp một lời nhắn tích cực ổn định trong từng ngày Việt Nam và đổi
sang câu khác khi sang ngày mới. Catalog ban đầu có đúng 100 câu nguyên bản: 20
câu cho mỗi chủ đề yêu đời, tận hưởng khoảnh khắc, cuộc sống, mỉm cười và hạnh
phúc.

## Schema và seed

`public.daily_quotes` lưu `rotation_order`, `topic`, `content`, trạng thái active
và thời điểm tạo. Constraint bảo vệ thứ tự dương, năm topic hợp lệ, nội dung duy
nhất và độ dài 1–240 ký tự. Seed nằm trong migration
`20260912090000_daily_quotes.sql` và dùng một batch insert xác định.

RLS được bật nhưng client không có quyền trực tiếp trên bảng. Việc thêm, sửa,
ẩn hoặc sắp xếp quote phải đi qua migration/content operation được review.

## Chọn quote theo ngày

`muse_private.daily_quote_for_date(date)` xếp các câu active theo
`rotation_order` và ánh xạ ngày vào vòng quay bằng modulo. Epoch là 2026-09-12;
cùng một ngày luôn trả cùng một câu, ngày kế tiếp trả mục kế tiếp và sau 100 ngày
vòng quay bắt đầu lại. Hàm nội bộ không được cấp quyền cho app.

`public.get_daily_quote()` không nhận tham số, tự lấy ngày bằng
`now() AT TIME ZONE 'Asia/Ho_Chi_Minh'`, kiểm tra phiên đăng nhập và tài khoản
active, rồi trả `rotation_order`, `content`, `topic`, `quote_date`. Chỉ role
`authenticated` có quyền execute.

## Bảo mật và lỗi

Quote là catalog không chứa dữ liệu người dùng nhưng vẫn áp dụng least privilege:
client không được ghi bảng, không được gọi helper theo ngày và không quyết định
ngày hiển thị. Nếu không còn quote active, RPC trả rỗng và client chuyển sang
trạng thái lỗi có nút thử lại; vận hành phải luôn giữ ít nhất một mục active.

## Kiểm thử, triển khai và rollback

Database integration test xác nhận đúng 100 câu, năm topic mỗi topic 20 câu,
cùng ngày trả cùng mục, hai ngày liên tiếp trả mục khác và RPC authenticated dùng
đúng ngày Việt Nam. Migration là additive và tương thích client cũ. Nếu cần sửa
sau deploy, dùng migration forward; rollback app vẫn an toàn vì client cũ còn
quote hard-code, còn client mới cần RPC này.

## Liên quan

- [Daily quote Flutter](../fe/daily-quotes.md)
- [Migrations và kiểm thử](./migrations-testing.md)
