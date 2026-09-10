# Android QA release 1.6

- **Trạng thái:** `in-progress`
- **Cập nhật:** 2026-09-10

## Mục tiêu

Phát hành bản Android QA `1.6.0+3` từ nhánh `develop`. Bản này thống nhất ngôn
ngữ thị giác giữa Bầu trời, Auth, Nhật ký, Khám phá, Cá nhân và journal editor;
đồng thời bổ sung responsive layout cùng nền mây trắng chuyển động/parallax.

Đây là GitHub prerelease dùng Supabase Development, chưa phải production hoặc
store release. Không có migration database hay Edge Function mới trong bản này.

## Phạm vi thay đổi

- Thanh thương hiệu, badge trang và bottom navigation dùng chung, không để ink/
  hover vượt khỏi góc bo.
- Auth dùng artwork cục bộ, nền trời–kem–tím, form có tương phản ổn định và bố cục
  một/hai cột theo viewport.
- Bầu trời sửa điểm nối giữa ảnh phong cảnh và phần nhiệm vụ; ảnh luôn phủ trên
  lớp mây dùng chung.
- Nhật ký, Khám phá, Cá nhân và editor dùng gutter responsive và cùng hệ màu với
  Bầu trời.
- Frame mây trắng 2×2 tự trôi ngang liền mạch; khi cuộn, mây parallax bằng 14%
  quãng cuộn. Reduce Motion tắt toàn bộ chuyển động trang trí.

## Luồng phát hành

1. Commit thay đổi trên `feature/shared-app-chrome` và tạo PR vào `develop`.
2. Chỉ squash merge khi CI, review và các kiểm tra bắt buộc đạt.
3. CI thành công trên `develop` kích hoạt `Distribute Android QA Release`.
4. Workflow đọc `1.6.0+3`, ký APK bằng Environment `android-development`, tạo
   checksum và GitHub prerelease dạng `qa-v1.6.0-3-<commit-sha>`.
5. QA tải APK và file SHA-256, cài đè lên bản `1.5.0+2` rồi chạy checklist dưới.

## Kiểm thử và nghiệm thu

- Flutter format, `flutter analyze --fatal-infos --no-pub` và toàn bộ widget/unit
  test phải đạt trên CI.
- Kiểm tra Android build, secret scan và các DB/RLS test hiện có dù release không
  đổi schema.
- QA màn 320dp, text scale 200%, light/dark mode và Reduce Motion.
- Xác nhận ảnh phong cảnh Bầu trời không bị mây giả che; vùng không có ảnh nền
  hiển thị frame mây liên tục và không có seam khi cuộn.
- Xác nhận đăng nhập/đăng ký, bốn tab, tạo/sửa daily journal, thư tương lai và
  transform ảnh không bị regression.
- Cài APK `+3` lên trên `1.5.0+2`, xác nhận package `com.musemend.app`, session và
  dữ liệu Supabase Development được giữ nguyên.

## Bảo mật, tương thích và rollback

Thay đổi chỉ thuộc presentation và version metadata; không mở quyền, không thêm
remote asset và không thay contract Supabase. APK tiếp tục chỉ nhúng publishable
key Development; signing secret không nằm trong repository.

Nếu có lỗi chặn QA, đánh dấu prerelease không dùng, sửa bằng nhánh `fix/*` từ
`develop` và phát hành build number mới. Không ghi đè tag hoặc asset đã phát hành.

## Liên kết

- [Android QA Release](./android-qa-release.md)
- [Runbook phát hành](./release-runbook.md)
- [MuseMend UI system](../fe/ui-system.md)
- [Màn Bầu trời](../fe/sky-screen.md)
- [Journal editor](../fe/journal-editor.md)
