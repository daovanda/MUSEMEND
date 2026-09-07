# Home Figma inventory

- **Trạng thái:** in-progress
- **Cập nhật:** 2026-09-07
- **Nguồn duy nhất:** [Figma — page Home](https://www.figma.com/design/AhhlLUWAyvLVs7R5ZBVcQV/Nh%E1%BA%ADt-K%C3%BD-Ch%E1%BB%AFa-L%C3%A0nh?node-id=130-25)

## Phạm vi

Tài liệu này là bản đồ thiết kế cho **page `Home` duy nhất**. `Style`, `Page 3` và
các page khác không phải nguồn nghiệm thu. Inventory giúp giữ toàn cảnh Home,
nhưng không có nghĩa tất cả frame được triển khai trong cùng một PR.

Thứ tự hiện tại:

1. Bầu trời và navigation dùng chung.
2. Các màn Home khác theo từng feature sau khi Bầu trời được QA.
3. Province, checkpoint, landmark, food và item chỉ gắn artwork khi catalog động
   có asset riêng và mapping server rõ ràng.

## Nhóm frame đã nhận diện trên Home

- onboarding: splash, welcome, privacy, tên hiển thị và chọn tài khoản;
- rationale/quyền hệ điều hành: contacts, microphone, photos, location và
  notification;
- trạng thái hỗ trợ: loading, offline, empty/error;
- màn chính: Bầu trời cùng header, mood, hành trình, nhiệm vụ, quote, chia sẻ và
  bottom navigation;
- các biến thể Bầu trời: mood mở (`57:24`/`199:881`) và mood thu gọn (`233:893`).

Chỉ nhóm Bầu trời đang được triển khai trong vòng này. Trước khi làm nhóm kế tiếp,
agent phải mở lại đúng frame trên page Home và bổ sung node/measurement vào file
này, không suy ra từ screenshot hoặc page khác.

## Đặc tả Bầu trời đã đo

Frame gốc rộng `390`, cao `1741`, nền dọc `#E0F2F7 → #FBF9F5 → #FBF9F5`.

| Thành phần | Node | Kích thước/vị trí theo frame | Quy tắc |
| --- | --- | --- | --- |
| Nền trời/cảnh quan | `image 20` (`58:184`) | `390×560`, top `0` | asset tĩnh, phủ ngang màn |
| Mascot mây | `image 23` (`174:44`) | `145×97`, left `122`, top `98` | asset tĩnh |
| Mood bubble | `85:559` | `332×179`, left `29`, top `206`, radius `48` | white 60%, border white 50%, background blur `12` |
| Mood selector | `85:567` | `268×93`, left `32`, top `42` trong bubble | 5 mood tĩnh, xếp chồng có rotation |
| Journey | `74:611` | `360×142`, left `16`, top `489` | tỉnh/trạm/checkpoint là dữ liệu động |
| Mission group | `199:881` | `325×324`, left `28`, top `804` | nhóm theo thời điểm, nội dung từ DB |
| Quote | `Quote` | dưới mission | câu mẫu cứng, có dấu ngoặc kép trang trí |
| Chia sẻ khoảnh khắc | `Heading 3 - Chia sẻ khoảnh khắc` | carousel dưới quote | card preview/title/subtitle/share; nội dung mẫu cứng |
| Bottom nav center | `195:289` | nút `56×56`, top `-19` | nền `#366672`, icon mây `#EFFBFF`; chạm về Bầu trời, giữ để chọn mood |

Hai nút mood dùng radius pill, border white 80%, shadow đen 5%; gradient từ
`#D4E2C7` qua `#E9F1E3` 60% đến white 20%. Nút trái rộng `91`, nút phải rộng
`137`, cao hiển thị `36`.

## Năm mood tĩnh

| Enum DB | Nhãn Home | Node ảnh | Màu nền 20% | Kích thước tile | Rotation |
| --- | --- | --- | --- | --- | --- |
| `awful` | QUẠO | `85:587` | `#FFCDD2` | `47.09×62.89` | `+8°` |
| `sad` | TRỐNG RỖNG | `85:570` | `#9CB4D8` | `55×73.45` | `+4°` |
| `okay` | ỔN ÁP | `85:576` | white | `70×93` | `0°` |
| `good` | THƯ GIÃN | `85:573` | `#FFF9C4` | `55×73.45` | `-4°` |
| `great` | CHỮA LÀNH | `85:595` | `#DCEDC8` | `47.09×62.89` | `-8°` |

## Static và dynamic

Được bundle tĩnh trong app:

- nền Bầu trời;
- mascot mây;
- cloud phụ từ `image 12` (`57:21`) được export sẵn, chờ xác nhận vị trí dùng;
- năm biểu cảm mood;
- icon mây ở bottom navigation được vẽ code-native (đúng node `195:289`); không
  thay bằng cloud phụ nếu chưa có xác nhận layer tương ứng.

Không hardcode theo ảnh Figma:

- tỉnh, số trạm, checkpoint và `required_energy`;
- landmark, food, item và phần thưởng của trạm;
- nhiệm vụ, thời gian, trạng thái và năng lượng thưởng.

Sprite `sky-collection-sprite.png` là nguồn tham chiếu nhiều object. Nó không được
hiển thị như một landmark cụ thể hoặc đưa vào seed; UI dùng placeholder cho tới
khi mỗi object có asset riêng và `asset_path` do catalog Supabase cung cấp.

## Tiêu chí review

- So sánh ở viewport điện thoại và giữ đúng thứ tự layer nền → fade → header →
  mascot → mood bubble → journey → missions → quote/share → nav.
- Không dùng screenshot toàn frame làm UI.
- Kiểm tra click, long-press, disabled/saving và reduce-motion.
- Semantics phải mô tả mood và trạng thái chọn, không đọc lặp nhãn.
- Ảnh QA/golden sinh cục bộ nằm trong thư mục ignore và không chứa dữ liệu thật.

## Liên quan

- [UI/UX direction](./ui-design-direction.md)
- [Màn Bầu trời](./sky-screen.md)
- [Asset manifest](./assets.md)
