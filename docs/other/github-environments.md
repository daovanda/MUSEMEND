# Cấu hình GitHub Environments

**Trạng thái:** `proposed` — workflow đã tham chiếu environment nhưng cấu hình
GitHub phải do repository owner thực hiện.  
**Cập nhật:** 2026-09-06

## 1. Mục tiêu và phạm vi

Tách credential Supabase Development và Production, đồng thời đặt cổng phê duyệt
trước production. Không dùng chung Supabase project, database password, access
token, Storage hoặc dữ liệu giữa hai môi trường.

## 2. Tạo environments

Trong GitHub repository, mở **Settings -> Environments** và tạo chính xác:

- `development`
- `android-development`
- `production`

Trong mỗi environment, tạo:

| Loại | Tên | Nội dung |
| --- | --- | --- |
| Variable | `SUPABASE_PROJECT_REF` | Project ref của đúng môi trường |
| Secret | `SUPABASE_ACCESS_TOKEN` | Access token dùng bởi Supabase CLI |
| Secret | `SUPABASE_DB_PASSWORD` | Database password của đúng project |

Không thêm service-role key hoặc `MUSEMEND_CLEANUP_SECRET`: workflow deploy không
cần đọc hai giá trị này. Edge Function secret/Vault phải được provision trực tiếp
trong từng Supabase project bằng quy trình quản trị secret riêng.

Ngoài Environment variables dành cho deploy, repository cần hai Actions variables
không đặc quyền để build ứng dụng Development:

| Loại | Tên | Nội dung |
| --- | --- | --- |
| Repository variable | `SUPABASE_URL` | URL HTTPS của Supabase Development |
| Repository variable | `SUPABASE_PUBLISHABLE_KEY` | Publishable key dành cho mobile client |

Không thay publishable key bằng secret/service-role key. Hai biến repository được
CI truyền vào Android và iOS bằng `--dart-define`; chúng không cấp quyền vượt RLS.

`android-development` không cần Supabase deploy credential. Nó chỉ chứa signing
upload key và Play service account theo [Android Internal Testing](./android-internal-testing.md).

## 3. Protection rules

`development`:

- Chỉ cho phép branch `develop` deploy.
- Không bắt buộc approval nếu nhóm nhỏ, nhưng phải giữ CI và review bắt buộc trước
  merge `develop`.

`production`:

- Bắt buộc ít nhất một required reviewer.
- Bật **Prevent self-review** khi có từ hai maintainer.
- Chỉ cho phép protected branch/tag; tag phát hành theo `v*`.
- Không cho administrator bypass nếu chính sách GitHub hiện tại hỗ trợ.

Environment secret chỉ được giải mã sau khi protection rule hoàn tất. Việc ghi
`environment: production` trong YAML không tự tạo required reviewer; repository
owner phải cấu hình các rule trên giao diện GitHub.

## 4. Phân quyền và quản lý secret

- Token thuộc tài khoản kỹ thuật có MFA, chỉ cấp quyền project cần deploy.
- Không dùng personal token của developer lâu dài cho production.
- Rotate access token và database password định kỳ, khi người quản trị rời nhóm,
  hoặc ngay khi phát hiện log/history đáng ngờ.
- Không chụp màn hình, copy vào issue/PR hoặc dùng `echo` để kiểm tra giá trị.
- Review định kỳ danh sách người có quyền sửa workflow, environment và branch
  protection vì họ có thể thay đổi đường đi tới secret.

## 5. Kiểm thử và tiêu chí nghiệm thu

- Workflow Dev fail với thông báo tên biến thiếu, không in giá trị.
- Project ref Development và Production khác nhau.
- Một production run hợp lệ ở trạng thái chờ approval trước bước checkout deploy.
- Người khởi tạo không thể tự duyệt khi `Prevent self-review` được bật.
- Từ chối production run không làm lộ environment secrets trong log.

## 6. Rollback và sự cố

Nếu nghi lộ secret: hủy workflow đang chạy, revoke/rotate tại Supabase, cập nhật
GitHub Environment, kiểm tra audit log và Git history. Chỉ xóa chuỗi khỏi file là
không đủ.

## 7. Việc còn lại và liên kết

Việc tạo environment/protection rule là thao tác ngoài Git nên tài liệu này giữ
trạng thái `proposed` cho tới khi owner xác minh cấu hình thực tế.

- [CI/CD](./ci-cd.md)
- [Runbook phát hành](./release-runbook.md)
- [Quy ước bảo mật chung](../README.md#5-bảo-mật-bắt-buộc)
