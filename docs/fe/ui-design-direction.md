# UI/UX direction for MVP

- **Status:** in-progress
- **Last updated:** 2026-09-05
- **Source of reference:** [Figma — Nhật Ký Chữa Lành](https://www.figma.com/design/AhhlLUWAyvLVs7R5ZBVcQV/Nh%E1%BA%ADt-K%C3%BD-Ch%E1%BB%AFa-L%C3%A0nh?node-id=5-147&p=f)

## 1. Mục tiêu và phạm vi

Tài liệu này ghi lại hướng thiết kế đã quan sát từ Figma để implementation Flutter
không tự tạo một ngôn ngữ thị giác khác. Figma là nguồn tham chiếu hình ảnh; hành
vi nghiệp vụ, bảo mật và dữ liệu vẫn phải tuân theo schema/RPC cùng tài liệu kỹ thuật.

Phạm vi hiện tại là design direction cho MVP, chưa phải đặc tả pixel-perfect hoặc
cam kết rằng mọi frame trong Figma đều nằm trong P0.

## 2. Ngôn ngữ thị giác đã quan sát

- Bảng màu nhẹ, thiên về xanh da trời rất nhạt, kem, xanh bạc hà và tím pastel.
- Nền có gradient/ánh sáng mềm, tạo cảm giác yên tĩnh và không mang tính lâm sàng.
- Card lớn, bo góc mạnh, bóng và đường viền nhẹ; khoảng trắng rộng.
- Linh vật mây là điểm nhận diện trung tâm và thay đổi biểu cảm theo mood.
- Icon nét mảnh, nhãn chữ in hoa nhỏ ở navigation và nhóm lựa chọn.
- Nút chính dạng pill/rounded, màu nổi vừa phải, không dùng màu cảnh báo mạnh cho
  thao tác thông thường.
- Minh họa hành trình và vật phẩm dùng phong cách sticker mềm, đồng nhất với mây.

## 3. Information architecture

Thanh điều hướng trong Figma có bốn vùng chính:

1. **Reflect** — check-in, mood, nhiệm vụ và trạng thái hôm nay.
2. **Journal** — danh sách, tạo và xem nhật ký/thư tương lai.
3. **Library** — hành trình, passport, địa danh, món ăn và vật phẩm đã mở.
4. **Profile** — hồ sơ, cài đặt, quyền riêng tư và tài khoản.

Tên route/domain trong code không bắt buộc giống nhãn hiển thị, nhưng navigation
phải giữ bốn trách nhiệm này tách bạch. Journey là một phần trải nghiệm khám phá,
không trở thành tầng điều hướng thứ năm nếu chưa có quyết định UX mới.

## 4. Mood check-in

Figma thể hiện mood bằng card mây có minh họa, chia ít nhất hai nhóm cảm nhận:

- Tích cực: ví dụ rất cháy, yêu đời, năng suất, chữa lành, thư giãn.
- Tiêu cực/khó chịu: ví dụ trống rỗng, quạo, overthinking, áp lực, burnout.

Database hiện chỉ chấp nhận năm giá trị chuẩn:
`great`, `good`, `okay`, `sad`, `awful`. Vì vậy:

- Các nhãn cảm xúc phong phú trong UI không được gửi thẳng thành enum DB.
- Presentation có thể hiển thị nhiều sắc thái, nhưng application layer phải ánh xạ
  rõ sang một trong năm mood chuẩn và kiểm thử mapping.
- Không suy diễn hoặc hiển thị chẩn đoán sức khỏe tinh thần từ một lựa chọn mood.
- Khi chưa chốt mapping sản phẩm, P0 dùng đúng năm mức chuẩn và chọn artwork phù hợp.

## 5. Design system implementation

Không hard-code màu, radius, spacing hoặc typography trong từng màn hình. Đặt token
trong `lib/app/theme/`:

- semantic colors: background, surface, primary, secondary, success, warning, text;
- spacing scale;
- corner radius;
- elevation/shadow;
- typography roles;
- animation duration/motion curve.

Tạo component dùng chung chỉ khi có từ hai use case thực tế trở lên, ví dụ:

- `MuseCard`
- `MusePrimaryButton`
- `MuseAsyncView`
- `CloudMoodArtwork`
- `MuseBottomNavigation`

Component không chứa logic gọi Supabase. Widget feature nhận state/callback từ tầng
presentation/application.

## 6. Responsive và accessibility

- Thiết kế trước cho điện thoại nhưng không khóa bằng kích thước frame tuyệt đối.
- Nội dung phải hoạt động từ màn hình nhỏ đến text scale tối thiểu 200%.
- Vùng chạm tối thiểu 48×48 logical pixels.
- Màu pastel phải được kiểm tra contrast; không dùng màu làm tín hiệu duy nhất.
- Artwork mây trang trí cần semantic label phù hợp hoặc bị loại khỏi accessibility tree.
- Các lựa chọn mood phải có label tiếng Việt rõ ràng, selected state và keyboard/
  screen-reader semantics.
- Hỗ trợ Reduce Motion cho animation mây/chuyển checkpoint.

## 7. Assets

Không dùng ảnh screenshot của Figma làm giao diện. Asset cần được export riêng ở
SVG/WebP/PNG phù hợp, có tên có nghĩa, kích thước hợp lý và xác nhận quyền sử dụng.
Nếu artwork chính thức chưa sẵn sàng, dùng placeholder code-native có thể thay thế,
không nhúng URL tạm thời hoặc URL ký hạn từ Figma.

Asset đề xuất:

```text
app/assets/
  illustrations/clouds/
  illustrations/journey/
  icons/
  backgrounds/
```

## 8. Bảo mật và riêng tư trong UI

- Không hiển thị nội dung journal/mood trong notification lock screen mặc định.
- Không đưa nội dung nhạy cảm vào route URL, analytics, crash logs hoặc debug prints.
- Ẩn dữ liệu khi session hết hạn; không giữ màn hình chi tiết user trước sau logout.
- Picker và preview media phải xử lý quyền bị từ chối, file sai loại và file quá lớn.
- Không dùng dark pattern để xin notification/media permission hay ngăn xóa tài khoản.

## 9. Kiểm thử và tiêu chí nghiệm thu

- Golden/widget tests cho theme, navigation và các trạng thái chính.
- Widget test ở text scale lớn và kích thước màn hình nhỏ.
- Kiểm tra contrast trước khi chốt token.
- Mọi màn hình có loading, empty, error/retry và authenticated-session handling.
- So sánh trực quan với frame Figma liên quan trong PR.
- Không có widget presentation nào import trực tiếp `supabase_flutter`.

## 10. Giới hạn và việc còn lại

- Cần bản export chính thức của artwork/logo/icon trước khi làm pixel-perfect.
- Cần chốt mapping các nhãn cảm xúc phong phú sang năm enum mood trong DB.
- Cần chốt package/bundle ID trước khi sinh project Android/iOS.
- Full interactive map chưa có asset/spec đủ chắc chắn; P0 dùng journey card/list.
- Figma có thể chứa exploration ngoài P0; phạm vi feature theo roadmap MVP đã chốt
  được ưu tiên hơn việc triển khai tất cả frame.

## 11. Tài liệu liên quan

- [Quy ước dự án](../README.md)
- [Frontend index](./README.md)
- [Daily check-in và streak](../db/daily-checkins-streak.md)
- [Journey và rewards](../db/journey-rewards.md)

