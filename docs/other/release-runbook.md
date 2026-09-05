# Runbook phát hành MuseMend

**Trạng thái:** `in-progress`  
**Cập nhật:** 2026-09-05

## 1. Mục tiêu và phạm vi

Runbook này áp dụng cho việc đưa migration và Edge Functions từ Dev sang
Production. Phát hành có ký lên Google Play/App Store Connect sẽ được bổ sung khi
module Flutter và credential store được thiết lập.

## 2. Điều kiện trước phát hành

- PR đã merge theo `feature/* -> develop`; CI và code review đều đạt.
- Supabase Dev đã deploy thành công và QA không còn lỗi chặn phát hành.
- Migration/Edge Function mới đã được smoke-test bằng tài khoản thử, gồm kiểm tra
  phân tách A/B nếu đụng authentication, RLS hoặc dữ liệu riêng tư.
- Tài liệu FE/BE/DB/Other phản ánh đúng implementation.
- Đã đánh giá tương thích app cũ, expand/migrate/contract và forward-fix.
- Supabase Production có backup/PITR phù hợp với mức rủi ro của thay đổi.
- GitHub Environment `production` đã có required reviewer và đúng secret/variable.

## 3. Chuẩn bị release

1. Tạo `release/<version>` từ `develop` nếu cần giai đoạn ổn định.
2. Chỉ nhận bug fix, tài liệu và thay đổi phát hành cần thiết trên release branch.
3. Chạy regression test; mọi fix quay lại `develop` để không phân kỳ.
4. Merge release vào `main` bằng PR đã qua CI/review.
5. Tạo annotated tag SemVer, ví dụ `v0.1.0`, tại commit trên `main` và push tag.

Không di chuyển hoặc ghi đè một tag đã dùng để deploy. Nếu release sai, tạo phiên
bản mới.

## 4. Deploy Production

1. Mở GitHub Actions -> **Deploy Supabase Production** -> **Run workflow**.
2. Nhập tag release và bật xác nhận QA/rollout.
3. Chờ preflight xác nhận tag thuộc `main`, replay migration và type-check function.
4. Reviewer so sánh tag, PR, migration plan và phạm vi ảnh hưởng rồi approve
   Environment `production`.
5. Theo dõi bước database trước, Edge Functions sau; không chạy thêm một deploy
   song song.
6. Lưu liên kết workflow run vào release note/biên bản QA.

## 5. Xác minh sau deploy

- Migration list khớp repository tại tag.
- Edge Function liên quan trả mã expected cho request hợp lệ và không hợp lệ.
- Smoke-test login, RLS, RPC hoặc luồng nghiệp vụ bị ảnh hưởng bằng dữ liệu test.
- Kiểm tra log lỗi, timeout, cron và cleanup queue; không đưa PII vào biên bản.
- Chưa phát hành mobile nếu backend không còn tương thích với app đang lưu hành.

## 6. Xử lý lỗi và rollback

### Preflight hoặc approval thất bại

Không có production mutation. Sửa trên branch phù hợp, chạy lại CI/QA và tạo tag
mới nếu commit release thay đổi.

### Edge Function thất bại sau migration

Giữ schema tương thích, redeploy function từ tag tốt gần nhất hoặc phát hành
forward-fix. Xác nhận function cũ vẫn dùng được với schema mới trước khi rollback.

### Migration thất bại một phần

Dừng rollout app/function phụ thuộc schema. Thu thập lỗi đã redacted, kiểm tra
transaction boundary và tạo migration forward-fix; không sửa migration đã áp dụng
và không tự ý reset database.

### Có nguy cơ mất/lộ dữ liệu

Ngừng rollout, giới hạn truy cập, rotate credential liên quan, lưu audit evidence
và báo người phụ trách. Restore/PITR chỉ thực hiện sau khi xác định recovery point,
phạm vi dữ liệu mất và được phê duyệt.

## 7. Mobile release còn lại

Trước khi tự động hóa store release cần chốt:

- Android application ID, upload key/Play App Signing và Play service account.
- iOS bundle ID, signing certificate/profile hoặc App Store Connect API key.
- Chính sách version/build number, track TestFlight/Internal testing và rollout.
- Cách inject publishable Supabase config theo môi trường mà không đưa service role
  vào app.

Các credential signing phải nằm trong protected Environment riêng và chỉ được mở
sau approval. APK debug từ CI không được tải lên store.

## 8. Liên kết

- [CI/CD](./ci-cd.md)
- [GitHub Environments](./github-environments.md)
- [Quy ước Git và Definition of Done](../README.md)
