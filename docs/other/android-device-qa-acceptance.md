# Nghiệm thu Android MVP trên thiết bị thật

**Trạng thái:** `implemented`  
**Cập nhật:** 2026-09-06

## 1. Mục tiêu và phạm vi

Tài liệu này là biên bản kiểm thử bắt buộc cho APK Android QA được phát hành qua
GitHub Releases. Mục tiêu là xác nhận chính artifact đã ký, cấu hình Supabase
Development và các vertical slice P0 hoạt động trên thiết bị Android thật.

Checklist này không thay thế Flutter tests, database integration tests hoặc CI.
Nó bổ sung bằng chứng cho những hành vi phụ thuộc hệ điều hành như cài đặt, quyền
notification, Photo Picker, deep-link, mất mạng và cập nhật APK.

## 2. Artifact và môi trường

Trước mỗi vòng QA, ghi đầy đủ thông tin sau. Không ghi publishable key, access
token, mật khẩu, nội dung nhật ký riêng tư hoặc thông tin nhận dạng thật.

| Trường | Giá trị |
| --- | --- |
| Release URL | |
| Release tag | |
| Commit SHA | |
| SHA-256 đã đối chiếu | `PASS` / `FAIL` |
| Thiết bị và phiên bản Android | |
| Người kiểm thử | |
| Thời gian bắt đầu/kết thúc | |
| Tài khoản thử A/B | Chỉ ghi mã giả, không ghi email/mật khẩu |

APK phải đến từ GitHub prerelease của repository. Trên Windows, đối chiếu digest
trong file `.sha256` với kết quả:

```powershell
Get-FileHash .\musemend-qa-*.apk -Algorithm SHA256
```

Không tiếp tục cài nếu checksum không khớp. Thiết bị chỉ được dùng tài khoản thử
và dữ liệu giả trên Supabase Development.

## 3. Quy tắc ghi kết quả

Mỗi test case nhận một trong bốn trạng thái:

- `PASS`: kết quả thực tế đúng toàn bộ mong đợi và có bằng chứng.
- `FAIL`: sai hành vi, crash, treo hoặc lộ dữ liệu/lỗi nội bộ.
- `BLOCKED`: không thể chạy vì thiếu điều kiện; phải ghi lý do.
- `N/A`: chỉ dùng khi test không thuộc vòng hiện tại và đã được người phụ trách
  chấp nhận rõ ràng.

Với `FAIL` hoặc `BLOCKED`, ghi model thiết bị, phiên bản Android, bước tái hiện,
thời điểm, ảnh/video không chứa dữ liệu nhạy cảm và liên kết issue/PR sửa lỗi.

## 4. Checklist cài đặt và cấu hình

| ID | Bước kiểm thử | Kết quả mong đợi | Kết quả |
| --- | --- | --- | --- |
| APK-01 | Đối chiếu SHA-256 rồi cài APK mới | Checksum khớp; package `com.musemend.app` cài thành công | |
| APK-02 | Mở app sau fresh install | Không crash; hiển thị màn đăng nhập | |
| ENV-01 | Đăng nhập bằng tài khoản QA | App kết nối Supabase Development và không hiện lỗi cấu hình | |
| SEC-01 | Quan sát log/UI khi có lỗi | Không lộ token, SQL, stack trace, secret hoặc nội dung user khác | |

## 5. Checklist chức năng P0

| ID | Bước kiểm thử | Kết quả mong đợi | Kết quả |
| --- | --- | --- | --- |
| AUTH-01 | Đăng ký tài khoản thử mới | Tạo session; profile/settings/travel progress được bootstrap | |
| AUTH-02 | Đóng hẳn rồi mở app | Session được phục hồi; không yêu cầu đăng nhập lại khi token còn hạn | |
| AUTH-03 | Đăng xuất rồi mở lại app | Trở về đăng nhập; dữ liệu riêng không còn hiển thị | |
| CHK-01 | Check-in mood và ghi chú | Tạo đúng một check-in của ngày Việt Nam | |
| CHK-02 | Sửa check-in trong cùng ngày | Cập nhật cùng bản ghi; không tạo dòng thứ hai | |
| CHK-03 | Đóng/mở app nhiều lần | App-open không bị nhân đôi; streak không cộng sai | |
| MIS-01 | Tạo và hoàn thành nhiệm vụ tự tạo | Nhận đúng 5 năng lượng | |
| MIS-02 | Thử hoàn thành lại hoặc retry | Không cộng năng lượng/phần thưởng lần hai | |
| MIS-03 | Bỏ qua/cập nhật nhiệm vụ | Trạng thái đúng và chỉ thay đổi qua thao tác hợp lệ | |
| JNY-01 | Khởi hành và tiến tới checkpoint | Trừ/ghi nhận năng lượng đúng; checkpoint thuộc tỉnh hiện tại | |
| JNY-02 | Nhận reward checkpoint | Food/item/landmark mở đúng một lần và xuất hiện trong Library | |
| JRN-01 | Tạo, sửa rồi tải lại daily journal | Nội dung và subtype nhất quán; không mất dữ liệu | |
| JRN-02 | Tạo hai tag, gắn rồi mở lại journal | Tag được lưu/hiển thị đúng, không nhân đôi assignment | |
| JRN-03 | Xóa mềm journal | Journal biến mất khỏi danh sách và không mở lại qua deep-link | |
| MED-01 | Chọn ảnh bằng Photo Picker và upload | Preview tải được qua signed URL; draft không mất nếu upload retry | |
| MED-02 | Dùng tài khoản B thử truy cập media của A | Không đọc được metadata hoặc object của A | |
| FUT-01 | Tạo/sửa thư tương lai rồi mở sớm | Nội dung lưu đúng; lịch nhắc được reschedule/cancel đúng | |
| NOT-01 | Cho phép notification và đặt thư đến hạn gần | Notification xuất hiện; chạm vào mở đúng journal | |
| NOT-02 | Từ chối notification rồi tạo thư | App không crash; thư vẫn xuất hiện trong inbox khi đến hạn | |
| PRF-01 | Sửa profile/theme/sound/notification | Chỉ các trường được phép thay đổi và còn đúng sau mở lại app | |
| ISO-01 | Dùng tài khoản A/B đọc và sửa dữ liệu | A không xem/sửa journal, mission, progress, notification, media của B | |

## 6. Mạng, lỗi và khả năng truy cập

| ID | Bước kiểm thử | Kết quả mong đợi | Kết quả |
| --- | --- | --- | --- |
| NET-01 | Tắt mạng tại Reflect rồi chờ timeout | Có trạng thái lỗi an toàn và nút thử lại; không treo vô hạn | |
| NET-02 | Bật mạng và chọn thử lại | Dữ liệu tải lại được; không tạo tác vụ hoặc reward trùng | |
| UI-01 | Font hệ thống 200% trên màn nhỏ | Nội dung chính vẫn đọc/thao tác được, không overflow nghiêm trọng | |
| A11Y-01 | Duyệt luồng chính bằng TalkBack | Nút/trường có nhãn và thứ tự focus sử dụng được | |
| RES-01 | Đưa app background rồi quay lại ở thao tác đang chờ | Không crash; trạng thái không bị ghi hai lần | |

## 7. Cập nhật và xóa tài khoản

| ID | Bước kiểm thử | Kết quả mong đợi | Kết quả |
| --- | --- | --- | --- |
| UPD-01 | Cài APK có version code cao hơn lên trên bản trước | Cập nhật thành công, session và dữ liệu server được giữ | |
| DEL-01 | Trên tài khoản dùng một lần, nhập chuỗi xác nhận xóa | Request idempotent; tài khoản bị khóa nghiệp vụ và app sign-out | |
| DEL-02 | Chạy/quan sát cleanup sau retention | Auth, DB và Storage được xóa idempotent; retry không gây lỗi/lộ dữ liệu | |

Không chạy `DEL-01` trên tài khoản demo dùng chung. `DEL-02` cần biên bản vận hành
riêng và bằng chứng từ worker; chưa được dùng transaction rollback thay cho kiểm
thử cleanup thật khi đánh giá khả năng phát hành công khai.

## 8. Tiêu chí pass và xử lý lỗi

Bản Android internal MVP được nghiệm thu khi:

1. Tất cả case `APK`, `ENV`, `SEC`, `AUTH`, `CHK`, `MIS`, `JNY`, `JRN`, `MED`,
   `FUT`, `NOT`, `PRF`, `ISO` và `NET` đều `PASS` trên ít nhất một thiết bị thật.
2. Không còn lỗi crash, mất dữ liệu, cộng thưởng hai lần hoặc truy cập chéo user.
3. `UI-01` và `A11Y-01` không có lỗi chặn thao tác chính.
4. CI của đúng commit Release xanh và Supabase Development deploy thành công.
5. Mọi lỗi đã có issue/PR và bản sửa được kiểm thử lại bằng một Release mới.

`UPD-01` cần hai version code khác nhau nên được hoàn tất từ Release QA thứ hai.
`DEL-02`, iOS device và các yêu cầu pháp lý vẫn là gate riêng trước public release.

## 9. Rollback và dữ liệu thử

Nếu có lỗi blocker, dừng chuyển APK cho tester khác, đánh dấu prerelease bị lỗi
trong release notes và sửa trên nhánh `fix/*` từ `develop`. Không thay thế asset
của tag cũ; tăng build number, chạy lại CI và tạo Release mới để giữ audit trail.

Dữ liệu kiểm thử phải có thể xóa, không chứa nhật ký/ảnh thật và không được sao
chép sang Production. Không chụp màn hình email, token hoặc dữ liệu riêng tư của
người khác làm bằng chứng.

## 10. Liên quan

- [Android QA Release](./android-qa-release.md)
- [Ma trận QA MVP](./mvp-qa.md)
- [Roadmap MVP](./mvp-roadmap.md)
- [Privacy và safety](./privacy-safety.md)
- [Runbook phát hành](./release-runbook.md)
