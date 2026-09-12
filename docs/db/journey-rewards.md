# Journey, checkpoints và rewards

Trạng thái: `implemented`  
Cập nhật: 2026-09-12

## Mục tiêu và phạm vi

Miền journey chuyển năng lượng tích lũy thành tiến độ checkpoint, mở phần thưởng và
ghi lịch sử khám phá. Client hiển thị trạng thái; quyết định vượt trạm và unlock
luôn nằm ở database.

## Mô hình dữ liệu

Catalog server-owned:

- `destinations` → `destination_checkpoints` theo `order_index`;
- mỗi điểm đến có `landmarks`, `foods`, `destination_items`;
- `checkpoint_rewards` trỏ đúng một loại reward: landmark, food, destination item
  hoặc energy. Constraint yêu cầu đúng cột đích và số lượng/năng lượng dương.
- `destination_checkpoints.required_energy > 0` là số điểm cần phân bổ cho từng trạm.
- `destinations.country_code` là mã quốc gia ISO hai ký tự bắt buộc;
  `destination_type` phân biệt tỉnh, thành phố, đảo, di sản hoặc vùng đất.
- `destinations.vietnam_region` chỉ còn là metadata tùy chọn cho ba miền Việt Nam.
- `destination_checkpoints.asset_path` trỏ tới artwork server-owned.
- Nội dung hiển thị theo ngôn ngữ nằm trong `destination_translations`,
  `checkpoint_translations`, `landmark_translations`, `food_translations` và
  `destination_item_translations`; cột catalog gốc là bản tham chiếu tiếng Việt.

Dữ liệu user-owned:

- `travel_progress`: con trỏ điểm đến/trạm, energy và trạng thái toàn hành trình;
- `user_checkpoint_progress`: trạng thái/energy tại từng checkpoint;
- `unlocked_destinations`, `unlocked_landmarks`, `unlocked_foods`,
  `unlocked_destination_items`: bộ sưu tập unique theo user/item;
- `travel_events`: audit timeline của journey, energy và reward.

Trigger từ chối `current_checkpoint_id` không thuộc `current_destination_id`.

## Luồng và RPC

### `start_journey()`

Chọn điểm đến active đầu tiên theo `(order_index, id)` mà user chưa hoàn thành, sau đó
chọn checkpoint active đầu tiên. RPC upsert unlock/progress, ghi event bắt đầu và
gọi engine advance. Nếu đã có checkpoint hiện tại, hàm trả trạng thái hiện có. Sau
khi hoàn thành một điểm đến, gọi lại để bắt đầu điểm tiếp theo.

### `advance_journey()`

RPC retry-safe gọi engine nội bộ rồi trả `travel_progress`. Engine tính:

```text
available = current_energy - journey_energy_used
```

Nếu đủ `required_energy`, checkpoint được hoàn thành và
`journey_energy_used` tăng; `current_energy` không bị trừ vì energy là điểm tích
lũy. Engine có thể vượt nhiều checkpoint trong một transaction. Reward collection
được upsert chống trùng; energy reward được cộng vào cả current/lifetime và có thể
giúp đi tiếp ngay. Cuối điểm đến, trạng thái tạm là `paused`; nếu mọi điểm đến active đều
đã hoàn thành thì chuyển `completed`.

`complete_mission()` gọi engine tự động sau khi cộng năng lượng.

### `set_item_equipped(p_item_id, p_equipped)`

Chỉ cho trang bị item đã unlock. Khi bật, mọi item khác cùng `item_type` bị tháo để
mỗi category chỉ có một item equipped. RPC đồng thời đánh dấu item đã xem.

## RLS và quyền client

User active được đọc catalog active và dữ liệu hành trình của chính mình. Client
không có INSERT/UPDATE/DELETE trực tiếp vào progress, event hay unlock. Ba bảng
unlock item cho phép cập nhật duy nhất `is_viewed`; equip phải gọi RPC. Các hàm
`SECURITY DEFINER` cố định `search_path` và guard bằng `require_user()`.

## Seed MVP

Migration demo seed idempotent tạo:

- 3 điểm đến mẫu Việt Nam: Hà Nội, Đà Nẵng, Lâm Đồng;
- mỗi điểm đến 5 checkpoint, mỗi checkpoint cần 10 energy;
- 15 landmark, 15 food và 3 badge hoàn thành điểm đến;
- 33 reward mapping: landmark + food cho từng trạm, thêm badge ở trạm 5.

Mã catalog có prefix `demo-`; đây không phải catalog địa lý/nội dung production.

Các cột `destinations.cover_asset_path`, `destinations.map_asset_path` và
`landmarks.asset_path`, `foods.asset_path`, `destination_items.asset_path` đã được
repository Flutter đọc vào domain model. Seed demo hiện vẫn để các cột catalog
ở `NULL`: export cloud mascot dùng chung không phải asset của một dòng catalog,
còn sprite Figma đang chứa nhiều object/crop nên chưa thể gán đúng từng item.
Không ghi đường dẫn Figma tạm hoặc URL ký hạn vào migration; asset động chỉ được
publish cùng catalog content đã duyệt, qua bucket/policy server-owned và
migration/seed idempotent.

## Kiểm thử

Integration test bắt đầu journey, hoàn thành hai custom mission, xác nhận energy
10, checkpoint đầu hoàn tất, `journey_energy_used=10` và mở landmark + food. Gọi
complete lặp được kiểm tra không cộng đôi. Chưa test hết điểm đến, đổi điểm đến, energy
bonus, equip category, catalog inactive hoặc concurrency nhiều request.

## Migration và rollback

`mvp_journey` chứa engine và RPC; `mvp_demo_catalog` chứa seed; migration
`global_destinations` đổi vocabulary mà không đổi ID hay xóa dữ liệu. Thay đổi thứ tự,
required energy hoặc reward trên dữ liệu đã có có thể làm con trỏ user không còn
nhất quán; cần migration dữ liệu và kế hoạch rollback riêng, không update thủ công
trên Dashboard.

## Giới hạn và việc còn lại

- Artwork riêng cho food/item vẫn dùng placeholder; cần một đợt content review
  và export riêng trước production.
- App phải gọi `start_journey()` khi user muốn chuyển sang điểm đến kế tiếp.
- Chưa có admin/content publishing workflow hay version catalog.
- Chưa có test tải/lock contention và invariant toàn hành trình.

Liên quan: [missions-energy.md](./missions-energy.md),
[migrations-testing.md](./migrations-testing.md),
[curated-catalog.md](./curated-catalog.md).

