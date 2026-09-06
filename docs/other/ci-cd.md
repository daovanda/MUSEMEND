# CI/CD của MuseMend

**Trạng thái:** `in-progress`  
**Cập nhật:** 2026-09-05

## 1. Mục tiêu và phạm vi

Tài liệu này mô tả pipeline hiện có cho Flutter và Supabase. Mục tiêu là phát
hiện lỗi trước khi merge, chỉ triển khai revision đã qua CI, tách hoàn toàn Dev
khỏi Production và không đưa credential vào repository.

Phần tự động phát hành AAB lên Google Play và archive iOS lên App Store Connect
chưa được triển khai vì ứng dụng, application ID, signing key và tài khoản store
chưa được chốt. Không được hiểu artifact APK debug là bản production.

## 2. Luồng nhánh và môi trường

```text
feature/* hoặc fix/*
        |
        v
Pull request -> CI -> review -> develop
                               |
                               v
                     Supabase Development
                     + APK debug cho tester
                               |
                              QA
                               |
                  release/* -> main -> tag vX.Y.Z
                                         |
                                         v
                           production preflight
                                         |
                              manual approval
                                         |
                                         v
                             Supabase Production
```

- `CI` chạy với pull request vào `develop`/`main`, push lên các nhánh chuẩn và
  khi gọi thủ công.
- `Deploy Supabase Development` tự chạy sau khi workflow `CI` của `develop`
  thành công. Lần chạy thủ công chỉ hợp lệ khi workflow được gọi từ `develop`.
- `Deploy Supabase Production` chỉ có `workflow_dispatch`, bắt buộc nhập tag
  phiên bản thuộc lịch sử `main`, xác nhận QA và qua Environment `production`.
- Không deploy production trực tiếp từ working tree, branch feature hay SHA chưa
  được gắn tag.

## 3. Các quality gate hiện có

### Policy và tài liệu

- Actionlint đã cố định phiên bản và kiểm tra checksum trước khi phân tích cú pháp,
  biểu thức và shell script trong workflow.
- Kiểm tra các README/AGENTS bắt buộc tồn tại và không rỗng.
- Trong pull request, thay đổi `app/`, Edge Functions, database hoặc workflow
  phải kèm tài liệu Markdown đúng miền.
- Branch protection trên GitHub phải bắt buộc job này và code review trước merge.

### Security

- Gitleaks quét toàn bộ Git history mà không nhận credential của môi trường.
- Workflow mặc định chỉ có quyền `contents: read`; checkout không giữ credential.
- Dependency của database validator được cài bằng `npm ci` từ lockfile và được
  kiểm tra advisory mức `high` trở lên.
- Pull request không được nhận secret Dev/Production.

### Database

`node tools/db-validation/validate.mjs` tạo PostgreSQL nhúng sạch, replay các
migration có thể chạy cục bộ và chạy integration test RPC/RLS trong transaction
rollback. Những migration hosted scheduler bị validator hiện tại bỏ qua; vì vậy
chúng phải tiếp tục được thiết kế idempotent và xác minh trên Supabase Dev trước
Production.

### Edge Functions

Deno lint và type-check toàn bộ file TypeScript dưới `supabase/functions/`.
Không gọi function thật và không cần service-role key trong CI.

### Flutter Android

Khi `app/pubspec.yaml` chưa tồn tại, job giải thích và bỏ qua. Module Flutter dùng
`app/.fvmrc` làm nguồn phiên bản SDK; phiên bản đã chốt cho nền MVP là Flutter
`3.29.2` (Dart `3.7.2`). Job sẽ cài dependency theo lockfile, kiểm tra
format/analyze, chạy test, build APK debug và lưu artifact 7 ngày. APK này chỉ
dành cho tester nội bộ. Thay đổi SDK phải cập nhật `.fvmrc`, kiểm chứng toàn bộ CI
và ghi rõ khả năng tương thích trong tài liệu/PR.

### Flutter iOS

Job macOS riêng cài dependency theo lockfile và chạy
`flutter build ios --simulator --no-codesign`. Gate này phát hiện lỗi compile,
plugin/CocoaPods và cấu hình iOS mà Windows không thể kiểm chứng. Simulator build
không thay thế archive thiết bị, signing, TestFlight hoặc kiểm thử permission trên
iPhone/iPad thật.

## 4. Hợp đồng deploy Supabase

Hai workflow deploy sử dụng Supabase CLI đã pin phiên bản và thực hiện theo thứ
tự:

1. Link đúng project từ GitHub Environment.
2. `supabase db push` để áp dụng migration còn thiếu.
3. Deploy toàn bộ Edge Functions bằng server-side bundling.
4. In migration state vào log để đối chiếu.

Database migration chạy trước Edge Function để code mới không truy cập schema
chưa tồn tại. Thay đổi phá vỡ phải dùng expand -> migrate -> contract; không dựa
vào rollback tự động sau khi DDL đã chạy.

## 5. Authentication, authorization và privacy

- CI không có quyền Supabase và phải chạy được với source công khai cho runner.
- Credential chỉ nằm trong GitHub Environment `development` hoặc `production`.
- Database password được Supabase CLI đọc từ environment variable đã mask, không
  được lặp lại dưới dạng tham số dòng lệnh hoặc in ra log.
- Environment Production phải có required reviewer và hạn chế deployment từ
  nhánh/tag được bảo vệ.
- Không đưa `MUSEMEND_CLEANUP_SECRET`, service-role key, database password, access
  token, signing key hoặc nội dung dữ liệu người dùng vào log/artifact.
- Supabase access token dùng cho CI/CD phải thuộc tài khoản kỹ thuật có MFA, được
  rotate định kỳ và thu hồi ngay khi nghi ngờ lộ.

## 6. Kiểm thử và tiêu chí nghiệm thu

Trước khi bắt buộc workflow bằng branch protection:

1. Mở pull request thử và xác nhận mọi job không-secret chạy được.
2. Thử thay đổi code mà không cập nhật docs; job policy phải thất bại.
3. Merge một thay đổi an toàn vào `develop`; chỉ project Dev được cập nhật.
4. Chạy production với tag không thuộc `main`; preflight phải từ chối.
5. Chạy tag hợp lệ; job production phải đứng chờ reviewer trước khi đọc secret.
6. Sau deploy, đối chiếu migration list và smoke-test RPC/Edge Function trên đúng
   môi trường, không sử dụng dữ liệu người dùng thật cho test.

## 7. Khả năng tương thích và rollback

- Flutter cũ phải tiếp tục hoạt động trong lúc migration mới được rollout.
- Migration production không được sửa sau khi áp dụng; fix bằng migration mới.
- Edge Function nên giữ tương thích ngược ít nhất trong cửa sổ phát hành mobile.
- Nếu Edge Function lỗi, redeploy artifact từ tag tốt gần nhất.
- Nếu migration gây lỗi, dừng rollout, vô hiệu hóa code path mới và áp dụng
  forward-fix. Chỉ phục hồi backup khi có đánh giá mất dữ liệu và runbook cụ thể.

## 8. Phụ thuộc, giới hạn và việc còn lại

- Cần cấu hình GitHub Environments theo
  [github-environments.md](./github-environments.md).
- Cần bật branch protection và chọn các job CI làm required checks.
- Cần thêm test Edge Function hành vi, không chỉ lint/type-check.
- Cần thay validator nhúng hoặc bổ sung Supabase local stack để kiểm tra cron,
  extensions và hành vi sát hosted Postgres hơn trước production.
- Cần thiết kế pipeline signing/phát hành mobile sau khi chốt Android/iOS.
- Cần bổ sung archive iOS đã ký và phân phối TestFlight sau khi có Apple credential.

## 9. Tài liệu liên quan

- [Quy ước chung](../README.md)
- [Cấu hình GitHub Environments](./github-environments.md)
- [Runbook phát hành](./release-runbook.md)
- [Database](../db/README.md)
- [Backend](../be/README.md)
- [Frontend](../fe/README.md)
