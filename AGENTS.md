# MuseMend Agent Instructions

File này áp dụng cho toàn bộ repository. Mọi coding agent phải đọc và tuân thủ
[docs/README.md](docs/README.md) trước khi phân tích, viết hoặc sửa code.

## Bắt buộc trước khi thay đổi

1. Đọc `docs/README.md`.
2. Đọc README và các tài liệu liên quan trong miền đang làm:
   - Frontend: `docs/fe/`
   - Backend/Edge Functions: `docs/be/`
   - Database/Supabase: `docs/db/`
   - CI/CD, kiến trúc liên miền, bảo mật và vận hành: `docs/other/`
3. Kiểm tra code, migrations và tests hiện có; không suy luận chỉ từ tài liệu ý tưởng.
4. Nếu tài liệu và implementation mâu thuẫn, phải nêu rõ trước khi thay đổi hành vi.

## Quy tắc thực thi

- Tuân thủ kiến trúc module, Git workflow, CI/CD, bảo mật và Definition of Done
  trong `docs/README.md`.
- Giữ frontend, backend và database tách bạch; giao tiếp qua interface/API/RPC
  đã được tài liệu hóa.
- Không commit secret, token, file `.env`, service-role key, signing key hoặc dữ
  liệu người dùng thật.
- Mọi thay đổi database phải được thực hiện bằng migration mới và có kiểm thử phù hợp.
- Không để client tự quyết định quyền, phần thưởng, năng lượng, tiến độ hoặc unlock.
- Không sửa migration đã chạy ở môi trường dùng chung.
- Không thực hiện thao tác Git phá hủy hoặc làm mất thay đổi chưa được xác minh.
- Chỉ đánh dấu công việc hoàn thành sau khi các kiểm tra liên quan đã đạt.

## Tài liệu là một phần của thay đổi

Trong cùng thay đổi code, agent phải tạo hoặc cập nhật tài liệu chi tiết:

- `docs/fe/<feature>.md` cho Flutter/UI/state/repository/platform integration.
- `docs/be/<component>.md` cho Edge Function/API/integration/backend operation.
- `docs/db/<domain>.md` cho schema/RLS/RPC/trigger/migration/seed.
- `docs/other/<topic>.md` cho ADR/CI/CD/security/release/monitoring/runbook.

File mới dùng tên `kebab-case.md` và phải được liên kết từ README của thư mục
tương ứng. Trạng thái tài liệu phải phản ánh đúng implementation: `proposed`,
`in-progress`, `implemented` hoặc `deprecated`.

Thay đổi chỉ có code mà không cập nhật tài liệu liên quan chưa đạt Definition of Done.

## Khi thay đổi quy tắc hoặc kiến trúc

- Sửa quy tắc chung, Git workflow, CI/CD, bảo mật hoặc Definition of Done tại
  `docs/README.md`.
- Sửa kiến trúc hoặc quy ước riêng của một miền tại README tương ứng trong
  `docs/fe/`, `docs/be/`, `docs/db/` hoặc `docs/other/`.
- Ghi quyết định kiến trúc quan trọng thành ADR mới trong `docs/other/`, thay vì
  chỉ sửa mô tả và làm mất lý do của quyết định cũ.
- Chỉ sửa `AGENTS.md` khi muốn thay đổi cách agent tìm, ưu tiên hoặc bắt buộc
  tuân thủ các hướng dẫn.
- Khi đổi đường dẫn hoặc cấu trúc tài liệu, phải cập nhật cả `AGENTS.md`,
  `docs/README.md` và các liên kết chỉ mục liên quan trong cùng commit.

## Thứ tự ưu tiên nội bộ

Khi các tài liệu trong repository mâu thuẫn, agent áp dụng thứ tự:

1. `AGENTS.md` gần file đang sửa nhất, nếu sau này có thêm file theo thư mục.
2. `AGENTS.md` tại gốc repository.
3. `docs/README.md`.
4. README của miền.
5. Tài liệu feature/component và ADR đã được chấp nhận.
6. `docs/MuseMend.md` và `docs/MuseMend2.md` là tài liệu ý tưởng, không tự động
   ghi đè quyết định kỹ thuật đã được chốt.

Nếu vẫn không thể xác định lựa chọn đúng, agent phải dừng phần thay đổi có ảnh
hưởng và yêu cầu người phụ trách xác nhận.
