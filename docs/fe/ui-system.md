# MuseMend UI system

- **Trạng thái:** `in-progress`
- **Cập nhật:** 2026-09-10

## Mục tiêu và phạm vi

Thiết lập một ngôn ngữ thị giác chung cho Auth, Bầu trời, Nhật ký, Khám phá và
Cá nhân. Hệ thống kế thừa cảm giác pastel, gradient nhẹ, bề mặt kính
mờ, bo góc lớn và chuyển động ngắn của màn Bầu trời; không phụ thuộc vào Figma
đã bị loại khỏi phạm vi sản phẩm.

## Implementation

Token màu nằm ở `lib/app/theme/` (`MuseColors`, `buildMuseTheme`). Primitive dùng
chung nằm tại `lib/core/presentation/muse_ui.dart`:

- `MusePageBackground`: nền gradient theo page/accent, có dark-mode fallback và
  ba lớp mây mềm chuyển động phía sau nội dung.
- `MuseTopBar`: thanh thương hiệu dùng chung ở đầu các tab chính, gồm biểu tượng
  mây, chữ MuseMend gradient và vùng trạng thái tùy chọn.
- `MusePageTagline`: câu dẫn ngắn căn giữa dưới thanh thương hiệu; các tab không
  lặp lại icon và tiêu đề lớn của chính tab. Câu dẫn được đặt trong dấu ngoặc
  kép kiểu chữ để tạo cảm giác như một lời nhắn dịu dàng.
- `MusePageBadge`: badge kính dạng viên thuốc ở bên phải `MuseTopBar`, dùng để
  ghi tên Nhật ký, Khám phá hoặc Cá nhân theo cùng hình thức với badge trạng thái
  năng lượng/streak của Bầu trời.
- `MuseResponsiveList`: list trang dùng gutter 14/20/24dp theo chiều rộng và tự
  tăng gutter để giới hạn vùng nội dung ở 720dp trên tablet/web.
- `MuseContentFrame`: căn giữa và giới hạn những section nằm trong một page nền
  tràn cạnh, như hành trình và nhiệm vụ của Bầu trời.
- `MusePageHeader`: icon, tiêu đề và mô tả thống nhất.
- `MuseGlassCard`: surface bán trong suốt, blur, border và shadow nhẹ.
- `MuseSectionLabel` và `MusePill`: nhãn nhóm và hành động nhỏ.

Feature chỉ cung cấp nội dung/state/callback; primitive không gọi Supabase. Bốn
tab Bầu trời, Nhật ký, Khám phá và Cá nhân dùng cùng `MuseTopBar`; Bầu trời truyền
thêm trạng thái năng lượng/streak qua slot `trailing`. Auth, Library và Profile
đã dùng nền/header/card mới. Mission custom dùng modal sheet riêng, giữ toàn bộ
validation và RPC cũ.

Nhật ký, Khám phá và Cá nhân chỉ hiển thị câu dẫn căn giữa ngay dưới
`MuseTopBar`, không lặp lại tên tab trong một header lớn. Nhật ký editor dùng cùng
gutter responsive nhưng giữ trải nghiệm viết toàn trang. Các action check-in ở
màn Bầu trời dùng flex thay vì chiều rộng cố định để không overflow trên máy hẹp.

Thanh điều hướng dưới đặt surface và hiệu ứng nhấn bên trong cùng một
`ClipRRect`. Border, splash và highlight vì vậy không thể vẽ ra ngoài hai góc bo
phía trên; shadow vẫn được vẽ bởi lớp ngoài clip.

## Motion và accessibility

Button/surface dùng Material ink và animation 140–180ms. Không dùng animation làm
tín hiệu duy nhất; vùng chạm vẫn tối thiểu 48dp. Nền và card giữ contrast với
text token, hỗ trợ dark mode và text scale. Artwork trang trí không được chứa dữ
liệu người dùng.

Nền Bầu trời, Nhật ký, Khám phá, Cá nhân và journal editor dùng chung chu kỳ mây
18 giây. Ở Bầu trời, ảnh `SkyScene` nằm trên frame mây; hiệu ứng chỉ lộ ra ở các
phần không được ảnh phong cảnh phủ.
Ba cụm mây trắng code-native dùng đúng một fill và một bóng xanh rất nhạt; thân
mây không đổi màu theo accent của trang. Một frame mây được lặp thành lưới 2×2.
Frame tự trôi ngang tuyến tính đúng một chiều rộng rồi nối vào bản sao kế tiếp,
vì vậy không có khoảng trống hoặc điểm đảo chiều. Khi nội dung cuộn dọc, lưới mây
dịch 14% quãng cuộn và lặp sau mỗi chiều cao viewport để tạo parallax liền mạch.
Opacity được giảm riêng cho dark mode và mây luôn nằm sau nội dung.
`AnimationController` dừng cả tự trôi lẫn parallax khi hệ thống bật Reduce Motion;
route không hoạt động được `TickerMode` của Flutter ngắt tick.

## Bảo mật và giới hạn

Thay đổi chỉ ở presentation/theme, không mở thêm quyền Supabase, không thêm asset
remote hoặc log nội dung riêng tư. Blur là hiệu ứng hiển thị, không phải biện pháp
bảo mật; RLS/repository vẫn là lớp bảo vệ dữ liệu.

## Kiểm thử và nghiệm thu

- `flutter analyze --fatal-infos` không có issue.
- `flutter test` chạy qua toàn bộ test hiện có.
- Widget test xác nhận `MuseTopBar` luôn có thương hiệu, biểu tượng mây, chiều cao
  ổn định và render được vùng trạng thái tùy chọn.
- Test breakpoint xác nhận gutter ở 320/390/768/1200dp và render câu dẫn tại
  viewport 320×640 không phát sinh overflow.
- QA thủ công xác nhận hover/pressed trên từng tab không tạo lớp chữ nhật vượt
  khỏi vùng bo, đồng thời cả bốn tab hiển thị cùng thanh MuseMend.
- Cần kiểm tra thủ công Android/iOS ở màn hình nhỏ, text scale 200%, dark mode,
  reduce motion và contrast trước khi gọi pixel-polished.

## Việc còn lại

Golden test cho primitive, localization và các biến thể empty/error riêng từng
page sẽ bổ sung trong vòng polish tiếp theo.

Liên quan: [UI direction](./ui-design-direction.md), [Application foundation](./application-foundation.md),
[Journal editor](./journal-editor.md).
