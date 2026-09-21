# Google OAuth qua Supabase

**Trạng thái:** `in-progress`
**Cập nhật:** 2026-09-21

## Mục tiêu và phạm vi

Cho phép người dùng MuseMend bắt đầu bằng Google trên Android, iOS và Flutter
Web QA. Supabase Auth là broker OAuth duy nhất. Flutter không dùng Google
Client Secret, service-role key hoặc SDK Google Sign-In.

## Luồng và trách nhiệm

```text
Flutter app → Supabase Auth → Google consent → Supabase callback
            → URL deep link của app / origin Flutter Web QA
            → authSessionProvider → onboarding hoặc app
```

`SupabaseAuthRepository.signInWithGoogle` yêu cầu `OAuthProvider.google`. Trên
native, callback cuối là `com.musemend.app://login-callback`; Android nhận host
đó trong manifest và iOS đã đăng ký scheme. Trên Flutter Web, callback quay về
origin đang QA. Auth state là nguồn điều hướng duy nhất; không chép access token
vào route, database hay log.

Account Google mới được trigger `handle_new_auth_user` tạo `profiles` từ metadata
của Auth. `full_name` và `avatar_url` được nhận nếu Google cung cấp, provider
được nhận là `google`; onboarding vẫn yêu cầu hoàn tất trước khi vào app.

## Cấu hình Google Cloud và Supabase

1. Trong Google Cloud Console, chọn hoặc tạo project riêng cho MuseMend.
2. Hoàn tất branding, audience và test users theo trạng thái consent screen.
3. Tạo OAuth Client loại **Web application**. Đây là client Supabase dùng làm
   callback broker, kể cả khi app đích là Android/iOS.
4. Thêm Authorized redirect URI duy nhất:
   `https://jpoktrdyehalxkhdhkzu.supabase.co/auth/v1/callback`.
5. Thêm Authorized JavaScript origin công khai
   `https://musemend-app.vercel.app`, và để QA Flutter Web local thêm origin chính xác của
   server đang chạy, ví dụ `http://127.0.0.1:64580`. Không dùng wildcard ở
   Google Cloud.
6. Vào Supabase Dashboard → Authentication → Providers → Google, bật provider,
   nhập Client ID và Client Secret, rồi lưu. Client Secret chỉ nhập trực tiếp ở
   Dashboard và phải rotate nếu đã lộ.
7. Vào Supabase Dashboard → Authentication → URL Configuration, thêm các
   redirect URL sau:
   - `com.musemend.app://login-callback`
   - `http://127.0.0.1:64580` (chỉ QA local hiện tại; thay/loại bỏ khi port đổi)

Không thêm deep link `com.musemend.app://...` vào Google Authorized redirect
URIs: Google luôn chỉ quay về Supabase callback. Không đổi Site URL sang local.

## Production consent và public portal

Google có ngoại lệ cho Sign in with Google chỉ dùng `openid`, `email`,
`profile`: một External app ở `Testing` có thể cho account Google khác thử luồng
này mà không phải thêm vào test-user list. Đây chỉ là tiện ích QA; trạng thái
production vẫn phải được publish rõ ràng. Khi publish External app, portal
Vercel phải phục vụ trực tiếp ba URL sau, không yêu cầu đăng nhập và không
redirect sang domain khác:

- `https://musemend-app.vercel.app/`
- `https://musemend-app.vercel.app/privacy`
- `https://musemend-app.vercel.app/terms`

Trang home liên kết rõ tới Privacy. Privacy giải thích rằng Google Sign-In chỉ
dùng tên, email và ảnh đại diện để xác thực/tạo profile, không đọc Gmail,
Contacts hoặc Drive. Chủ sản phẩm PHẢI rà soát nội dung pháp lý trước public
release, thay vì coi bản mô tả MVP này là tư vấn pháp lý.

Sau khi Vercel production deployment đã được kiểm tra trực tiếp, điền đúng ba
URL vào Google Auth Platform → Branding, giữ Audience `External`, rồi chuyển
Audience sang `In production`. Không đưa Client Secret vào Vercel hay Flutter.
Google khuyến nghị tách Cloud project development/QA và production; khi tách,
tạo Client ID/Secret Web mới cho project production và thay cấu hình Provider
trên Supabase tương ứng.

## Bảo mật và privacy

- Chỉ yêu cầu scopes chuẩn `openid`, `email`, `profile`; không thêm scope nhạy
  cảm hoặc restricted khi chưa threat review.
- Client ID là định danh công khai; Client Secret chỉ ở Supabase provider config.
- Không đặt secret trong Flutter `--dart-define`, Vercel variables dùng cho
  client, GitHub secrets log, test fixture hay ticket.
- Redirect URL phải là allow-list hẹp; dùng scheme/package đã sở hữu để tránh
  app khác bắt callback. Kiểm tra lại deep link sau khi đổi application ID.
- Supabase có thể liên kết tự động account email/Google khi email đã được xác
  thực và duy nhất. Không viết logic client để gộp hoặc chiếm account.

## Kiểm thử và nghiệm thu

- Widget test: nút Google có ở sign-in/sign-up, không có ở quên mật khẩu, và
  gọi đúng repository contract.
- Android/iOS: chọn Google, hủy consent, và hoàn tất consent; kiểm tra return
  từ browser về app, onboarding account mới và app của account cũ.
- Flutter Web QA: chỉ dùng origin đã cấu hình ở Google Cloud/Supabase redirect
  allow-list; verify không có URL token trong log.
- Một account email hiện hữu và một account Google cùng email phải được thử theo
  chính sách identity linking của Supabase trước khi public release.

## Rollout, rollback và giới hạn

Provider Google đã bật trong Supabase Development, nhưng app chưa là public
production khi Vercel/Google Consent chưa hoàn tất. Google không thu phí riêng
để publish OAuth consent; nếu branding hoặc scope cần verification thì thời
gian review là yếu tố cần theo dõi. Nếu cần rollback, tắt Google Provider ở
Supabase trước; app sẽ nhận lỗi an toàn từ Auth, không làm mất account hoặc dữ
liệu. Có thể phát hành bản app bỏ nút ở một bản sau nếu cần, nhưng không xoá
Google identity của người dùng trong rollback.

Google consent screen ở chế độ testing chỉ cho test users và authorization của
test user hết hạn sau bảy ngày; phải chuẩn bị publishing/verification trước
public release. Các scope mở rộng có thể cần review của Google.

## Liên quan

- [Authentication client](../fe/authentication.md)
- [Supabase Google Auth](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Supabase Flutter OAuth](https://supabase.com/docs/reference/dart/auth-signinwithoauth)
- [Supabase identity linking](https://supabase.com/docs/guides/auth/auth-identity-linking)
