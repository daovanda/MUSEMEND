# Authentication client

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-19

## Mục tiêu và phạm vi

Lát cắt P0.1 hỗ trợ đăng ký, đăng nhập email/mật khẩu, khôi phục session qua SDK,
đăng xuất và khôi phục mật khẩu qua email. Profile/settings bootstrap phía DB vẫn
là nguồn sự thật.

## Luồng và trách nhiệm

`AuthRepository` là contract domain. `SupabaseAuthRepository` là adapter duy nhất
gọi Supabase Auth. `AuthController` điều phối thao tác và trạng thái async;
`SignInScreen` validate form. `authSessionProvider` điều khiển redirect
`/splash` → `/sign-in`; sau khi có session, router đọc trạng thái onboarding để
đưa tài khoản mới tới `/onboarding` và tài khoản đã hoàn tất tới `/reflect`.

Khi khởi động, session khôi phục từ bộ nhớ thiết bị chưa được coi là đăng nhập
chỉ vì token còn tồn tại cục bộ. Adapter gọi Supabase Auth để xác thực user trước
khi phát session cho router. Nếu user/session đã bị thu hồi, hết hạn hoặc không
còn tồn tại, adapter xoá session cục bộ và router trở về `/sign-in`. Việc xoá này
được phát ra ngay, không chờ endpoint thu hồi token trên server; điều đó đặc biệt
quan trọng khi tài khoản vừa bị xoá và đăng ký lại bằng cùng email. Bước xác thực
khởi động có giới hạn 15 giây, nên mạng hoặc Auth endpoint không thể giữ splash
vĩnh viễn. Khi hết thời gian mà chưa xác thực được token, app yêu cầu đăng nhập
lại để tránh tin cậy một session không rõ trạng thái.

Màn auth dùng cùng ngôn ngữ thị giác với Bầu trời: artwork phong cảnh và mascot
cục bộ, nền chuyển từ xanh trời sang kem/tím pastel, logo gradient và form kính
sáng. Ở điện thoại, thương hiệu nằm trên form; từ 820dp, màn hình tách thành vùng
chào đón và form để tận dụng chiều ngang. Form cố định palette sáng có tương phản
đủ trên cả theme hệ thống tối, tránh trường hợp nền tối kết hợp với surface kính
sáng làm chữ và input bị xám/mờ. Chuyển đăng nhập/đăng ký dùng animation 220ms và
tự bỏ focus bàn phím nhưng không thay đổi repository hay flow xác thực.
Toàn bộ tiêu đề, form, validation, lỗi an toàn và accessibility semantics lấy từ
ARB theo locale hiện hành; adapter Auth không tự tạo thông báo theo một ngôn ngữ
cố định.

Phong cảnh và hai vùng sương pastel trôi ngược chiều nhau với biên độ 4–15dp,
chu kỳ 18 giây và đường cong `easeInOutSine`. Ảnh nền được phóng nhẹ 1.035 lần để
chuyển động không lộ mép. Đây chỉ là motion trang trí; controller tự dừng khi
`MediaQuery.disableAnimations` bật và nội dung form hoàn toàn không chuyển vị trí.

Đăng ký gửi metadata `display_name` và `language_code`; trigger DB tạo
profile/settings và travel progress. Mã ngôn ngữ được lưu trong Auth metadata để
template email tùy biến có thể chọn đúng ngôn ngữ trước khi profile/settings
được tải. Tên này được điền sẵn trong onboarding, nhưng người dùng có thể đổi
hoặc bỏ qua. UI không gửi `user_id`, role hoặc quyền.

Khi người dùng đổi ngôn ngữ trong Hồ sơ, app cập nhật `language_code` trong Auth
metadata theo locale hiệu dụng (ngôn ngữ chọn tay hoặc locale thiết bị). Lỗi cập
nhật metadata không chặn việc lưu hồ sơ/cài đặt vì đây chỉ là dữ liệu
personalization cho email.

### Web callback portal

Trên Flutter Web, router chỉ mở landing trung tính, `/email-confirmed` và
`/reset-password`. Trang web không phải bản web của app: các route sign-in,
onboarding và nghiệp vụ không render giao diện ứng dụng. Android/iOS giữ nguyên
flow đăng nhập và onboarding native. Đăng ký truyền
`emailRedirectTo=https://musemend-app.vercel.app/email-confirmed`; recovery từ
bất kỳ nền tảng nào dùng web `/reset-password`. Trang xác nhận chỉ hiển thị
thành công sau khi callback hợp lệ khôi phục session; nếu link sai/hết hạn thì
hiện hướng dẫn mở link mới. Root chỉ hướng dẫn mở email, không giả làm trang xác
nhận thành công.

### Khôi phục mật khẩu

Từ màn đăng nhập, người dùng chuyển sang form chỉ yêu cầu email. App gọi
`AuthRepository.requestPasswordReset`, adapter dùng
`supabase.auth.resetPasswordForEmail` và hiển thị thông báo thành công chung để
không tiết lộ email có tồn tại hay không. Liên kết trong email luôn trỏ tới URL
web production cố định `https://musemend-app.vercel.app/reset-password`, kể cả
khi người dùng yêu cầu email từ app di động hoặc bản Flutter Web local. Flutter
Web dùng `PathUrlStrategy`; Vercel rewrite callback route về app shell để giữ
pathname riêng và session callback của Supabase. Trên web, form chỉ hiện khi có
session hợp lệ từ link recovery; mở URL trống sẽ hiện trạng thái link không hợp
lệ, không hiển thị form có thể submit vô ích.

Màn đặt lại yêu cầu mật khẩu mới và nhập lại mật khẩu, sau đó gọi
`supabase.auth.updateUser`. Đây là lần ghi mật khẩu thật lên Supabase Auth, không
chỉ đổi trạng thái giao diện. Khi thành công app đăng xuất phiên recovery và
đưa người dùng về đăng nhập với thông báo đã đổi mật khẩu. Link recovery dùng
`{{ .ConfirmationURL }}` do Supabase tạo: token riêng cho yêu cầu, dùng một lần;
Email OTP Expiration đặt 3600 giây (1 giờ).

Email xác nhận đăng ký có template riêng, cũng dùng `{{ .ConfirmationURL }}` và
chọn nội dung theo `language_code`; callback hợp lệ mở trang web báo xác nhận
thành công và hướng người dùng quay lại app. Hai HTML source được giữ trong
`supabase/templates/confirm-sign-up.html` và
`supabase/templates/reset-password.html`; nội dung được đồng bộ thủ công với
Supabase Dashboard hosted.

Supabase Auth phải allow-list URL production `/email-confirmed` và
`/reset-password`. Không cần allow-list từng origin local cho luồng email vì
liên kết luôn trỏ tới domain public. Không lưu token vào DB, log
hoặc repository. Email recovery và confirmation không được đi qua click tracking
có thể viết lại/xử lý trước token.

## Validation và lỗi

Email phải đúng định dạng, tên 2–60 ký tự, mật khẩu tối thiểu 8 ký tự. Lỗi Auth
được ánh xạ sang thông báo an toàn, không hiện stack trace/schema/token. Trạng thái
loading khóa submit lặp. Nếu project bật email confirmation, user được nhắc kiểm
tra email và vẫn ở màn hình auth cho tới khi có session.

## Bảo mật và riêng tư

SDK quản lý session; app không log token, mật khẩu hay email. Client chỉ dùng
publishable key. RLS vẫn là lớp phân quyền dữ liệu, không dựa vào việc ẩn UI.

## Kiểm thử và nghiệm thu

Widget test kiểm tra chuyển sign-up, validation và khả năng cuộn/sử dụng trên màn
hình 320×568 ở text scale 200%; nút submit vẫn giữ vùng chạm tối thiểu 48 px.
Widget test cũng kiểm tra màn auth ở dark theme vẫn giữ nền kem và chữ form màu
`MuseColors.ink`, đồng thời artwork nền/mascot lấy từ asset bundle nội bộ.
Test Reduce Motion xác nhận transform nền không đổi theo thời gian khi animation
bị vô hiệu hóa.
Unit test session policy xác nhận lỗi `user_not_found`/session hết hạn làm sạch
session khôi phục, còn lỗi kết nối có thể retry không làm mất đăng nhập cục bộ.
Luồng khôi phục phiên bị thu hồi không chờ server revoke; kiểm thử khởi động cần
bao gồm trường hợp xoá tài khoản, đăng ký lại cùng email và đăng nhập trên thiết bị
còn token cũ.
Android QA đã xác nhận đăng nhập, session restore và sign-out. Database integration
kiểm tra bootstrap cùng cách ly hai tài khoản. Widget/unit test kiểm tra việc yêu
cầu reset dùng URL public và màn reset gọi update password rồi sign-out. Cần QA
thực tế trên email mới để xác nhận sign-up template, callback production, link chỉ
dùng một lần/hết hạn sau 1 giờ, đổi mật khẩu thành công rồi đăng nhập lại; không
dùng mật khẩu người dùng thật trong automated tests.

## Tương thích, rollback và việc còn lại

Không có migration trong thay đổi client này. Revert adapter/UI không làm mất dữ
liệu Auth. Còn thiếu xử lý account-disabled chi tiết và QA end-to-end trên email
test; password reset không được xem là verified production cho tới khi người dùng
hoàn tất lần QA thủ công này.

## Liên quan

- [Application foundation](./application-foundation.md)
- [Profiles, settings và ownership](../db/profiles-settings.md)
- [Roadmap MVP](../other/mvp-roadmap.md)
