# MuseMend — Quy ước phát triển và tài liệu

Tài liệu này là quy ước bắt buộc đối với mọi developer và coding agent làm việc
trong repository MuseMend. Trước khi sửa code, schema, hạ tầng hoặc quy trình,
phải đọc file này và tài liệu liên quan trong `docs/fe/`, `docs/be/`,
`docs/db/` và `docs/other/`.

Các từ **PHẢI**, **KHÔNG ĐƯỢC**, **NÊN** trong tài liệu này mang tính quy phạm.
Nếu yêu cầu mới xung đột với tài liệu hiện có, không âm thầm chọn một phía:
phải ghi rõ xung đột, thống nhất quyết định, rồi cập nhật tài liệu cùng thay đổi.

## 1. Mục tiêu kiến trúc MVP

MuseMend là ứng dụng Flutter chạy trên Android/iOS. Backend MVP sử dụng Supabase:

- Supabase Auth cho danh tính và phiên đăng nhập.
- PostgreSQL cho dữ liệu nghiệp vụ.
- Row Level Security (RLS) để phân tách dữ liệu người dùng.
- Database RPC cho các thao tác nghiệp vụ cần transaction hoặc quyền đặc biệt.
- Supabase Storage cho tệp nhật ký riêng tư.
- Edge Functions cho tác vụ cần service role hoặc tích hợp dịch vụ ngoài.
- Cron/Vault cho tác vụ nền và quản lý secret.

MVP ưu tiên đọc/ghi trực tiếp Supabase qua SDK, nhưng code phải được tổ chức để
có thể chuyển sang local-first và đồng bộ sau này. UI không được phụ thuộc trực
tiếp vào cấu trúc response của Supabase; mọi truy cập dữ liệu đi qua repository
và model/domain rõ ràng.

Luồng phụ thuộc mong muốn:

```text
Presentation/UI
    ↓
Application/Use cases
    ↓
Domain interfaces
    ↓
Data repositories
    ↓
Supabase SDK / local database / platform services
```

Không import ngược từ tầng thấp lên tầng cao và không đặt nghiệp vụ quan trọng
trong widget, controller giao diện hoặc callback trực tiếp của SDK.

## 2. Phân chia module

### Frontend — `app/` hoặc thư mục Flutter được chốt khi khởi tạo

Tổ chức theo feature, sau đó chia lớp bên trong feature:

```text
lib/
  app/                 # bootstrap, router, theme, dependency injection
  core/                # thành phần dùng chung, không chứa nghiệp vụ feature
  features/
    auth/
      data/
      domain/
      presentation/
    checkin/
    missions/
    journey/
    journals/
    notifications/
    settings/
```

- Một feature không được đọc thẳng implementation nội bộ của feature khác.
- Thành phần dùng chung chỉ chuyển vào `core/` khi thực sự được dùng nhiều nơi.
- DTO Supabase tách khỏi domain model và UI model.
- Mọi trạng thái loading, empty, retry, lỗi mạng và hết phiên phải được xử lý.
- Chuỗi hiển thị không hard-code rải rác; chuẩn bị cấu trúc cho localization.
- Logic theo ngày phải dùng quy tắc múi giờ Việt Nam đã thống nhất với DB.

### Backend — `supabase/functions/<function-name>/`

Backend trong MVP là Edge Functions và tích hợp ngoài, không phải một server
Docker riêng nếu chưa có quyết định kiến trúc mới.

- Mỗi function có một trách nhiệm rõ ràng và entrypoint nhỏ.
- Tách validation, nghiệp vụ và adapter dịch vụ khi function trở nên phức tạp.
- Validate method, payload, kích thước dữ liệu và authentication trước xử lý.
- Không tin `user_id`, mức thưởng, quyền hoặc đường dẫn do client tự khai báo.
- Thao tác dữ liệu nhiều bước cần tính nguyên tử phải gọi RPC transaction trong DB.
- Log có ngữ cảnh nhưng không chứa token, secret, nội dung nhật ký hoặc PII.
- Tích hợp ngoài phải có timeout, xử lý lỗi và chiến lược retry/idempotency.

### Database — `supabase/migrations/`, `supabase/tests/`

- Mọi thay đổi schema, RLS, function, trigger, index hoặc cron **PHẢI** là migration.
- Không sửa production bằng Dashboard rồi bỏ qua migration.
- Migration đã chạy ở môi trường dùng chung không được sửa nội dung; tạo migration mới.
- Bảng và cột dùng `snake_case`; khóa chính/ngoại, constraint và index phải rõ ràng.
- Foreign key không thay thế được kiểm tra nghiệp vụ liên người dùng.
- Bảng chứa dữ liệu người dùng phải bật RLS và có policy tối thiểu cần thiết.
- Nghiệp vụ thưởng, năng lượng, tiến độ và mở khóa phải đi qua RPC phía server.
- RPC `security definer` phải cố định `search_path`, kiểm tra `auth.uid()` và
  thu hồi quyền execute mặc định trước khi cấp quyền cụ thể.
- Secret chỉ ở Supabase Secrets/Vault hoặc secret store của CI; không nằm trong SQL.
- Migration phải có kiểm thử replay cục bộ và integration test phù hợp.
- Seed catalog phải xác định được, có thể chạy lại an toàn và không chứa dữ liệu thật.

### Other — hạ tầng và quyết định liên miền

CI/CD, monitoring, threat model, ADR, release checklist và tài liệu vận hành đặt
trong `docs/other/`. Script hỗ trợ đặt trong thư mục công cụ phù hợp, không trộn
với source của app hoặc migration.

## 3. Git workflow

Nhánh:

- `main`: trạng thái production hoặc sẵn sàng phát hành; được bảo vệ.
- `develop`: bản tích hợp đã qua CI, dùng với Supabase Dev.
- `feature/<ten-ngan>`: tính năng mới, tạo từ `develop`.
- `fix/<ten-ngan>`: sửa lỗi chưa phát hành, tạo từ `develop`.
- `hotfix/<ten-ngan>`: lỗi production khẩn cấp, tạo từ `main`, sau đó đồng bộ
  lại cả `main` và `develop`.
- `release/<version>`: ổn định hóa bản phát hành khi dự án cần quy trình release.

Quy tắc:

- Không commit trực tiếp vào `main` hoặc `develop`.
- Một pull request chỉ nên có một mục tiêu nghiệp vụ rõ ràng.
- Không trộn refactor diện rộng với tính năng nếu không cần thiết.
- Không commit secret, file `.env`, token, signing key hoặc dữ liệu người dùng thật.
- Không force-push nhánh dùng chung và không rewrite lịch sử đã chia sẻ.
- Không dùng thao tác phá hủy như reset/checkout để làm mất thay đổi chưa xác minh.
- Commit phải nhỏ, có nghĩa, build được; thông điệp nên theo Conventional Commits,
  ví dụ `feat(journals): add future letter editor`.
- PR phải mô tả phạm vi, ảnh hưởng DB, cách kiểm thử, thay đổi bảo mật và tài liệu.
- Merge khi CI xanh và đã được review; ưu tiên squash merge cho feature PR.

## 4. CI/CD

Luồng phát triển:

```text
feature/* hoặc fix/*
    → Pull Request
    → CI
    → Code Review
    → develop
    → Supabase Dev + bản Flutter test
    → QA
```

Luồng phát hành:

```text
develop → release/* → kiểm thử hồi quy → main + tag
    ├─ migration + Edge Functions → Supabase Production (có phê duyệt)
    ├─ AAB → Google Play
    └─ iOS archive/IPA → App Store Connect
```

CI cho pull request tối thiểu phải:

- kiểm tra format và static analysis;
- chạy unit/widget tests của Flutter;
- kiểm tra build Android tối thiểu;
- replay/validate migrations trên DB sạch;
- chạy integration test cho RPC và RLS;
- quét secret và dependency có lỗ hổng nghiêm trọng;
- xác nhận tài liệu bắt buộc đã được cập nhật.

Pipeline `develop` triển khai vào Supabase Dev và tạo artifact cho tester. Production
phải có bước phê duyệt thủ công cho migration, Edge Functions và phát hành store.
Không dùng chung project, key, dữ liệu hoặc Storage giữa Dev và Production.

Migration production phải chạy trước code phụ thuộc schema mới nếu code không tương
thích ngược. Thay đổi phá vỡ dùng chiến lược expand → migrate → contract.

## 5. Bảo mật bắt buộc

- Client chỉ dùng publishable/anon key; service-role key không bao giờ nằm trong app.
- Mọi bảng user-owned bật RLS; policy phải kiểm tra chủ sở hữu bằng `auth.uid()`.
- Không coi ẩn nút trên UI là phân quyền.
- Mức thưởng, năng lượng, unlock và tiến độ được xác định phía server.
- RPC nhận yêu cầu, không nhận kết quả đáng tin từ client; phải chống gọi lặp.
- Dùng constraint, transaction và row lock phù hợp để tránh race condition.
- Storage mặc định private; đường dẫn phải gắn với user/journal và có policy sở hữu.
- Validate MIME type, kích thước, tên/đường dẫn file; không tin extension của file.
- Secret dùng Supabase Secrets, Vault hoặc CI secret store và phải có kế hoạch rotate.
- Không log access token, refresh token, secret, nội dung nhật ký, mood chi tiết hay PII.
- Dữ liệu nhập từ người dùng phải được validate; tránh SQL động và injection.
- Dependency phải được pin/lock, cập nhật có kiểm soát và theo dõi advisory.
- Lỗi trả về client không để lộ stack trace, SQL, schema nội bộ hoặc credential.
- Chức năng xóa tài khoản phải xử lý Auth, DB và Storage; tác vụ nền phải idempotent.
- Kiểm thử bảo mật tối thiểu bằng hai tài khoản: A không đọc/sửa dữ liệu của B.
- Mọi thay đổi authentication, authorization, RLS, upload hoặc external webhook phải
  có threat review ngắn trong tài liệu/PR.

Nếu phát hiện secret đã commit, không chỉ xóa file: phải rotate/revoke secret và
kiểm tra lịch sử Git, log CI cùng phạm vi ảnh hưởng.

## 6. Quy tắc tài liệu bắt buộc

Tài liệu là một phần của Definition of Done. Mọi thay đổi đáng kể phải cập nhật
hoặc tạo file Markdown trong đúng miền:

- `docs/fe/`: màn hình, state, navigation, model, repository, platform integration.
- `docs/be/`: Edge Function, API contract, auth, retry, integration và vận hành.
- `docs/db/`: schema, quan hệ, RLS, RPC, migration, seed và quy tắc dữ liệu.
- `docs/other/`: CI/CD, ADR, security, release, monitoring và quyết định liên miền.

Không gom mọi thứ vào một file dài. Mỗi feature/component nên có một file riêng,
đặt tên `kebab-case.md`, và được liên kết từ README của thư mục tương ứng.

Mỗi tài liệu chi tiết tối thiểu phải có:

1. Mục tiêu và phạm vi.
2. Trạng thái: proposed, in-progress, implemented, deprecated.
3. Thiết kế/luồng xử lý và trách nhiệm từng module.
4. Interface hoặc API/RPC/schema liên quan.
5. Quy tắc dữ liệu, validation và trường hợp lỗi.
6. Authentication, authorization, privacy và rủi ro bảo mật.
7. Cách kiểm thử và tiêu chí nghiệm thu.
8. Migration/khả năng tương thích và rollback nếu có.
9. Phụ thuộc, giới hạn và việc còn lại.
10. Ngày cập nhật và liên kết tới tài liệu liên quan.

Khi code thay đổi hành vi, tài liệu phải thay đổi trong cùng PR. Không ghi tài liệu
như thể tính năng đã hoàn thành nếu code chưa tồn tại; trạng thái phải phản ánh đúng.

## 7. Definition of Done

Một công việc chỉ hoàn thành khi:

- đúng phạm vi và kiến trúc module;
- không làm lộ secret hay mở rộng quyền ngoài nhu cầu;
- format, analysis, build và tests liên quan đều đạt;
- migration/RLS/RPC được kiểm thử nếu có thay đổi DB;
- trạng thái lỗi, retry và observability cần thiết đã có;
- tài liệu đúng miền đã được tạo/cập nhật;
- CI xanh và code review hoàn tất;
- có kế hoạch rollout/rollback cho thay đổi rủi ro.

## 8. Chỉ mục tài liệu

- [Frontend](./fe/README.md)
- [Backend](./be/README.md)
- [Database](./db/README.md)
- [Other / Architecture & Operations](./other/README.md)
- [Ý tưởng sản phẩm ban đầu](./MuseMend.md)
- [Thiết kế bổ sung](./MuseMend2.md)

Các tài liệu ý tưởng có thể còn rời rạc hoặc mâu thuẫn. Khi triển khai, ghi quyết
định đã chốt thành tài liệu chi tiết/ADR thay vì âm thầm suy luận từ bản ý tưởng.
