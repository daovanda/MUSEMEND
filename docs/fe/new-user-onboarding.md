# Onboarding tài khoản mới

**Trạng thái:** `implemented`
**Cập nhật:** 2026-09-18

## Mục tiêu và phạm vi

Tài khoản tạo mới được giới thiệu ngắn về giá trị của MuseMend, định hướng riêng
tư/offline và có thể nhập tên hiển thị trước khi vào Bầu trời.
Ảnh tham khảo chỉ cung cấp nội dung; UI dùng nền mây, glass card, màu pastel và
motion hiện có của MuseMend, không sao chép bố cục thiết kế cũ.

## Luồng và module

Router tải `onboardingProfileProvider` sau khi có session. Profile chưa có
`onboarding_completed_at` được chuyển tới `/onboarding`; profile đã hoàn tất đi
thẳng tới app. Ba bước gồm:

1. Chào mừng: gọi tên cảm xúc, viết riêng tư và chăm sóc bằng bước nhỏ.
2. Riêng tư: giới thiệu nhật ký trên thiết bị, dùng ngoại tuyến và sao lưu tùy chọn.
3. Cá nhân hóa: tên hiển thị tùy chọn và lời chào xem trước.

Onboarding luôn dùng giao diện sáng, kể cả khi thiết bị Android/iOS đang bật chế
độ tối hoặc tài khoản còn giá trị `theme_mode = dark` từ bản QA cũ. Quy tắc này
được áp dụng ở root app nên không tạo khác biệt giữa onboarding và các màn hình
bên trong.

Ở bước đầu, nút quay lại thực hiện `AuthController.signOut()` rồi để auth router
đưa người dùng về `/sign-in`; không điều hướng thẳng khi session vẫn còn vì router
sẽ đưa tài khoản chưa onboarding quay trở lại. Từ bước hai trở đi, cùng nút đó chỉ
quay về bước onboarding trước. Trong lúc sign-out/lưu đang chạy, nút bị khóa để
tránh gửi thao tác lặp. Ba bước nằm trong `PageView`: vuốt trái/phải chuyển bước,
còn nút tiếp tục/quay lại dùng cùng bộ điều khiển trang để trạng thái luôn đồng bộ.
Vùng nội dung không còn cuộn dọc; cả ba bước dùng cùng chiều cao thiết kế và
khối giới thiệu có vị trí cố định. Kích thước thiết kế được giữ nguyên trên
viewport điện thoại/web thông thường (không dùng chiều cao logic bị ảnh hưởng
bởi device-pixel-ratio để thu nhỏ toàn bộ UI). Nhờ vậy biểu tượng, tiêu đề,
mô tả và điểm bắt đầu của nội dung không nhảy vị trí khi vuốt ngang. Bước chào
mừng cũng có mô tả ngắn như hai bước sau.
Mỗi page có thêm khoảng đệm 8dp ở hai mép, tạo khoảng hở 16dp giữa các card
khi vuốt ngang; khoảng đệm nằm bên trong page nên trang bên cạnh không lộ ra
khi người dùng dừng ở một bước.
Màn onboarding khóa giao diện sáng và màu thanh hệ thống tương ứng, kể cả khi
thiết bị đang dùng dark mode.
Logo thương hiệu dùng `mascot-cloud.png` trong thanh MuseTopBar và ở trung tâm
của bước cá nhân hóa — bước dẫn người dùng vào sản phẩm. Mascot hiển thị trực
tiếp trên nền, không thêm vòng tròn/bong bóng trang trí bao quanh. Nhờ vậy hình
đám mây ở onboarding nhất quán với thương hiệu và không bị nhầm với icon chức
năng. Biểu tượng tay và khiên của hai bước giới thiệu vẫn giữ huy hiệu riêng để
người dùng phân biệt nội dung.
Headline của cả ba bước dùng cùng component responsive, bỏ xuống dòng thủ công từ
ARB và giới hạn tối đa hai dòng; cỡ chữ giảm nhẹ dưới 480dp để câu tiếng Việt không
bị tách thành dòng thứ ba. Vùng headline có chiều cao cố định và căn từ mép trên,
nên tiêu đề một dòng ở bước cá nhân hóa bắt đầu cùng mốc với tiêu đề hai dòng ở
hai bước giới thiệu. Dòng mô tả ngay dưới headline có vùng cao cố định
cho tối đa ba dòng trên cả ba bước, để câu giới thiệu không bị cắt bằng dấu ba
chấm ở kích thước điện thoại thường gặp; card đầu bắt đầu cùng một mốc phía dưới
vùng này ngay cả khi bản dịch chỉ chiếm một hoặc hai dòng. Cả ba mô tả bắt đầu
từ mép trên của vùng cố định; câu ngắn để trống phần dưới, không bị căn giữa
theo chiều dọc.
Ba card giới thiệu ở hai bước đầu có cùng chiều cao và vùng mô tả tối đa hai dòng;
khung nhập tên ở bước ba cũng dùng cùng chiều cao 108dp để chuyển cảnh từ bước
riêng tư sang cá nhân hóa không bị giật hình. Bản dịch dài được ellipsis trong
card thay vì làm các card sau bị đẩy lệch.

Tên từ đăng ký được điền sẵn. Tên người dùng nhập ở bước cuối được ưu tiên; bỏ
qua giữ tên hiện có. Nếu không có tên, các màn hình tiếp tục dùng fallback
được dịch tương ứng với locale (tiếng Việt là `Bạn của Muse`). Bước này không
hiển thị lựa chọn cách xưng hô để giữ cùng nhịp bố cục với bước riêng tư; giá trị
`preferred_address` hiện có vẫn được giữ nguyên khi hoàn tất để tương thích với
profile cũ, còn việc thay đổi cách xưng hô được thực hiện ở phần cài đặt.

Ô nhập chỉ dùng một hint trong khung là nhãn đã dịch `onboardingDisplayNameLabel`,
không có nhãn rời phía trên nên không thể chồng lên viền khi màn hình hẹp. Khung
nhập giữ chiều cao 108dp như card giới thiệu. Lời chào xem trước nằm trực tiếp
trên nền chung, không bọc trong glass card; biểu tượng bàn tay được đặt ngay phía
trên lời chào để giữ tín hiệu thân thiện. Cụm này dùng cỡ chữ lớn hơn một bậc và
tối đa hai dòng để bước ba bắt đầu và kết thúc tự nhiên khi vuốt từ bước hai.

## Contract, validation và lỗi

`OnboardingRepository` tách presentation khỏi Supabase. Adapter đọc ba cột profile
và gọi `complete_onboarding(display_name, preferred_address)`. Tên rỗng được coi
là không thay đổi; tên nhập mới dài 2–80 ký tự. Cách xưng hô chỉ nhận tập giá trị
đã định nghĩa trong domain và DB. Khi tải/lưu lỗi, màn hình giữ người dùng ở flow,
không giả định đã hoàn tất và cung cấp retry.

## Bảo mật và riêng tư

Client không được update trực tiếp trạng thái onboarding. RPC owner-scoped dùng
`muse_private.require_user()`, `SECURITY DEFINER`, `search_path=''` và chỉ cấp
execute cho `authenticated`. Theo quyết định sản phẩm, onboarding giới thiệu
offline/backup ở thì hiện tại để phản ánh trải nghiệm phát hành mục tiêu. Tại mốc
implementation này dữ liệu vẫn dùng Auth, RLS và Storage private, chưa có local-first
hay E2EE; hai năng lực đó phải được hoàn thiện trước khi phát hành công khai.

## Kiểm thử, rollout và giới hạn

Migration backfill tài khoản hiện có thành đã hoàn tất để không thay đổi trải
nghiệm đăng nhập của họ; tài khoản tạo sau migration có giá trị null và thấy flow.
Integration test kiểm tra trạng thái ban đầu và RPC hoàn tất. Widget/DTO test kiểm
tra mapping, nội dung ba bước, hành vi bỏ qua/lưu tên và nút quay về đăng nhập có
gọi sign-out ở bước đầu. Widget test cũng kiểm tra vuốt ngang tới bước riêng tư và
vuốt ngược về bước chào mừng. Test cấp ứng dụng giả lập thiết bị đang ở dark mode
và xác nhận `Theme.of(context).brightness` vẫn là `Brightness.light`.
Widget test còn đối chiếu vị trí bắt đầu nội dung của cả ba bước ở 360×800,
kiểm tra một lần vuốt dở đúng viewport web QA 354×879 không làm lệch hai trang,
đồng thời xác nhận hai card của các trang liền kề còn khoảng hở,
và kiểm tra không tràn layout với toàn bộ 12 ngôn ngữ được hỗ trợ. Trang chào
mừng đã được xem trực tiếp trên web ở 354 px: mô tả tiếng Việt hiển thị đầy đủ
trên ba dòng, các bước tiếp theo vẫn cùng mốc nội dung.

Rollback ứng dụng vẫn tương thích với hai cột mới. Sau khi migration đã deploy,
không xóa cột/RPC trong rollback nóng; dùng forward migration nếu cần sửa. Offline,
backup tùy chọn, áp dụng cách xưng hô toàn app và liên kết chính sách riêng tư công
khai vẫn là việc tiếp theo trước production.

Có thể QA giao diện trước khi deploy migration mà không dùng tài khoản hay ghi dữ
liệu bằng entrypoint preview:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 64563 `
  -t tool/onboarding_preview.dart
```

Liên quan: [Authentication](./authentication.md),
[Profile](./profile-overview.md),
[Profiles/settings DB](../db/profiles-settings.md).
