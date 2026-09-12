# Daily quote Flutter

**Trạng thái:** `implemented`  
**Cập nhật:** 2026-09-12

## Mục tiêu và phạm vi

Quote card trên Bầu trời đọc lời nhắn mỗi ngày từ Supabase thay cho chuỗi
hard-code. Nội dung chỉ là plain text và luôn được Flutter render bằng `Text`.

## Kiến trúc và luồng

Module `features/quotes/` tách thành domain, data và application:

- `DailyQuote` và `DailyQuoteRepository` là contract domain;
- `SupabaseDailyQuoteRepository` gọi RPC `get_daily_quote()` và DTO kiểm tra
  response trước khi ánh xạ;
- `dailyQuoteProvider` tải quote, tự hủy khi màn hình rời đi và tự invalidate sau
  nửa đêm UTC+7 nếu app vẫn mở;
- `_SkyQuoteCard` hiển thị loading, dữ liệu hoặc lỗi có nút thử lại.

Không đưa HTML, URL hoặc attribution từ DB vào widget. Flutter không tự chọn
random và không gửi ngày lên server, nên reload trong cùng ngày không đổi câu.

## Validation, riêng tư và lỗi

DTO yêu cầu đủ `rotation_order`, `content`, `topic`, `quote_date`; response rỗng
hoặc sai contract tạo lỗi định dạng chung, không lộ SQL. Quote không chứa dữ liệu
riêng tư. Client chỉ dùng publishable key và quyền execute RPC authenticated.

## Kiểm thử và tương thích

Unit test xác nhận DTO mapping. `flutter analyze` và toàn bộ test phải đạt. Client
mới yêu cầu migration daily quotes được deploy trước hoặc cùng release; khi RPC
chưa sẵn sàng, card hiển thị retry nhưng các phần Home khác vẫn hoạt động.

## Liên quan

- [DB daily quotes](../db/daily-quotes.md)
- [Màn Bầu trời](./sky-screen.md)
