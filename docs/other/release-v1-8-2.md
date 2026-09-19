# Android QA release 1.8.2

- **Trạng thái:** `in-progress`
- **Cập nhật:** 2026-09-19

## Mục tiêu

Phát hành bản QA tiếp theo `1.8.2+7`, tăng Android build number từ `+6` lên
`+7` để hỗ trợ cài đè. Bản này hoàn thiện luồng auth email cho app di động và
web callback portal, đồng thời bao gồm các chỉnh sửa onboarding/logo chưa phát
hành trong working tree.

## Thay đổi chính

- Web public chỉ có landing trung tính, xác nhận email và đặt lại mật khẩu; không
  cung cấp sign-in, onboarding hoặc các màn nghiệp vụ của app.
- Link xác nhận và khôi phục mật khẩu dùng URL public callback; form reset chỉ
  hiện sau callback hợp lệ và ghi mật khẩu mới thật lên Supabase Auth.
- Nội dung auth được bản địa hoá; template xác nhận và template reset được giữ
  riêng. Vercel rewrite callback path về Flutter Web app shell.
- Hoàn thiện logo mascot và bố cục/điều hướng onboarding, đồng bộ với giao diện
  sáng và responsive hiện tại.

Không có migration database hoặc thay đổi quyền/RLS trong release này.

## Luồng QA/phát hành

1. Tạo PR từ `feature/*` vào `develop`; chờ CI và review.
2. Squash merge vào `develop`. CI thành công sẽ kích hoạt workflow tạo Android QA
   Release `qa-v1.8.2-7-<commit>` từ đúng SHA đã xác minh.
3. Cài APK đè lên `1.8.1+6`, xác minh package ID, chữ ký và SHA-256.
4. Kiểm tra luồng đăng ký/xác nhận email và quên mật khẩu bằng tài khoản QA;
   không sử dụng link reset của người dùng thật.
5. Xác minh Vercel có deploy bản callback portal và Supabase allow-list gồm
   `/email-confirmed` cùng `/reset-password` trước khi kiểm tra email production.

## Tiêu chí nghiệm thu

- `flutter analyze`, toàn bộ Flutter tests và build Flutter Web đạt.
- Android version code tăng đơn điệu lên `7`; app cài đè và giữ dữ liệu hiện có.
- Root và URL không xác định không hiển thị sign-in; callback hợp lệ hiển thị
  đúng trạng thái, callback sai/hết hạn không mở form đổi mật khẩu.
- Recovery link dùng một lần, hết hạn sau một giờ; đổi mật khẩu xong đăng nhập
  được lại trong app bằng mật khẩu mới.
- Vercel và Supabase QA configuration được xác minh; không commit secret, token,
  thông tin người dùng hoặc link có token.

## Rollback

Đây là thay đổi app/UI/auth callback không có migration. Nếu QA phát hiện lỗi,
không phát hành APK đó; tạo forward-fix trên nhánh mới và tăng build number tiếp
theo. Không di chuyển hoặc ghi đè GitHub Release/tag đã tạo.

Liên quan: [Android QA Release](./android-qa-release.md),
[Authentication](../fe/authentication.md), [Auth email templates](../be/auth-email-templates.md).
