# Android QA release 1.5

- **Trạng thái:** `in-progress`
- **Cập nhật:** 2026-09-07

## Mục tiêu

Phát hành bản Android QA `1.5.0+2` từ nhánh `develop`, đồng thời đưa migration
`20260907150000_journal_media_transforms` lên Supabase Development. Bản này làm
cho vị trí, kích thước và góc xoay của ảnh trong nhật ký/thư được lưu lâu dài và
khôi phục khi mở lại thư.

## Luồng triển khai

1. PR feature vào `develop` phải đạt CI, gồm Flutter analyze/test, build Android,
   replay migration và integration test RLS/RPC.
2. Sau khi merge vào `develop`, workflow `Deploy Supabase Development` chạy từ
   đúng SHA CI đã xác minh, gọi `supabase db push --linked --yes`, rồi deploy
   Edge Functions.
3. Khi CI của `develop` thành công, `Distribute Android QA Release` build APK
   release có chữ ký, đọc version `1.5.0+2` và tạo GitHub prerelease dạng
   `qa-v1.5.0-2-<commit-sha>`.
4. QA tải APK, kiểm tra SHA-256 và xác minh ảnh vẫn giữ transform sau khi đóng
   rồi mở lại nhật ký.

## Thay đổi và tương thích

- Flutter gọi `update_journal_media_transform()` sau mỗi gesture kết thúc.
- Migration mở rộng `journal_media` bằng metadata transform và giới hạn phạm vi
  giá trị; object ảnh trong Storage không bị sửa hoặc crop.
- Client có fallback đọc ba cột media cũ trong lúc migration rollout; thao tác
  lưu transform chỉ được coi là thành công sau khi migration đã deploy.
- Build number `2` lớn hơn bản QA `0.1.0+1`, nên có thể cài đè trên Android mà
  không đổi package ID `com.musemend.app` hoặc upload key.

## Kiểm thử nghiệm thu

- `flutter analyze --fatal-infos --no-pub` không có lỗi.
- `flutter test --no-pub` đạt toàn bộ test hiện có.
- `node tools/db-validation/validate.mjs` replay toàn bộ migration và integration
  test thành công.
- Hai tài khoản thử nghiệm: chỉ chủ sở hữu sửa được transform; user khác bị từ
  chối bởi RPC.

## Rollback và giới hạn

Không sửa hoặc xóa migration đã chạy. Nếu cần dừng rollout, phát hành app cũ
vẫn đọc được media với transform mặc định và tạo migration forward-fix nếu phát
sinh lỗi. Đây là GitHub prerelease cho Supabase Development, chưa phải
production/store release; iOS vẫn chưa nằm trong bản này.

## Liên kết

- [Android QA Release](./android-qa-release.md)
- [CI/CD](./ci-cd.md)
- [Migrations và kiểm thử](../db/migrations-testing.md)
- [Journal editor](../fe/journal-editor.md)
