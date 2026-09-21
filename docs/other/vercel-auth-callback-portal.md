# Vercel public auth portal

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-21

> Theo [ADR-0005](./adr-0005-in-app-email-otp.md), email mới chỉ gửi OTP 6 số
> và hoàn tất xác nhận/đặt lại mật khẩu trong ứng dụng. Portal không còn là đích
> của email mới, nhưng là homepage công khai cho Google OAuth branding.

## 1. Mục tiêu và phạm vi

Deploy Flutter Web public information portal vào project Vercel hiện có
`musemend-app`, giữ nguyên domain `https://musemend-app.vercel.app`. Portal
phục vụ homepage, Privacy, Terms và callback email lịch sử; không phải bản web
để đăng nhập hoặc sử dụng nghiệp vụ.

Không xóa project hiện tại để sửa nội dung sai. Project hiện tại sở hữu domain;
xóa project sẽ làm domain mất liên kết nhưng không sửa source hoặc callback. Thay
vào đó kết nối GitHub repository `daovanda/MUSEMEND` vào đúng project hiện có.

## 2. Build và deploy

`app/vercel.json` phù hợp khi Project Root Directory là `app`; `vercel.json` ở
repo root cũng hỗ trợ cấu hình root directory tại repo. Cả hai dùng cùng script
`app/tool/vercel_build.sh`, giữ rewrite cho `/email-confirmed`,
`/reset-password`, `/privacy`, `/terms`, và publish `build/web` của Flutter.

Script bật `PUBLIC_AUTH_PORTAL=true`, đọc phiên bản Flutter từ `app/.fvmrc`, tìm đúng release stable trong
manifest chính thức của Flutter, xác minh SHA-256 từ manifest trước khi giải nén,
cài dependencies theo `pubspec.lock`, rồi build release. `APP_ENV` phải được đặt
tường minh là `development` hoặc `production`; không suy ra từ `VERCEL_ENV` vì
alias domain callback hiện tại có thể đang phục vụ QA bằng Supabase Development.
Build fail-closed nếu thiếu cấu hình, URL không hợp lệ hoặc khóa không phải
publishable/legacy `anon`. Build log không in giá trị biến.

Một số build container của Vercel chạy Flutter với quyền root trong khi SDK đã
giải nén có owner khác. Trước khi gọi Flutter, script chỉ thêm thư mục SDK đã
được xác minh SHA-256 vào Git `safe.directory`; không đánh dấu an toàn toàn bộ
repository hoặc thư mục rộng hơn.

Project cần kết nối repo `daovanda/MUSEMEND` và đặt Root Directory là `app`.
Trong giai đoạn QA callback hiện tại, đặt Vercel Production Branch là `develop`
để domain callback cố định nhận bản đã merge; đây chỉ là ngoại lệ cho portal
callback Dev, không biến nhánh `develop` thành nhánh phát hành sản phẩm. Git
Vercel tạo Preview cho PR và các nhánh ngoài `develop`; Production domain chỉ
đổi sau deployment mới. Khi callback Production được tách riêng, chuyển branch
và variables theo quy trình release đã duyệt.

## 3. Supabase environment và bảo mật

Build cần ba Dart defines: `APP_ENV`, `SUPABASE_URL` và
`SUPABASE_PUBLISHABLE_KEY`. Chúng được nhập thành Vercel Environment Variables,
không commit vào Git. Chỉ publishable/anon key được phép nhúng vào Flutter Web;
không đưa service-role key, database password, SMTP key, access token hay bất kỳ
secret đặc quyền nào vào client hoặc biến build.

Một deployment chỉ xác thực được token do đúng project Supabase của nó phát hành.
Hiện cả email Dev và Production đều trỏ cứng tới cùng domain
`musemend-app.vercel.app`; vì vậy **một build trên alias này chỉ có thể phục vụ
một môi trường Supabase tại một thời điểm**. Để QA luồng email hiện tại, Vercel
Production alias phải tạm thời build với `APP_ENV=development`, URL và
publishable/anon key của Supabase Development. Vercel Preview cũng dùng cùng bộ
Dev variables. Không dùng alias đó làm callback Production cho đến khi có domain
callback tách riêng hoặc một thiết kế callback đa project được rà soát bảo mật.

`app/config/prod.json` chưa có; chỉ có file mẫu. Do đó chưa xác nhận được
Production auth callback. Khi phát hành thật cần chọn một trong hai phương án:
domain callback riêng cho Production (khuyến nghị), hoặc chuyển có kiểm soát bộ
Vercel Production variables sang Supabase Production và kiểm thử email Production
mới. Không chuyển qua lại variables khi QA đang sử dụng.

`musemend-app.vercel.app/email-confirmed` và
`musemend-app.vercel.app/reset-password` phải có trong Supabase Auth Redirect URL
allow-list của project phát email. Auth portal build và project Supabase phải
cùng môi trường. Email verification/recovery phải kiểm tra bằng link thử mới,
không tái sử dụng token đã mở.

## 4. Kiểm thử và nghiệm thu

- `bash -n app/tool/vercel_build.sh` kiểm tra shell syntax.
- Flutter analyze, test và `flutter build web --release` kiểm tra ứng dụng.
- Kiểm tra artifact chứa `index.html`, `vercel.json` routing và route
  `/email-confirmed`, `/reset-password`, nhưng không có file cấu hình cục bộ.
- Preview URL phải xác nhận trang root mô tả MuseMend, liên kết được tới Privacy
  và Terms, không có sign-in; route confirmation/reset phải tải Flutter portal,
  không trả 404/login.
- Với cấu hình QA tạm thời, tạo email Dev thử mới để kiểm tra xác nhận và reset;
  token phải còn hạn, chưa sử dụng, và được phát từ cùng Supabase Development.

## 5. Rollback và giới hạn

Vercel hỗ trợ rollback deployment về bản production trước đó; không xóa project
hay domain. Nếu Git build không thành công, giữ nguyên deployment Production đang
serve, xử lý build log trên Preview trước rồi mới promotion. SDK Flutter được
tải trong build và xác minh hash; build lần đầu/từng build sạch cần thêm thời gian
tải SDK.

Chỉ coi setup hoàn tất khi GitHub connection, branch tracking, Vercel variables,
successful deployment và auth email QA được xác minh trực tiếp. Project hiện tại
đang ở dạng Vercel Drop và chưa kết nối Git; chưa được xem là đã chuyển sang
automatic deployment. Vercel Flutter SDK được tải lại ở build sạch; chưa cấu hình
persistent SDK cache nên build đầu tiên có thể lâu hơn.

## 6. Liên quan

- [CI/CD](./ci-cd.md)
- [ADR-0004 — Web chỉ phục vụ callback Auth](./adr-0004-web-auth-callback-portal.md)
- [Flutter Web local QA](../fe/flutter-web-local.md)
- [Authentication](../fe/authentication.md#web-callback-portal)
